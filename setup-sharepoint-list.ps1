# =============================================================================
# setup-sharepoint-list.ps1
# Creates the "Compliance Calendar" SharePoint list and optionally imports data.
#
# REQUIREMENTS:
#   Install-Module PnP.PowerShell -Scope CurrentUser
#
# USAGE:
#   # Create list + columns only:
#   .\setup-sharepoint-list.ps1 -SiteUrl "https://YOURTENANT.sharepoint.com/sites/YOURSITE"
#
#   # Create list + columns + import all 103 obligations:
#   .\setup-sharepoint-list.ps1 -SiteUrl "https://YOURTENANT.sharepoint.com/sites/YOURSITE" -ImportData
#
#   # Import data only (list already exists):
#   .\setup-sharepoint-list.ps1 -SiteUrl "https://YOURTENANT.sharepoint.com/sites/YOURSITE" -ImportOnly
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,

    [switch]$ImportData,
    [switch]$ImportOnly
)

$ListName = "Compliance Calendar"

# ── Connect ────────────────────────────────────────────────────────────────
Write-Host "`nConnecting to SharePoint: $SiteUrl" -ForegroundColor Cyan
Connect-PnPOnline -Url $SiteUrl -Interactive

# ── Create List ────────────────────────────────────────────────────────────
if (-not $ImportOnly) {
    $existing = Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "List '$ListName' already exists – skipping creation." -ForegroundColor Yellow
    } else {
        Write-Host "Creating list: $ListName" -ForegroundColor Green
        New-PnPList -Title $ListName -Template GenericList -OnQuickLaunch

        # Rename the built-in Title column to "Task No"
        Set-PnPField -List $ListName -Identity "Title" -Values @{Title="Task No"}

        Write-Host "Adding columns…" -ForegroundColor Cyan

        Add-PnPField -List $ListName -InternalName "Entity"             -DisplayName "Entity"              -Type Text           -AddToDefaultView
        Add-PnPField -List $ListName -InternalName "ComplianceObligation" -DisplayName "Compliance Obligation" -Type Note        -AddToDefaultView
        Add-PnPField -List $ListName -InternalName "Reference"          -DisplayName "Reference"            -Type Text           -AddToDefaultView
        Add-PnPField -List $ListName -InternalName "ComplianceAction"   -DisplayName "Compliance Action"   -Type Note
        Add-PnPField -List $ListName -InternalName "Officer"            -DisplayName "Responsible Officer" -Type Text           -AddToDefaultView
        Add-PnPField -List $ListName -InternalName "CompletedStatus"    -DisplayName "Completed Status"    -Type Text           -AddToDefaultView
        Add-PnPField -List $ListName -InternalName "CompletionDate"     -DisplayName "Completion Date"     -Type DateTime       -AddToDefaultView
        Add-PnPField -List $ListName -InternalName "ReviewDate"         -DisplayName "Next Review Date"    -Type DateTime       -AddToDefaultView
        Add-PnPField -List $ListName -InternalName "Comments"           -DisplayName "Comments"            -Type Note           -AddToDefaultView

        # Choice columns
        Add-PnPFieldFromXml -List $ListName -FieldXml @"
<Field Type="Choice" DisplayName="Section" InternalName="Section" Required="FALSE" AddToDefaultView="TRUE">
  <CHOICES>
    <CHOICE>AML/CTF</CHOICE>
    <CHOICE>APRA</CHOICE>
    <CHOICE>Breaches</CHOICE>
    <CHOICE>Compliance</CHOICE>
    <CHOICE>Conflicts of Interest</CHOICE>
    <CHOICE>Company Secretary</CHOICE>
    <CHOICE>Cyber-Attack</CHOICE>
    <CHOICE>Dispute Resolution</CHOICE>
    <CHOICE>Document Retention</CHOICE>
    <CHOICE>Financial Resources</CHOICE>
    <CHOICE>Human Resources</CHOICE>
    <CHOICE>Information Technology</CHOICE>
    <CHOICE>Insider Trading</CHOICE>
    <CHOICE>Marketing</CHOICE>
    <CHOICE>Outsourcing</CHOICE>
    <CHOICE>Privacy</CHOICE>
    <CHOICE>Representatives</CHOICE>
    <CHOICE>Responsible Manager</CHOICE>
    <CHOICE>Risk Management</CHOICE>
    <CHOICE>Training</CHOICE>
    <CHOICE>AER</CHOICE>
  </CHOICES>
</Field>
"@

        Add-PnPFieldFromXml -List $ListName -FieldXml @"
<Field Type="Choice" DisplayName="Frequency" InternalName="Frequency" Required="FALSE" AddToDefaultView="TRUE">
  <CHOICES>
    <CHOICE>Monthly</CHOICE>
    <CHOICE>Quarterly</CHOICE>
    <CHOICE>Annually</CHOICE>
    <CHOICE>Biannually</CHOICE>
    <CHOICE>Ad hoc</CHOICE>
    <CHOICE>Every two (2) years</CHOICE>
    <CHOICE>Every three (3) years</CHOICE>
  </CHOICES>
</Field>
"@

        Write-Host "List and columns created successfully." -ForegroundColor Green
    }
}

# ── Import Data ────────────────────────────────────────────────────────────
if ($ImportData -or $ImportOnly) {
    Write-Host "`nImporting compliance obligations…" -ForegroundColor Cyan

    $items = @(
        @{Title="30"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Conduct Risk Assessment."; Reference="AML/CTF Rules, Ch 8, Pt 8.1"; Officer="Director"; Frequency="Every two (2) years"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-05-29"; Comments="Scheduled post AFSL/AUSTRAC enrolment"},
        @{Title="31"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Ongoing customer due diligence."; Reference="AML/CTF Part 13, Division 7"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="33"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Suspicious matter reporting (SMR), threshold transaction reporting (TTR) and IFTI requirements."; Reference="AML/CTF Part 3, Divisions 1 to 4 and 6"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="19"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Enrolment with AUSTRAC."; Reference="s51B / s51F AML/CTF Act"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-06-01"; Comments="Enrol within 28 days of commencing designated services"},
        @{Title="20"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="AML/CTF Compliance Officer."; Reference="AML/CTF Rules, Ch 8, Pt 8.5"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="Not required until July"},
        @{Title="21"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="KYC Identification procedures."; Reference="AML/CTF Act Parts 2 and 10"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="22"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Employee due diligence (risk assessment)."; Reference="AML/CTF Rules, Ch 8, Pt 8.3"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="23"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Employee due diligence (new employees)."; Reference="AML/CTF Rules, Ch 8, Pt 8.3"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="24"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Training of employees in relation to AML/CTF."; Reference="AML/CTF Rules, Ch 8, Pt 8.2"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="Requires enhanced training for July adoption"},
        @{Title="25"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="AML/CTF Compliance reports to AUSTRAC."; Reference="AML/CTF Part 3, Division 5"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2027-01-11"; Comments="Scheduled post AFSL/AUSTRAC enrolment"},
        @{Title="26"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="AML/CTF Program and record-keeping requirements."; Reference="AML/CTF Parts 7 and 10, Division 5"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="27"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Outsourcing - AML/CTF Obligations."; Reference="RG 104"; Officer="Director"; Frequency="Every two (2) years"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2027-01-11"; Comments="Scheduled post AFSL/AUSTRAC enrolment"},
        @{Title="28"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Internal Review of AML/CTF Program."; Reference="AML/CTF Rules Part 8.4"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="29"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Independent Review of AML/CTF Program."; Reference="AML/CTF Rules Part 8.6"; Officer="Director"; Frequency="Every three (3) years"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2027-03-31"; Comments="Scheduled post AFSL/AUSTRAC enrolment"},
        @{Title="32"; Entity="CS Capital Partners"; Section="AML/CTF"; ComplianceObligation="Transaction Monitoring."; Reference="AML/CTF Rules Chapter 15"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-27"; Comments="PC Reviewed"},
        @{Title="36"; Entity="CS Capital Partners"; Section="Breaches"; ComplianceObligation="Retain records of compliance reports and breach notifications."; Reference="RG 104"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="37"; Entity="CS Capital Partners"; Section="Breaches"; ComplianceObligation="Investigate Breaches."; Reference="RG 78"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="38"; Entity="CS Capital Partners"; Section="Breaches"; ComplianceObligation="Reporting Breaches."; Reference="CA 912DAA / RG 78"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="35"; Entity="CS Capital Partners"; Section="Breaches"; ComplianceObligation="Breaches Procedure."; Reference="CA 912A(1) / RG 78"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2027-03-31"; Comments="PC Reviewed"},
        @{Title="1";  Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="General Obligations of AFS Licensee."; Reference="CA 912A / RG 104"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="2";  Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Prohibition on operating Managed Discretionary Accounts."; Reference="AFSL Condition"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="3";  Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Measure for Compliance."; Reference="RG 104 / AFSL Conditions / CA 912A(1)(b)(c)"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="4";  Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="The AFS Licensee is responsible for compliance."; Reference="RG 104"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="5";  Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Review of Compliance Program."; Reference="RG 104"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="6";  Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Delegate director/senior manager to oversee compliance."; Reference="RG 104"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC + Denise + Board approval"},
        @{Title="7";  Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Adequate financial, technological and human resources."; Reference="RG 104 / CA 912A(1)(d)"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="8";  Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Comply with written notice from ASIC to provide information."; Reference="CA 912C"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="9";  Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Not to engage in unconscionable conduct."; Reference="CA 991A / CCA Part 2.2"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="10"; Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Not to engage in unconscionable conduct in trade or commerce."; Reference="AA 12CB / CCA Part 2.2"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="11"; Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Not to engage in false or misleading representations."; Reference="AA 12BB / AA 12DB"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="12"; Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Not to engage in misleading or deceptive conduct."; Reference="AA 12DA / CCA Part 2.1"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="13"; Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Certain misleading conduct in relation to financial services."; Reference="AA 12DF"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="14"; Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Harassment and coercion."; Reference="AA 12DJ"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="15"; Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Not to enter into any anti-competitive agreements."; Reference="CCA Part 4, Division 2, s45"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="16"; Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Not to engage in cartel provisions."; Reference="CCA Part 4, Division 2, s45AD"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="17"; Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Not to engage in secondary boycotts."; Reference="CCA Part 4, Division 2, s45DA"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="18"; Entity="CS Capital Partners"; Section="Compliance"; ComplianceObligation="Compliance Audit."; Reference="RG 104"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="39"; Entity="CS Capital Partners"; Section="Conflicts of Interest"; ComplianceObligation="Conflicts of Interest Procedure."; Reference="CA 912A(1)(aa) / RG 181"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2027-03-31"; Comments="PC Reviewed"},
        @{Title="40"; Entity="CS Capital Partners"; Section="Conflicts of Interest"; ComplianceObligation="Managing Conflicts of Interest."; Reference="CA 912A(1)(aa) / RG 181"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="41"; Entity="CS Capital Partners"; Section="Dispute Resolution"; ComplianceObligation="Internal Dispute Resolution (IDR) system."; Reference="CA 912A(1)(g) / AS/NZS 10002:2014"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2027-03-31"; Comments="PC Reviewed"},
        @{Title="42"; Entity="CS Capital Partners"; Section="Dispute Resolution"; ComplianceObligation="Complaints Management."; Reference="AS/NZS 10002:2014"; Officer="Director"; Frequency="Monthly"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-06-26"; Comments="PC Reviewed"},
        @{Title="43"; Entity="CS Capital Partners"; Section="Dispute Resolution"; ComplianceObligation="Complaints Management Policy."; Reference="AS/NZS 10002:2014"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2027-03-31"; Comments="Not applicable"},
        @{Title="44"; Entity="CS Capital Partners"; Section="Dispute Resolution"; ComplianceObligation="Complaints Register."; Reference="CA 912A(1)(g) / AS/NZS 10002:2014"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="Not applicable"},
        @{Title="45"; Entity="CS Capital Partners"; Section="Cyber-Attack"; ComplianceObligation="Preparation, mitigation, detection and response to cyber-attacks."; Reference=""; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="Not applicable"},
        @{Title="46"; Entity="CS Capital Partners"; Section="Risk Management"; ComplianceObligation="Have adequate risk management systems."; Reference="CA 912A(1)(h) / RG 104"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="Not applicable"},
        @{Title="47"; Entity="CS Capital Partners"; Section="Document Retention"; ComplianceObligation="Retain records to demonstrate compliance."; Reference="RG 104 / RG 105 / AFSL Condition"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="48"; Entity="CS Capital Partners"; Section="Document Retention"; ComplianceObligation="Obligation to keep all financial records."; Reference="CA 286 / CA 988A-E"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="49"; Entity="CS Capital Partners"; Section="Financial Resources"; ComplianceObligation="Financial statements."; Reference="CA 989A-D / CA 308 / CA 319 / AFSL Condition"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="50"; Entity="CS Capital Partners"; Section="Financial Resources"; ComplianceObligation="Address financial resources not being adequate."; Reference="RG 104 / RG 166 / s912A(1)(d)(h)"; Officer="Director"; Frequency="Monthly"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="Not applicable"},
        @{Title="51"; Entity="CS Capital Partners"; Section="Financial Resources"; ComplianceObligation="Solvency, positive net assets and cash projections (12+ months)."; Reference="RG 166 / AFSL Condition"; Officer="Director"; Frequency="Monthly"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="Not applicable"},
        @{Title="52"; Entity="CS Capital Partners"; Section="Financial Resources"; ComplianceObligation="Appointment of auditor."; Reference="CA 990B"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate=""; ReviewDate="2027-01-11"; Comments="Not applicable"},
        @{Title="53"; Entity="CS Capital Partners"; Section="Financial Resources"; ComplianceObligation="Holding client money or property."; Reference="AFSL Condition"; Officer="Director"; Frequency="Monthly"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="Not applicable"},
        @{Title="54"; Entity="CS Capital Partners"; Section="Financial Resources"; ComplianceObligation="Review of Client Money Policy."; Reference="RG 104"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2027-07-01"; Comments="Not applicable for this FY"},
        @{Title="55"; Entity="CS Capital Partners"; Section="Financial Resources"; ComplianceObligation="Reporting triggers and financial reporting conditions."; Reference="AFSL Condition"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="Not applicable"},
        @{Title="56"; Entity="CS Capital Partners"; Section="Human Resources"; ComplianceObligation="Adequate human resources."; Reference="RG 104"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="57"; Entity="CS Capital Partners"; Section="Representatives"; ComplianceObligation="Appointing Representatives."; Reference="RG 104 / CA 916A"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="58"; Entity="CS Capital Partners"; Section="Representatives"; ComplianceObligation="Maintain competence of Representatives."; Reference="RG 104 / RG 146"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="59"; Entity="CS Capital Partners"; Section="Representatives"; ComplianceObligation="Training of Representatives."; Reference="CA 912A(1)(f)"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Register and training program set up to track CPD"},
        @{Title="60"; Entity="CS Capital Partners"; Section="Representatives"; ComplianceObligation="Monitor and supervise the activities of Representatives."; Reference="RG 104.67 / RG 104.72 / CA 912A(1)(ca)"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="61"; Entity="CS Capital Partners"; Section="Representatives"; ComplianceObligation="Notification of changes to Representatives to ASIC."; Reference="RG 104"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="62"; Entity="CS Capital Partners"; Section="Representatives"; ComplianceObligation="Annual Review - Fit and Proper Persons."; Reference="RG 104"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2025-07-31"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="63"; Entity="CS Capital Partners"; Section="Responsible Manager"; ComplianceObligation="Organisational competence obligation."; Reference="RG 105"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2025-07-31"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="64"; Entity="CS Capital Partners"; Section="Responsible Manager"; ComplianceObligation="Advise ASIC of change in Responsible Manager."; Reference="RG 105"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="N/A until AFSL application submitted"},
        @{Title="65"; Entity="CS Capital Partners"; Section="Responsible Manager"; ComplianceObligation="Key person requirements."; Reference="AFSL Condition"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="No changes"},
        @{Title="66"; Entity="CS Capital Partners"; Section="Training"; ComplianceObligation="Training of CS Capital Partners representatives."; Reference="RG 104"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2025-07-31"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="67"; Entity="CS Capital Partners"; Section="Training"; ComplianceObligation="Training policy and procedures."; Reference="RG 146"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2027-03-31"; Comments="PC Reviewed"},
        @{Title="68"; Entity="CS Capital Partners"; Section="Outsourcing"; ComplianceObligation="CS Capital Partners retains responsibility when services are outsourced."; Reference="RG 104"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2027-03-31"; Comments="PC Reviewed"},
        @{Title="69"; Entity="CS Capital Partners"; Section="Outsourcing"; ComplianceObligation="Ongoing monitoring of service providers."; Reference="RG 104"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="70"; Entity="CS Capital Partners"; Section="Outsourcing"; ComplianceObligation="Review of service providers."; Reference="RG 104"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="71"; Entity="CS Capital Partners"; Section="Information Technology"; ComplianceObligation="Regularly review adequacy of IT systems."; Reference="RG 104"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="72"; Entity="CS Capital Partners"; Section="Information Technology"; ComplianceObligation="Disaster Recovery Plan."; Reference="RG 104"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="73"; Entity="CS Capital Partners"; Section="Insider Trading"; ComplianceObligation="Monitor all trading conducted by representatives."; Reference="CA 1043A/F/K"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="74"; Entity="CS Capital Partners"; Section="Insider Trading"; ComplianceObligation="Educate representatives regarding illegality of market manipulation."; Reference="CA 1041A-H"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="75"; Entity="CS Capital Partners"; Section="Insider Trading"; ComplianceObligation="Monitor all representatives for market manipulation."; Reference="CA 1041A-H"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="76"; Entity="CS Capital Partners"; Section="Insider Trading"; ComplianceObligation="Report all instances of market manipulation to ASIC immediately."; Reference="CA 1041A-H"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="77"; Entity="CS Capital Partners"; Section="Insider Trading"; ComplianceObligation="Company policies to prevent insider information affecting operations."; Reference="CA 1043A/F/K"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2027-03-31"; Comments="PC Reviewed"},
        @{Title="78"; Entity="CS Capital Partners"; Section="Marketing"; ComplianceObligation="Review all advertising and marketing material."; Reference="CA 1018A"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="79"; Entity="CS Capital Partners"; Section="Marketing"; ComplianceObligation="AFSL number to appear on all financial service documents."; Reference="CA 912F"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="Not applicable to CS"},
        @{Title="80"; Entity="CS Capital Partners"; Section="Marketing"; ComplianceObligation="Restrictions on use of certain words and expressions."; Reference="CA 923B"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="81"; Entity="CS Capital Partners"; Section="Marketing"; ComplianceObligation="Not to engage in bait advertising."; Reference="AA 12DG"; Officer="Director"; Frequency="Quarterly"; CompletedStatus="Yes"; CompletionDate="2026-04-13"; ReviewDate="2026-07-15"; Comments="PC Reviewed"},
        @{Title="82"; Entity="CS Capital Partners"; Section="Marketing"; ComplianceObligation="Not to engage in referral selling."; Reference="AA 12DH / CCA Part 3.1"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="83"; Entity="CS Capital Partners"; Section="Marketing"; ComplianceObligation="Not to engage in pyramid selling."; Reference="AA 12DK"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="84"; Entity="CS Capital Partners"; Section="Marketing"; ComplianceObligation="Not to misuse market power."; Reference="CCA Part 3.1, Division 3, s46"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="85"; Entity="CS Capital Partners"; Section="Privacy"; ComplianceObligation="Privacy Policy."; Reference="Privacy Act"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2027-03-31"; Comments="PC Reviewed"},
        @{Title="86"; Entity="CS Capital Partners"; Section="Privacy"; ComplianceObligation="Australian Privacy Principles."; Reference="Australian Privacy Principles"; Officer="Director"; Frequency="Annually"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2027-03-31"; Comments="PC Reviewed"},
        @{Title="87"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Notification to former representatives' clients."; Reference="AFSL Condition"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="88"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Powers of Attorney."; Reference="CA 52A"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="89"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Business address."; Reference="CA 100"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="90"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Register of Members."; Reference="CA 169"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="91"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Indemnification and exemption of officer or auditor."; Reference="CA 199A"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="92"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Consent to act as Director."; Reference="CA 201D"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="93"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Appointment of Directors."; Reference="CA 201J"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="94"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Appointment of Director - notify ASIC within 28 days."; Reference="CA 201L"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="95"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Consent to act as Secretary."; Reference="CA 204C"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="96"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Notice of retirement or resignation of Director or Secretary."; Reference="CA 205A"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="97"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Notice of name and address of a Director and Secretary."; Reference="CA 205B"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus="Yes"; CompletionDate="2026-03-31"; ReviewDate="2026-05-29"; Comments="PC Reviewed"},
        @{Title="98"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Financial reports."; Reference="CA 292"; Officer="Director"; Frequency="Annually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"},
        @{Title="99"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Quarterly Return Form (ESVCLP - Luft)."; Reference="VCA s15-10"; Officer="Director"; Frequency="Quarterly"; CompletedStatus=""; CompletionDate=""; ReviewDate="2026-07-01"; Comments="Review in next cycle"},
        @{Title="100"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Annual Return Form (ESVCLP - Luft)."; Reference="VCA s15-1"; Officer="Director"; Frequency="Annually"; CompletedStatus=""; CompletionDate=""; ReviewDate="2026-09-01"; Comments="Review in next cycle"},
        @{Title="101"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Investments or disposals (ESVCLP)."; Reference="VCA s15-15"; Officer="Director"; Frequency="Quarterly"; CompletedStatus=""; CompletionDate=""; ReviewDate="2026-07-01"; Comments="Review in next cycle"},
        @{Title="102"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Responding to Industry Innovation Australia - information requested (VCA)."; Reference="VCA s15-20"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus=""; CompletionDate=""; ReviewDate="2026-05-29"; Comments="Review in next cycle"},
        @{Title="103"; Entity="CS Capital Partners"; Section="Company Secretary"; ComplianceObligation="Repeated breaches in relation to holding ineligible investments."; Reference="VCA s9-3(1)(f)"; Officer="Director"; Frequency="Ad hoc"; CompletedStatus=""; CompletionDate=""; ReviewDate="2026-05-29"; Comments="Review in next cycle"},
        @{Title="34"; Entity="CS Capital Partners"; Section="APRA"; ComplianceObligation="Form 701 Reporting Requirements."; Reference="CR Part 7.6B"; Officer="Director"; Frequency="Biannually"; CompletedStatus="N/A"; CompletionDate=""; ReviewDate="2026-07-15"; Comments="Review in next cycle"}
    )

    $count = 0
    foreach ($item in $items) {
        $values = @{
            Title                = $item.Title
            Entity               = $item.Entity
            Section              = $item.Section
            ComplianceObligation = $item.ComplianceObligation
            Reference            = $item.Reference
            Officer              = $item.Officer
            Frequency            = $item.Frequency
            CompletedStatus      = $item.CompletedStatus
            Comments             = $item.Comments
        }
        if ($item.CompletionDate) { $values.CompletionDate = [DateTime]::Parse($item.CompletionDate) }
        if ($item.ReviewDate)     { $values.ReviewDate     = [DateTime]::Parse($item.ReviewDate) }

        Add-PnPListItem -List $ListName -Values $values | Out-Null
        $count++
        Write-Progress -Activity "Importing obligations" -Status "Item $count of $($items.Count)" -PercentComplete (($count/$items.Count)*100)
    }

    Write-Host "`nImported $count items into '$ListName'." -ForegroundColor Green
}

Write-Host "`nDone. Open your SharePoint site to verify the list." -ForegroundColor Cyan
