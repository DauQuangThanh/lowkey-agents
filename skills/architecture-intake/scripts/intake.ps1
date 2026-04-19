# =============================================================================
# intake.ps1 — Phase 1: Architecture Intake (PowerShell)
# Output: $ArchOutputDir\01-architecture-intake.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:ARCH_AUTO = '1' }
if ($Answers) { $env:ARCH_ANSWERS = $Answers }


$OutputFile = Join-Path $script:ArchOutputDir "01-architecture-intake.md"
$Area       = "Architecture Intake"

$startTDebts = Get-Arch-TDebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-Arch-Banner "🏛   Step 1 of 6 — Architecture Intake"
Write-Arch-Dim "  Let's lock down the drivers that will shape every architecture decision."
Write-Arch-Dim "  Most answers are numbered choices or y/n. Skip with Enter if unsure."
Write-Host ""

# ── Handover from BA ─────────────────────────────────────────────────────────
$BAFinal = Join-Path $script:ArchBAInputDir "REQUIREMENTS-FINAL.md"
if (Test-Path $BAFinal) {
  Write-Host "  ✔ Found BA output: $BAFinal" -ForegroundColor Green
  Write-Arch-Dim "  The architect agent can read this for problem statement, NFRs, and open debts."
} else {
  Write-Host "  ⚠ No BA output found at: $BAFinal" -ForegroundColor Yellow
  Write-Arch-Dim "  For best results, run the business-analyst first. Continuing anyway..."
  Add-Arch-TDebt -Area $Area -Title "No BA requirements input found" `
    -Description "ba-output/REQUIREMENTS-FINAL.md was not present at intake time" `
    -Impact "Architecture decisions may lack traceability to requirements/NFRs"
}
Write-Host ""

# ── Q1: Top quality attribute ────────────────────────────────────────────────
Write-Host "Question 1 / 6 — Most important quality attribute" -ForegroundColor Cyan
Write-Arch-Dim "  Which one matters MOST for this system? (you can add more later)"
Write-Host ""
$TopQA = Ask-Arch-Choice "Select one:" @(
  "Performance — speed matters most (low latency, high throughput)",
  "Security — sensitive data, compliance, privacy-first",
  "Scalability — rapid growth expected, handle large spikes",
  "Availability — 24/7 uptime, high-stakes downtime cost",
  "Maintainability — small team, long-lived codebase",
  "Cost — strict budget, cost-sensitive",
  "Time-to-market — ship fast, refactor later",
  "Not sure yet"
)
if ($TopQA -eq "Not sure yet") {
  Add-Arch-TDebt -Area $Area -Title "Primary quality attribute not ranked" `
    -Description "Top quality-attribute driver has not been decided" `
    -Impact "ADR trade-offs cannot be judged without a priority ordering"
}

# ── Q2: Hard constraints ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 2 / 6 — Hard constraints" -ForegroundColor Cyan
Write-Arch-Dim "  Are there fixed rules the architecture MUST follow?"
Write-Arch-Dim "  Examples: 'must run on-prem', 'no GPL libraries', 'must be GDPR-compliant', 'only AWS approved'."
Write-Arch-Dim "  List all that apply, separated by semicolons. Press Enter if none."
Write-Host ""
$Constraints = Ask-Arch-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($Constraints)) {
  $Constraints = "None declared"
  Add-Arch-TDebt -Area $Area -Title "Hard constraints not declared" `
    -Description "No cloud/licence/residency/compliance constraints captured" `
    -Impact "Technology shortlist may include non-viable options"
}

# ── Q3: Team context ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 3 / 6 — Team context" -ForegroundColor Cyan
Write-Host ""
$TeamSize = Ask-Arch-Choice "How large is the engineering team that will build AND run this?" @(
  "Solo — 1 engineer",
  "Small — 2 to 5 engineers",
  "Medium — 6 to 15 engineers",
  "Large — more than 15 engineers"
)
$TeamSkills = Ask-Arch-Text "What is the team's strongest existing tech stack? (e.g. 'Python + PostgreSQL', '.NET + SQL Server', 'Node.js + React')"
if ([string]::IsNullOrWhiteSpace($TeamSkills)) {
  $TeamSkills = "Unknown"
  Add-Arch-TDebt -Area $Area -Title "Team skill set not captured" `
    -Description "Team's strongest stack is unknown" `
    -Impact "Risk of choosing a stack the team cannot operate"
}

# ── Q4: Operational envelope ─────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 4 / 6 — Operational envelope" -ForegroundColor Cyan
Write-Host ""
$UserLoad = Ask-Arch-Choice "Expected user load in year 1?" @(
  "Tiny — up to 100 users / 1 req/s",
  "Small — up to 1,000 users / 10 req/s",
  "Medium — up to 10,000 users / 100 req/s",
  "Large — up to 100,000 users / 1,000 req/s",
  "Very Large — 100,000+ users / 10,000+ req/s",
  "Unknown"
)
if ($UserLoad -eq "Unknown") {
  Add-Arch-TDebt -Area $Area -Title "User load not estimated" `
    -Description "Year-1 load is unknown" `
    -Impact "Capacity, sizing, and cost estimates are unreliable"
}

$DataVolume = Ask-Arch-Choice "Expected data volume by end of year 1?" @(
  "Small — under 10 GB",
  "Medium — 10 GB to 1 TB",
  "Large — 1 TB to 100 TB",
  "Very Large — over 100 TB",
  "Unknown"
)
if ($DataVolume -eq "Unknown") {
  Add-Arch-TDebt -Area $Area -Title "Data volume not estimated" `
    -Description "Year-1 data size is unknown" `
    -Impact "Storage tier and database choice cannot be finalised"
}

$SLA = Ask-Arch-Choice "What SLA (uptime) is required?" @(
  "Best-effort — no SLA (internal tool)",
  "Standard — 99.0% (about 7h downtime / month)",
  "High — 99.5% (about 3.5h / month)",
  "Very High — 99.9% (about 45 min / month)",
  "Extreme — 99.99% (about 4 min / month)",
  "Unknown"
)
if ($SLA -eq "Unknown") {
  Add-Arch-TDebt -Area $Area -Title "SLA target not defined" `
    -Description "Uptime target is unknown" `
    -Impact "Redundancy, multi-region, and failover decisions cannot be made"
}

$RtoRpo = Ask-Arch-Text "RTO (max recovery time after failure) and RPO (max acceptable data loss)? e.g. 'RTO 1h / RPO 15min' — Enter to skip"
if ([string]::IsNullOrWhiteSpace($RtoRpo)) {
  $RtoRpo = "TBD"
  Add-Arch-TDebt -Area $Area -Title "RTO/RPO not defined" `
    -Description "Disaster recovery targets are unknown" `
    -Impact "Backup strategy and DR topology cannot be designed"
}

# ── Q5: Integration surface ──────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 5 / 6 — Integration surface" -ForegroundColor Cyan
Write-Arch-Dim "  Which external systems must this talk to? (comma-separated list — Enter if none)"
Write-Arch-Dim "  Examples: 'Azure AD, Stripe, SAP, Twilio, BigQuery'"
Write-Host ""
$Integrations = Ask-Arch-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($Integrations)) { $Integrations = "None" }

# ── Q6: Deployment preference ────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 6 / 6 — Deployment preference" -ForegroundColor Cyan
Write-Host ""
$Deployment = Ask-Arch-Choice "Where should this system run?" @(
  "AWS",
  "Azure",
  "Google Cloud",
  "Multi-cloud",
  "On-prem / self-hosted",
  "Hybrid (cloud + on-prem)",
  "No strong preference"
)
if ($Deployment -eq "No strong preference") {
  Add-Arch-TDebt -Area $Area -Title "Deployment target undecided" `
    -Description "Cloud/on-prem choice is open" `
    -Impact "Hosting, networking, and managed-service ADRs cannot be finalised"
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Arch-SuccessRule "✅ Architecture Intake Summary"
Write-Host "  Top QA driver:        $TopQA"
Write-Host "  Constraints:          $Constraints"
Write-Host "  Team:                 $TeamSize — strongest stack: $TeamSkills"
Write-Host "  User load:            $UserLoad"
Write-Host "  Data volume:          $DataVolume"
Write-Host "  SLA:                  $SLA"
Write-Host "  RTO / RPO:            $RtoRpo"
Write-Host "  Integrations:         $Integrations"
Write-Host "  Deployment:           $Deployment"
Write-Host ""

if (-not (Confirm-Arch-Save "Does this look correct? (y=save / n=redo)")) {
  Write-Arch-Dim "  Restarting step 1..."
  & $PSCommandPath
  return
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$basisLine = if (Test-Path $BAFinal) { "> Requirements basis: ``$BAFinal``" } else { "> Requirements basis: **NOT PROVIDED** — see TDEBTs" }

$content = @"
# Architecture Intake

> Captured: $DateNow
$basisLine

## 1. Quality Attribute Drivers

- **Top driver:** $TopQA

## 2. Hard Constraints

$Constraints

## 3. Team Context

| Field | Value |
|---|---|
| Team size | $TeamSize |
| Strongest stack | $TeamSkills |

## 4. Operational Envelope

| Field | Value |
|---|---|
| Expected user load (Y1) | $UserLoad |
| Expected data volume (Y1) | $DataVolume |
| SLA target | $SLA |
| RTO / RPO | $RtoRpo |

## 5. Integration Surface

$Integrations

## 6. Deployment Preference

$Deployment

"@
$content | Set-Content -Path $OutputFile -Encoding UTF8

$endTDebts = Get-Arch-TDebtCount
$newTDebts = $endTDebts - $startTDebts

Write-Host ""
Write-Host "  Saved to: $OutputFile" -ForegroundColor Green
if ($newTDebts -gt 0) {
  Write-Host "  ⚠  $newTDebts technical debt(s) logged to: $script:ArchTDebtFile" -ForegroundColor Yellow
}
Write-Host ""
