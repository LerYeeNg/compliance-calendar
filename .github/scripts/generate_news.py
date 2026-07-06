"""
Monthly compliance watch updater.
Called by GitHub Actions — uses Claude with live web search to find real
regulatory updates for AFSL/ASIC, AUSTRAC, and AER, then writes news.json.
Search window: past 1 month → next 12 months.
"""

import json
import os
import re
from datetime import datetime, timedelta
import anthropic

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT   = os.path.join(SCRIPT_DIR, '..', '..')
NEWS_PATH   = os.path.join(REPO_ROOT, 'news.json')

def load_existing():
    try:
        with open(NEWS_PATH, encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return {}

def extract_item_date(title):
    """Parse the first date found in an item title, e.g. '30 May 2026'."""
    MONTHS = {'jan':1,'feb':2,'mar':3,'apr':4,'may':5,'jun':6,
              'jul':7,'aug':8,'sep':9,'oct':10,'nov':11,'dec':12}
    m = re.search(r'(\d{1,2})?\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})', title, re.I)
    if not m:
        return None
    day = int(m.group(1)) if m.group(1) else 1
    mon = MONTHS[m.group(2).lower()[:3]]
    yr  = int(m.group(3))
    try:
        return datetime(yr, mon, day)
    except ValueError:
        return None

def carry_forward_recent(existing, cutoff_days=30):
    """
    Return items from the existing news.json whose date falls within
    the past `cutoff_days` days — guaranteed to be included in the new output.
    Returns a dict keyed by section id: list of items.
    """
    now = datetime.utcnow()
    cutoff = now - timedelta(days=cutoff_days)
    retained = {}
    for sec in existing.get('sections', []):
        keep = []
        for item in sec.get('items', []):
            d = extract_item_date(item.get('title', ''))
            if d and cutoff <= d <= now:
                keep.append(item)
        if keep:
            retained[sec['id']] = keep
    return retained

def main():
    existing  = load_existing()
    now       = datetime.utcnow()
    now_label = now.strftime('%B %Y')
    date_from = (now - timedelta(days=30)).strftime('%d %B %Y')
    date_to   = (now + timedelta(days=365)).strftime('%d %B %Y')

    # Items from last 30 days are guaranteed to be carried forward in code
    retained = carry_forward_recent(existing, cutoff_days=30)
    if retained:
        retain_note = (
            "\n\nNOTE: The following items are from the past 30 days and MUST be included "
            "in your output (merge them into the relevant section, do not drop them):\n"
            + json.dumps(retained, indent=2)
        )
    else:
        retain_note = ""

    system_prompt = """You are a compliance research assistant for CS Capital Partners,
an Australian fund manager holding an AFSL. You have access to a web search tool.
Use it to find REAL, CURRENT regulatory updates — search multiple times across
each area to find the most relevant items.

You output ONLY a valid JSON object — no markdown, no commentary, no code fences."""

    user_prompt = f"""Today is {now.strftime('%d %B %Y')}.

Search the web for Australian regulatory compliance updates relevant to a small
AFSL-holding fund manager across these three areas:
  1. AFSL / ASIC — search for: "ASIC compliance 2026", "AFSL obligations 2026",
     "Corporations Act amendments 2026", "ASIC regulatory updates"
  2. AUSTRAC / AML-CTF — search for: "AUSTRAC 2026", "AML CTF reforms Australia 2026",
     "Tranche 2 AML", "AUSTRAC compliance obligations"
  3. AER – Australian Energy Regulator — search for: "AER regulatory changes 2026",
     "Australian Energy Regulator 2026 compliance"

Look for items with dates between {date_from} and {date_to} (past 1 month to next 12 months).

Then return a JSON object in exactly this structure:

{{
  "updated": "{now_label}",
  "sections": [
    {{
      "id": "afsl",
      "title": "AFSL – ASIC",
      "items": [
        {{
          "badge": "change|deadline|new|watch",
          "title": "Short title with date, e.g. 'Breach Reporting Deadline – 30 Jun 2026'",
          "desc": "One or two sentences. Include the specific rule/act reference if known."
        }}
      ]
    }},
    {{
      "id": "austrac",
      "title": "AUSTRAC – AML/CTF Reforms",
      "items": [...]
    }},
    {{
      "id": "aer",
      "title": "AER – Australian Energy Regulator (Upcoming)",
      "items": [...]
    }}
  ]
}}

Rules:
- Each section should have 3–6 items based on what you actually find.
- Only include items with real dates or recently confirmed changes — do not invent items.
- badge: "deadline" = hard date coming up, "new" = newly introduced rule, "change" = tightened/changed rule, "watch" = emerging/monitor.
- Titles ≤ 80 chars, desc ≤ 220 chars.
- Output ONLY the raw JSON object. No markdown. No explanation.{retain_note}
"""

    client = anthropic.Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])

    print(f"Calling Claude with web search (window: {date_from} to {date_to})...")
    message = client.messages.create(
        model='claude-opus-4-5',
        max_tokens=4096,
        tools=[{"type": "web_search_20250305", "name": "web_search", "max_uses": 12}],
        system=system_prompt,
        messages=[{'role': 'user', 'content': user_prompt}],
    )

    # Extract the final text block (after all tool use turns)
    raw = ''
    for block in message.content:
        if hasattr(block, 'text'):
            raw = block.text.strip()

    print("Raw response (first 400 chars):", raw[:400])

    # Extract JSON object — find first { and last } in case Claude adds prose around it
    start = raw.find('{')
    end   = raw.rfind('}')
    if start == -1 or end == -1:
        raise ValueError('No JSON object found in Claude response')
    raw = raw[start:end+1]

    news = json.loads(raw)  # Raises if invalid — causes the Action to fail visibly

    # Programmatic safety net: re-inject any retained recent items that Claude dropped
    if retained:
        for sec in news.get('sections', []):
            must_have = retained.get(sec['id'], [])
            if must_have:
                existing_titles = {i['title'].lower() for i in sec.get('items', [])}
                for item in must_have:
                    if item['title'].lower() not in existing_titles:
                        sec['items'].insert(0, item)
                        print(f"  ↩ Re-injected retained item: {item['title']}")

    with open(NEWS_PATH, 'w', encoding='utf-8') as f:
        json.dump(news, f, indent=2, ensure_ascii=False)
        f.write('\n')

    total = sum(len(s.get('items', [])) for s in news.get('sections', []))
    print(f"OK news.json written — {len(news.get('sections', []))} sections, {total} items.")

if __name__ == '__main__':
    main()
