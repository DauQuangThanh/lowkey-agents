# =============================================================================
# elicit-requirements.ps1 — Phase 3: Functional Requirements Elicitation (PowerShell)
# Output: $BAOutputDir\03-requirements.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:BA_AUTO = '1' }
if ($Answers) { $env:BA_ANSWERS = $Answers }


$OutputFile = Join-Path $script:BAOutputDir "03-requirements.md"
$Area       = "Requirements Elicitation"

$startDebts = Get-BA-DebtCount

$script:ReqCount     = 0
$script:Requirements = @()

function Add-Req {
  param([string]$Cat, [string]$Desc, [string]$Priority)
  $script:ReqCount++
  $id = "FR-{0:D3}" -f $script:ReqCount
  $script:Requirements += [PSCustomObject]@{
    Id = $id; Category = $Cat; Description = $Desc; Priority = $Priority
  }
}

$TotalCategories = 14
$script:CatNum   = 0

function Category-Header {
  param([string]$Cat, [string]$Desc)
  $script:CatNum++
  Write-Host ""
  Write-BA-Dim ("  Category {0} of {1}" -f $script:CatNum, $TotalCategories)
  Write-Host "── $Cat ──" -ForegroundColor Cyan
  Write-BA-Dim "  $Desc"
}

# ── Header ────────────────────────────────────────────────────────────────────
Write-BA-Banner "📝  Step 3 of 7 — Requirements Elicitation"
Write-BA-Dim "  I'll go through common feature categories one at a time."
Write-BA-Dim "  For each, answer y (yes) or n (no)."
Write-Host ""

# ── 1. User Accounts ─────────────────────────────────────────────────────────
Category-Header "User Accounts" "Login, registration, profiles, and roles"
if ((Ask-BA-YN "Does your system need User Accounts?") -eq "yes") {
  Write-Host ""
  Write-BA-Dim "  Which of these do you need? (y/n for each)"
  $hasReg    = Ask-BA-YN "  User registration (sign up with email/password)?"
  $hasSocial = Ask-BA-YN "  Social login (e.g. 'Sign in with Google')?"
  $hasMfa    = Ask-BA-YN "  Two-factor authentication?"
  $hasRoles  = Ask-BA-YN "  Different roles/permissions (e.g. Admin vs Regular User)?"
  $hasProf   = Ask-BA-YN "  User profiles (name, photo, preferences)?"
  $hasReset  = Ask-BA-YN "  Password reset via email?"

  $rolesDetail = "Standard roles"
  if ($hasRoles -eq "yes") {
    $rolesDetail = Ask-BA-Text "  Briefly describe the roles needed (e.g. 'Admin, Manager, Staff, Customer'):"
    if ([string]::IsNullOrWhiteSpace($rolesDetail)) { $rolesDetail = "Standard roles" }
  }

  if ($hasReg    -eq "yes") { Add-Req "User Accounts" "Users can register, log in, and manage their accounts" "Must Have" }
  if ($hasSocial -eq "yes") { Add-Req "User Accounts" "Users can log in using Google or similar social provider" "Should Have" }
  if ($hasMfa    -eq "yes") { Add-Req "User Accounts" "Two-factor authentication (MFA) available for users" "Should Have" }
  if ($hasRoles  -eq "yes") { Add-Req "User Accounts" "Role-based access control: $rolesDetail" "Must Have" }
  if ($hasProf   -eq "yes") { Add-Req "User Accounts" "Users can view and edit their profile information" "Should Have" }
  if ($hasReset  -eq "yes") { Add-Req "User Accounts" "Users can reset their password via email" "Must Have" }
}

# ── 2. Data Management ────────────────────────────────────────────────────────
Category-Header "Data Management" "Creating, viewing, editing, and deleting records"
if ((Ask-BA-YN "Does your system need Data Management?") -eq "yes") {
  Write-Host ""
  Write-BA-Dim "  What is the main type of data your system manages?"
  $dataType = Ask-BA-Text "  (e.g. 'customer orders', 'patient records', 'inventory items')"
  if ([string]::IsNullOrWhiteSpace($dataType)) {
    $dataType = "records"
    Add-BA-Debt -Area $Area -Title "Core data type not specified" `
      -Description "The main data entity of the system was not named" `
      -Impact "Cannot design data model or core screens"
  }
  $hasBulk    = Ask-BA-YN "  Do users need to import/export data via spreadsheet (CSV/Excel)?"
  $hasSearch  = Ask-BA-YN "  Do users need to search or filter records?"
  $hasHistory = Ask-BA-YN "  Should the system keep a history of changes to records?"

  Add-Req "Data Management" "Users can create, view, edit, and delete $dataType" "Must Have"
  if ($hasBulk    -eq "yes") { Add-Req "Data Management" "Users can import/export $dataType via CSV or Excel" "Should Have" }
  if ($hasSearch  -eq "yes") { Add-Req "Data Management" "Users can search and filter $dataType by key fields" "Must Have" }
  if ($hasHistory -eq "yes") { Add-Req "Data Management" "System maintains an audit history of changes to $dataType" "Should Have" }
}

# ── 3. Reporting & Analytics ──────────────────────────────────────────────────
Category-Header "Reporting & Analytics" "Charts, dashboards, summaries, and data exports"
if ((Ask-BA-YN "Does your system need Reporting & Analytics?") -eq "yes") {
  Write-Host ""
  $reportType = Ask-BA-Choice "  What kind of reporting is most important?" @(
    "Simple summary tables (total counts, basic stats)",
    "Charts and graphs (trends over time, comparisons)",
    "Full dashboard with multiple views",
    "Scheduled reports sent by email",
    "All of the above"
  )
  $hasExport = Ask-BA-YN "  Can users export reports to PDF or Excel?"
  Add-Req "Reporting" "System provides $reportType for relevant data" "Must Have"
  if ($hasExport -eq "yes") { Add-Req "Reporting" "Users can export reports to PDF and/or Excel format" "Should Have" }
}

# ── 4. Notifications ──────────────────────────────────────────────────────────
Category-Header "Notifications" "Automatic alerts sent to users when something happens"
if ((Ask-BA-YN "Does your system need Notifications?") -eq "yes") {
  Write-Host ""
  $notifChannel = Ask-BA-Choice "  How should notifications be delivered?" @(
    "Email only",
    "In-app notifications only",
    "Both email and in-app",
    "SMS text messages",
    "Multiple channels — I'll specify later"
  )
  if ($notifChannel -eq "Multiple channels — I'll specify later") {
    Add-BA-Debt -Area $Area -Title "Notification channels not specified" `
      -Description "Multiple channels were indicated but not confirmed" `
      -Impact "Cannot implement notification system without knowing channels"
  }
  $notifTrigger = Ask-BA-Text "  What should trigger a notification?"
  if ([string]::IsNullOrWhiteSpace($notifTrigger)) {
    $notifTrigger = "TBD"
    Add-BA-Debt -Area $Area -Title "Notification triggers not defined" `
      -Description "Events that trigger notifications were not specified" `
      -Impact "Cannot build notification logic"
  }
  Add-Req "Notifications" "System sends notifications via $notifChannel when: $notifTrigger" "Must Have"
}

# ── 5. Integrations ───────────────────────────────────────────────────────────
Category-Header "Integrations" "Connecting with other software systems"
if ((Ask-BA-YN "Does your system need Integrations?") -eq "yes") {
  Write-Host ""
  $integrations = Ask-BA-Text "  What system(s) should it connect to? (e.g. 'Salesforce, QuickBooks, Stripe')"
  if ([string]::IsNullOrWhiteSpace($integrations)) {
    $integrations = "TBD"
    Add-BA-Debt -Area $Area -Title "Integration targets not specified" `
      -Description "Integrations were confirmed but no systems were named" `
      -Impact "Cannot estimate integration complexity or cost"
  }
  Add-Req "Integrations" "System integrates with: $integrations" "Must Have"
}

# ── 6. Payments ───────────────────────────────────────────────────────────────
Category-Header "Payments" "Accepting online payments, subscriptions, or invoicing"
if ((Ask-BA-YN "Does your system need Payments?") -eq "yes") {
  Write-Host ""
  $payType = Ask-BA-Choice "  What type of payment processing is needed?" @(
    "One-time payments (e.g. purchase a product)",
    "Recurring subscriptions (e.g. monthly/annual plan)",
    "Invoice generation and manual payment",
    "All of the above"
  )
  Add-Req "Payments" "System supports $payType" "Must Have"
  Add-BA-Debt -Area $Area -Title "Payment provider not selected" `
    -Description "Payment processing is required but no provider (e.g. Stripe, PayPal) was chosen" `
    -Impact "Technology and compliance decisions depend on provider"
}

# ── 7. File Handling ──────────────────────────────────────────────────────────
Category-Header "File Handling" "Uploading, downloading, and managing documents or images"
if ((Ask-BA-YN "Does your system need File Handling?") -eq "yes") {
  Write-Host ""
  $fileTypes = Ask-BA-Text "  What file types? (e.g. 'PDF, images, Word documents')"
  if ([string]::IsNullOrWhiteSpace($fileTypes)) {
    $fileTypes = "TBD"
    Add-BA-Debt -Area $Area -Title "Accepted file types not specified" `
      -Description "File handling is needed but accepted formats not confirmed" `
      -Impact "Storage, validation, and security rules depend on file types"
  }
  Add-Req "File Handling" "Users can upload, download, and manage files: $fileTypes" "Must Have"
}

# ── 8. Workflows & Approvals ─────────────────────────────────────────────────
Category-Header "Workflows & Approvals" "Multi-step processes with reviews/approvals"
if ((Ask-BA-YN "Does your system need Workflows & Approvals?") -eq "yes") {
  Write-Host ""
  $wfDesc = Ask-BA-Text "  Describe the main approval workflow in plain terms"
  if ([string]::IsNullOrWhiteSpace($wfDesc)) {
    $wfDesc = "TBD"
    Add-BA-Debt -Area $Area -Title "Approval workflow not described" `
      -Description "An approval workflow is needed but steps are undefined" `
      -Impact "Cannot design workflow engine or state machine"
  }
  Add-Req "Workflows" "System supports the following approval workflow: $wfDesc" "Must Have"
}

# ── 9. Communication / Collaboration ─────────────────────────────────────────
Category-Header "Communication / Collaboration" "In-system messaging, comments, team collaboration"
if ((Ask-BA-YN "Does your system need Communication / Collaboration?") -eq "yes") {
  Write-Host ""
  $commType = Ask-BA-Choice "  What kind of communication features are needed?" @(
    "Comments on records",
    "Direct messaging between users",
    "Team channels (like a simple Slack inside the app)",
    "All of the above"
  )
  Add-Req "Communication" "System includes: $commType" "Should Have"
}

# ── 10. Mobile Access ─────────────────────────────────────────────────────────
Category-Header "Mobile Access" "Using the system on phones or tablets"
if ((Ask-BA-YN "Does your system need Mobile Access?") -eq "yes") {
  Write-Host ""
  $mobile = Ask-BA-Choice "  What type of mobile access is required?" @(
    "Mobile-friendly website (works in phone browser)",
    "Native iOS app (Apple)",
    "Native Android app",
    "Both iOS and Android native apps"
  )
  Add-Req "Mobile" "System supports: $mobile" "Must Have"
}

# ── 11. Admin Panel ───────────────────────────────────────────────────────────
Category-Header "Admin / Configuration Panel" "Settings area where administrators configure the system"
if ((Ask-BA-YN "Does your system need an Admin Panel?") -eq "yes") {
  Write-Host ""
  $adminFeat = Ask-BA-Text "  What should admins be able to do?"
  if ([string]::IsNullOrWhiteSpace($adminFeat)) {
    $adminFeat = "Standard admin functions"
    Add-BA-Debt -Area $Area -Title "Admin panel scope undefined" `
      -Description "An admin panel is needed but features were not specified" `
      -Impact "Cannot scope admin module"
  }
  Add-Req "Admin" "Admin panel allows: $adminFeat" "Must Have"
}

# ── 12. Multi-language / Multi-region ────────────────────────────────────────
Category-Header "Multi-language / Multi-region" "Different languages, currencies, or time zones"
if ((Ask-BA-YN "Does your system need Multi-language or Multi-region support?") -eq "yes") {
  Write-Host ""
  $languages = Ask-BA-Text "  Which languages/regions? (e.g. 'English and Vietnamese, VND and USD')"
  if ([string]::IsNullOrWhiteSpace($languages)) {
    $languages = "TBD"
    Add-BA-Debt -Area $Area -Title "Languages/regions not specified" `
      -Description "Multi-language support was confirmed but languages not named" `
      -Impact "Cannot estimate localisation effort"
  }
  Add-Req "Localisation" "System supports: $languages" "Must Have"
}

# ── 13. Offline Mode ──────────────────────────────────────────────────────────
Category-Header "Offline Mode" "Using the system without an internet connection"
if ((Ask-BA-YN "Does your system need Offline Mode?") -eq "yes") {
  Write-Host ""
  $offline = Ask-BA-Text "  What should work offline?"
  if ([string]::IsNullOrWhiteSpace($offline)) {
    $offline = "TBD"
    Add-BA-Debt -Area $Area -Title "Offline feature scope undefined" `
      -Description "Offline mode confirmed but specific features not defined" `
      -Impact "Offline/sync architecture decisions depend on scope"
  }
  Add-Req "Offline" "Offline mode supports: $offline" "Must Have"
}

# ── 14. Other ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-BA-Dim "  Category $TotalCategories of $TotalCategories"
Write-Host "── Anything Else? ──" -ForegroundColor Cyan
Write-BA-Dim "  Is there any other feature that's important but wasn't covered above?"
if ((Ask-BA-YN "Any other important features not covered?") -eq "yes") {
  $otherDesc = Ask-BA-Text "  Describe the feature briefly:"
  if ([string]::IsNullOrWhiteSpace($otherDesc)) { $otherDesc = "TBD" }
  Add-Req "Other" $otherDesc "TBD"
  Add-BA-Debt -Area $Area -Title "Additional feature detail missing" `
    -Description "User indicated another feature but did not provide enough detail: '$otherDesc'" `
    -Impact "Needs further elicitation"
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-BA-SuccessRule ("✅ Requirements Summary ({0} requirements captured)" -f $script:ReqCount)
foreach ($r in $script:Requirements) {
  Write-Host ("  [{0}] ({1}) [{2}] {3}" -f $r.Id, $r.Priority, $r.Category, $r.Description)
}
Write-Host ""

if (-not (Confirm-BA-Save "Save these requirements? (y=save / n=redo)")) {
  & $PSCommandPath
  return
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$lines  = @()
$lines += "# Functional Requirements"
$lines += ""
$lines += "> Captured: $DateNow"
$lines += ""
$lines += "## Requirements List"
$lines += ""
$lines += "| ID | Category | Requirement | Priority |"
$lines += "|---|---|---|---|"
foreach ($r in $script:Requirements) {
  $lines += ("| {0} | {1} | {2} | {3} |" -f $r.Id, $r.Category, $r.Description, $r.Priority)
}
$lines += ""
$lines += "## Summary"
$lines += ""
$lines += "Total functional requirements captured: $($script:ReqCount)"
$lines += ""
$lines | Set-Content -Path $OutputFile -Encoding UTF8

$endDebts = Get-BA-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host "  Saved to: $OutputFile" -ForegroundColor Green
if ($newDebts -gt 0) { Write-Host "  ⚠  $newDebts debt(s) logged." -ForegroundColor Yellow }
Write-Host ""
