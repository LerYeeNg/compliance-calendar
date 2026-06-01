// ─────────────────────────────────────────────────────────────────────────────
// COMPLIANCE CALENDAR – CONFIGURATION
// No Azure AD app registration needed. Just fill in the two values below.
// The app uses your existing SharePoint login session automatically.
// ─────────────────────────────────────────────────────────────────────────────
const CONFIG = {

  // SharePoint site URL — no trailing slash, just the site root
  siteUrl:  'https://netorgft13870443.sharepoint.com/sites/HomeTeam',

  // Exact display name of the SharePoint list (case-sensitive)
  listName: 'Compliance Calendar',

  // Azure AD app registration (from portal.azure.com → App registrations)
  clientId: '1c37af01-1dbe-4774-93b9-a8c199921682',   // Application (client) ID
  tenantId: 'cee8dbb1-88a6-48ac-9231-641abcd5acff',   // Directory (tenant) ID

  // ── SharePoint column internal names ─────────────────────────────────────
  // These match the columns created by setup-sharepoint-list.ps1.
  // Only change if you created columns manually with different names.
  fields: {
    taskNo:         'Title',
    entity:         'Entity',
    section:        'Section',
    obligation:     'ComplianceObligation',
    reference:      'Reference',
    action:         'ComplianceAction',
    officer:        'Officer',
    frequency:      'Frequency',
    completed:      'CompletedStatus',
    completionDate: 'CompletionDate',
    reviewDate:     'ReviewDate',
    comments:       'Comments',
  },
};
