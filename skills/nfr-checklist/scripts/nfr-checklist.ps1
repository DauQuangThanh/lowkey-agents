# =============================================================================
# nfr-checklist.ps1 — Phase 5: Non-Functional Requirements Checklist (PowerShell)
# Output: $BAOutputDir\05-nfr.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:BA_AUTO = '1' }
if ($Answers) { $env:BA_ANSWERS = $Answers }


$OutputFile = Join-Path $script:BAOutputDir "05-nfr.md"
$Area       = "Non-Functional Requirements"

$startDebts = Get-BA-DebtCount

$script:Nfrs = @()
function Add-Nfr {
  param([string]$AreaName, [string]$Desc, [string]$Priority)
  $script:Nfrs += "| **$AreaName** | $Desc | $Priority |"
}

function Nfr-Section {
  param([int]$Num, [int]$Total, [string]$AreaName, [string]$PlainDesc)
  Write-Host ""
  Write-BA-Dim ("  {0} of {1}" -f $Num, $Total)
  Write-Host "── $AreaName ──" -ForegroundColor Cyan
  Write-BA-Dim "  $PlainDesc"
}

# ── Header ────────────────────────────────────────────────────────────────────
Write-BA-Banner "⚙  Step 5 of 7 — Non-Functional Requirements"
Write-BA-Dim "  These questions are about HOW the system should behave — not WHAT it does."
Write-Host ""

# ── 1. Performance ────────────────────────────────────────────────────────────
Nfr-Section 1 9 "Performance" "How fast the system must respond to users"
if ((Ask-BA-YN "Is performance a concern for your project?") -eq "yes") {
  Write-Host ""
  $users = Ask-BA-Choice "  How many users do you expect at the same time?" @(
    "Under 10 — Very small team",
    "10–100 — Small organisation",
    "100–1,000 — Medium sized",
    "1,000–10,000 — Large",
    "Over 10,000 — Public scale"
  )
  $load = Ask-BA-Choice "  How fast should pages/actions load?" @(
    "Under 1 second (instant feel)",
    "Under 3 seconds (acceptable)",
    "Under 5 seconds (tolerable)",
    "No strict requirement"
  )
  Add-Nfr "Performance" "Concurrent users: $users | Page load target: $load" "Must Have"
}

# ── 2. Security ───────────────────────────────────────────────────────────────
Nfr-Section 2 9 "Security" "Protecting data and preventing unauthorised access"
if ((Ask-BA-YN "Does the system handle sensitive or private data?") -eq "yes") {
  Write-Host ""
  $dataType = Ask-BA-Choice "  What kind of sensitive data? (choose the most sensitive)" @(
    "General personal info (names, emails, addresses)",
    "Financial data (payment info, bank details)",
    "Health or medical records",
    "Legal or confidential business data",
    "Multiple types — all of the above"
  )
  $hasEnc   = Ask-BA-YN "  Must data be encrypted at rest AND in transit (HTTPS)?"
  $hasAudit = Ask-BA-YN "  Must security events (logins, failed attempts) be logged?"

  $encNote = "Yes — encryption required (HTTPS + at-rest)"
  if ($hasEnc -eq "no") { $encNote = "Standard HTTPS only" }
  $auditNote = "Yes"
  if ($hasAudit -eq "no") { $auditNote = "No" }

  Add-Nfr "Security" "Sensitive data type: $dataType | Encryption: $encNote | Audit log: $auditNote" "Must Have"
  Add-BA-Debt -Area $Area -Title "Security requirements need expert review" `
    -Description "Security NFRs captured but need review by a security professional" `
    -Impact "Compliance gaps may create legal risk"
}

# ── 3. Scalability ────────────────────────────────────────────────────────────
Nfr-Section 3 9 "Scalability" "How much the system might grow in users or data"
if ((Ask-BA-YN "Do you expect significant growth in users or data in the next 1–3 years?") -eq "yes") {
  Write-Host ""
  $growth = Ask-BA-Choice "  Expected growth rate:" @(
    "2× — Double in size",
    "5× — Five times bigger",
    "10× — Ten times bigger",
    "100×+ — Massive growth (public product)"
  )
  Add-Nfr "Scalability" "System must scale to $growth current capacity within 1–3 years" "Should Have"
}

# ── 4. Availability ───────────────────────────────────────────────────────────
Nfr-Section 4 9 "Availability / Uptime" "How often the system must be running without downtime"
if ((Ask-BA-YN "Is high availability or uptime important?") -eq "yes") {
  Write-Host ""
  $uptime = Ask-BA-Choice "  Required availability level:" @(
    "99% — About 3.6 days downtime per year (business hours only)",
    "99.5% — About 1.8 days downtime per year",
    "99.9% — About 8.7 hours downtime per year (standard SLA)",
    "99.99% — About 52 minutes downtime per year",
    "24/7 zero tolerance — Mission critical"
  )
  $maint = Ask-BA-YN "  Can maintenance happen at night/weekends? (planned downtime OK?)"
  $maintNote = "Planned maintenance windows allowed"
  if ($maint -eq "no") { $maintNote = "No planned downtime — zero-downtime deployments required" }
  Add-Nfr "Availability" "Target: $uptime | Maintenance: $maintNote" "Must Have"
}

# ── 5. Usability ─────────────────────────────────────────────────────────────
Nfr-Section 5 9 "Usability & Accessibility" "How easy the system is to use"
if ((Ask-BA-YN "Are there specific usability or accessibility requirements?") -eq "yes") {
  Write-Host ""
  $hasA11y = Ask-BA-YN "  Must the system comply with accessibility standards?"
  $skill = Ask-BA-Choice "  What is the expected technical skill level of most users?" @(
    "Non-technical — No IT background",
    "Mixed — Some technical, some not",
    "Technical — All users are IT-savvy"
  )
  $a11yNote = "No formal standard"
  if ($hasA11y -eq "yes") { $a11yNote = "WCAG 2.1 AA compliance required" }
  Add-Nfr "Usability" "Target user skill: $skill | Accessibility: $a11yNote" "Should Have"
}

# ── 6. Data Retention ─────────────────────────────────────────────────────────
Nfr-Section 6 9 "Data Retention" "How long data must be kept and when it can be deleted"
if ((Ask-BA-YN "Are there rules about how long data must be stored?") -eq "yes") {
  Write-Host ""
  $ret = Ask-BA-Choice "  How long must records be kept?" @(
    "1 year",
    "3 years",
    "5 years",
    "7 years (common legal/tax requirement)",
    "Indefinitely",
    "Defined by regulation — not yet confirmed"
  )
  if ($ret -eq "Defined by regulation — not yet confirmed") {
    Add-BA-Debt -Area $Area -Title "Data retention period not confirmed" `
      -Description "Retention is required but the specific duration is not confirmed" `
      -Impact "Legal and storage architecture depend on this"
  }
  Add-Nfr "Data Retention" "Records must be retained for: $ret" "Must Have"
}

# ── 7. Compliance ─────────────────────────────────────────────────────────────
Nfr-Section 7 9 "Regulatory Compliance" "Legal or industry standards the system must meet"
if ((Ask-BA-YN "Must the system comply with any specific regulations or standards?") -eq "yes") {
  Write-Host ""
  Write-BA-Dim "  Check all that apply (y/n for each):"
  $gdpr  = Ask-BA-YN "  GDPR — European data privacy rules?"
  $hipaa = Ask-BA-YN "  HIPAA — US healthcare data rules?"
  $pci   = Ask-BA-YN "  PCI-DSS — Payment card security rules?"
  $iso   = Ask-BA-YN "  ISO 27001 — Information security management?"
  $otherReg = Ask-BA-YN "  Any other regulation not listed?"
  $otherName = ""
  if ($otherReg -eq "yes") {
    $otherName = Ask-BA-Text "  Name the regulation(s):"
    if ([string]::IsNullOrWhiteSpace($otherName)) {
      Add-BA-Debt -Area $Area -Title "Unknown compliance requirement" `
        -Description "User indicated other regulations but did not specify" `
        -Impact "Legal exposure if compliance missed"
    }
  }

  $list = @()
  if ($gdpr  -eq "yes") { $list += "GDPR" }
  if ($hipaa -eq "yes") { $list += "HIPAA" }
  if ($pci   -eq "yes") { $list += "PCI-DSS" }
  if ($iso   -eq "yes") { $list += "ISO 27001" }
  if (-not [string]::IsNullOrWhiteSpace($otherName)) { $list += $otherName }

  if ($list.Count -gt 0) {
    Add-Nfr "Compliance" ("Must comply with: " + ($list -join ", ")) "Must Have"
  }
  Add-BA-Debt -Area $Area -Title "Compliance requirements need legal review" `
    -Description "Compliance standards identified but not yet validated with legal/compliance team" `
    -Impact "Non-compliance creates legal and financial risk"
}

# ── 8. Backup & Recovery ──────────────────────────────────────────────────────
Nfr-Section 8 9 "Backup & Disaster Recovery" "What happens if the system fails or data is lost"
if ((Ask-BA-YN "Do you have requirements for backup and recovery?") -eq "yes") {
  Write-Host ""
  $rto = Ask-BA-Choice "  RTO — How quickly must the system be back online after a failure?" @(
    "Under 1 hour",
    "Under 4 hours",
    "Under 24 hours",
    "Within 1 week",
    "No strict requirement"
  )
  $rpo = Ask-BA-Choice "  RPO — How much data loss is acceptable in a worst case?" @(
    "Zero — No data can be lost",
    "Up to 1 hour of data",
    "Up to 24 hours of data",
    "Up to 1 week of data"
  )
  Add-Nfr "Backup & Recovery" "Recovery Time Objective (RTO): $rto | Recovery Point Objective (RPO): $rpo" "Must Have"
}

# ── 9. Other NFR ─────────────────────────────────────────────────────────────
Nfr-Section 9 9 "Other Quality Requirements" "Anything else about how the system must behave"
if ((Ask-BA-YN "Any other quality or constraint requirements not covered?") -eq "yes") {
  $other = Ask-BA-Text "  Describe briefly:"
  if ([string]::IsNullOrWhiteSpace($other)) {
    $other = "TBD"
    Add-BA-Debt -Area $Area -Title "Additional NFR not specified" `
      -Description "User indicated another quality requirement but did not provide detail" `
      -Impact "May affect architecture"
  }
  Add-Nfr "Other" $other "TBD"
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-BA-SuccessRule ("✅ Non-Functional Requirements Summary ({0} captured)" -f $script:Nfrs.Count)
foreach ($n in $script:Nfrs) { Write-Host "  $n" }
Write-Host ""

if (-not (Confirm-BA-Save "Save? (y=save / n=redo)")) {
  & $PSCommandPath
  return
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$lines  = @()
$lines += "# Non-Functional Requirements"
$lines += ""
$lines += "> Captured: $DateNow"
$lines += ""
$lines += "## NFR Table"
$lines += ""
$lines += "| Area | Requirement | Priority |"
$lines += "|---|---|---|"
foreach ($n in $script:Nfrs) { $lines += $n }
$lines += ""
$lines += "## Notes"
$lines += ""
$lines += "NFR count: $($script:Nfrs.Count)"
$lines += ""
$lines += "> ⚠ Non-functional requirements should be reviewed by a technical architect"
$lines += "> to ensure they are realistic and achievable within budget."
$lines += ""
$lines | Set-Content -Path $OutputFile -Encoding UTF8

$endDebts = Get-BA-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host "  Saved to: $OutputFile" -ForegroundColor Green
if ($newDebts -gt 0) { Write-Host "  ⚠  $newDebts debt(s) logged." -ForegroundColor Yellow }
Write-Host ""
