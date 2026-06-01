# Compliance Calendar – Setup Guide

Complete these steps once. The app uses Azure AD (Microsoft Entra ID) for login
and calls the SharePoint REST API with a bearer token — works from any browser,
no SharePoint session required.

---

## What you will need

- Access to **portal.azure.com** (to register the app)
- A **GitHub account** (free) to host the HTML file
- Access to your **SharePoint Online** site where the list lives
- About 15 minutes

---

## Step 1 — Create the Azure AD App Registration

1. Go to **[portal.azure.com](https://portal.azure.com)** and sign in with your Microsoft 365 account.
2. In the search bar type **"App registrations"** → click it → click **New registration**.
3. Fill in:
   - **Name:** `CS Capital Compliance Calendar`
   - **Supported account types:** *Accounts in this organizational directory only (Single tenant)*
   - **Redirect URI:** choose platform **Single-page application (SPA)** — leave the URL blank for now
4. Click **Register**.
5. On the overview page, **copy these two values** — you will need them in Step 4:
   - **Application (client) ID**
   - **Directory (tenant) ID**

---

## Step 2 — Add SharePoint Permission

1. In your new app, click **API permissions** in the left menu.
2. Click **Add a permission** → **SharePoint** → **Delegated permissions**.
3. Search for `Sites` → tick **Sites.ReadWrite.All** → click **Add permissions**.
4. Click **Grant admin consent for [your organisation]** → **Yes**.
   *(A green tick will appear. This is a one-time step and requires you to be a Microsoft 365 admin.)*

---

## Step 3 — Host the Files on GitHub Pages (free)

1. Go to **[github.com](https://github.com)** → sign in or create a free account.
2. Click **+** (top right) → **New repository**.
   - Name: `compliance-calendar`
   - Visibility: **Public**
   - Click **Create repository**
3. Click **Add file → Upload files** and drag in both files:
   - `compliance-calendar.html`
   - `config.js`
4. Click **Commit changes**.
5. Go to **Settings → Pages** → under *Source* select **Deploy from a branch** → branch = `main` → click **Save**.
6. Wait ~60 seconds, then GitHub will show your live URL:
   ```
   https://YOUR-GITHUB-USERNAME.github.io/compliance-calendar/compliance-calendar.html
   ```
   Keep this URL — you will use it in Steps 4 and 5.

---

## Step 4 — Fill in config.js

Open `config.js` (on your computer, before re-uploading) and fill in the four values:

```js
const CONFIG = {
  siteUrl:  'https://netorgft13870443.sharepoint.com/sites/HomeTeam',
  listName: 'Compliance Calendar',
  clientId: 'paste-your-application-client-id-here',
  tenantId: 'paste-your-directory-tenant-id-here',
  ...
};
```

Save the file, then **re-upload it to GitHub** (drag it onto the repository page → Commit changes).

---

## Step 5 — Register the Redirect URI in Azure AD

1. Back in **portal.azure.com** → App registrations → your app.
2. Click **Authentication** in the left menu.
3. Under *Single-page application*, click **Add URI**.
4. Paste your GitHub Pages URL from Step 3:
   ```
   https://YOUR-GITHUB-USERNAME.github.io/compliance-calendar/compliance-calendar.html
   ```
5. Click **Save**.

---

## Step 6 — Test the App

1. Open your GitHub Pages URL in a browser.
2. A **Microsoft login popup** will appear — sign in with your Microsoft 365 account.
3. On first use you will see a consent screen asking permission to access SharePoint — click **Accept**.
4. The app will connect to the SharePoint list and load all obligations.
5. The green banner confirms the connection:
   ```
   Connected · Compliance Calendar · 103 items · Synced 10:32:15 am
   ```

---

## Step 7 — Embed in a SharePoint Page (optional)

If you want the calendar visible inside a SharePoint page:

1. Go to your SharePoint site → open or create a modern page.
2. Edit the page → click **+** → search for **Embed** → add the Embed web part.
3. Paste:
   ```html
   <iframe src="https://YOUR-GITHUB-USERNAME.github.io/compliance-calendar/compliance-calendar.html"
           width="100%" height="920" frameborder="0" allow="popup"></iframe>
   ```
4. Set the web part height to **Full page** or at least **920px**.
5. Publish the page.

> **Note:** Allow popups from your GitHub Pages domain in the browser — the Azure AD
> login uses a popup window.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Login popup is blocked | Allow popups from `github.io` in your browser settings. |
| Red banner "Add clientId and tenantId to config.js" | Open `config.js`, fill in the IDs from your Azure AD app registration, re-upload to GitHub. |
| Login succeeds but red banner "SharePoint 401 Unauthorized" | Admin consent was not granted. Go to portal.azure.com → your app → API permissions → Grant admin consent. |
| Login succeeds but red banner "SharePoint 403 Forbidden" | Your account does not have permission to read the SharePoint list. Ask a site owner to grant access. |
| Login succeeds but red banner "SharePoint 404 / List not found" | The `listName` in config.js does not match exactly. Check capitalisation and spacing. |
| Save fails with "Could not get form digest" | Token may have expired. Refresh the page and sign in again. |
| Consent screen asks for permissions every time | Make sure admin consent was granted in Step 2 (green tick in API permissions). |
| Works directly but not in SharePoint iframe | The iframe `allow="popup"` attribute must be present. Some browsers block third-party popups in iframes — open the GitHub Pages URL directly instead. |

---

## How notifications work

Once data is in the SharePoint list, use **SharePoint alerts** or **Power Automate**:

- **Simple alerts:** Open the Compliance Calendar list → ⚙ → **Alert me** →
  choose frequency (immediate, daily digest, weekly).
- **Power Automate – review reminders:** Create a scheduled flow that runs daily,
  queries items where `ReviewDate` is within the next 14 days, and sends an email
  or Teams message.
- **Power Automate – on edit:** Trigger *"When an item is modified"* to notify
  the compliance team whenever a status is updated.

---

## SharePoint List (already set up)

The SharePoint list was created using `setup-sharepoint-list.ps1` and contains
all 103 obligations. If you ever need to recreate it:

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
.\setup-sharepoint-list.ps1 -SiteUrl "https://netorgft13870443.sharepoint.com/sites/HomeTeam" -ImportData
```

---

*Setup guide version: June 2026 — Azure AD (MSAL.js) + SharePoint REST API*
