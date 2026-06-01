"""
Monthly compliance watch updater.
Called by GitHub Actions — reads the existing news.json, asks Claude to
refresh the items based on the latest regulatory developments, and writes
the result back to news.json.
"""

import json
import os
import re
from datetime import datetime
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

def main():
    existing = load_existing()
    now_label = datetime.utcnow().strftime('%B %Y')

    system_prompt = """You are a compliance research assistant for CS Capital Partners,
an Australian fund manager holding an AFSL. Your job is to identify the most
important current and upcoming compliance obligations across three areas:
  1. AFSL / ASIC (Corporations Act, RG series, licensing conditions)
  2. AUSTRAC / AML-CTF (Anti-Money Laundering and Counter-Terrorism Financing Act)
  3. AER – Australian Energy Regulator (relevant if portfolio companies hold energy licences)

You output ONLY a valid JSON object — no markdown, no commentary, no code fences."""

    user_prompt = f"""Today is {datetime.utcnow().strftime('%d %B %Y')}.

Return a JSON object in exactly this structure (keep section ids as "afsl", "austrac", "aer"):

{{
  "updated": "{now_label}",
  "sections": [
    {{
      "id": "afsl",
      "title": "AFSL – ASIC",
      "items": [
        {{
          "badge": "change|deadline|new|watch",
          "title": "Short title (include date/deadline if applicable)",
          "desc": "One or two sentence explanation relevant to a small AFSL-holder / fund manager."
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
- Each section should have 3–5 items.
- Focus on obligations or deadlines that fall within the next 6 months OR are newly in force.
- IMPORTANT: Also retain any items from the previous list whose deadline fell within the past 30 days — these are recent enough that the compliance team may not have confirmed completion yet. Keep them with their original badge so they stay visible as a reminder.
- badge values: "new" = newly introduced, "deadline" = hard deadline coming up, "change" = rule changed/tightened, "watch" = emerging/monitor.
- Be concise — titles ≤ 80 chars, desc ≤ 200 chars.
- Output ONLY the raw JSON object. No markdown. No explanation.

Previously shown items (carry forward any with deadlines in the past 30 days):
{json.dumps(existing, indent=2)}
"""

    client = anthropic.Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])

    print("Calling Claude API…")
    message = client.messages.create(
        model='claude-sonnet-4-5',
        max_tokens=2048,
        system=system_prompt,
        messages=[{'role': 'user', 'content': user_prompt}],
    )

    raw = message.content[0].text.strip()
    print("Raw response (first 300 chars):", raw[:300])

    # Strip any accidental markdown fences
    raw = re.sub(r'^```(?:json)?\s*', '', raw)
    raw = re.sub(r'\s*```$', '', raw)

    news = json.loads(raw)   # Will raise if invalid — causes the Action to fail visibly

    with open(NEWS_PATH, 'w', encoding='utf-8') as f:
        json.dump(news, f, indent=2, ensure_ascii=False)
        f.write('\n')

    total = sum(len(s.get('items', [])) for s in news.get('sections', []))
    print(f"✓ news.json written — {len(news.get('sections', []))} sections, {total} items.")

if __name__ == '__main__':
    main()
