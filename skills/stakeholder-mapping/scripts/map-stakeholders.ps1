# =============================================================================
# map-stakeholders.ps1 — Phase 2: Stakeholder Mapping (PowerShell)
# Output: $BAOutputDir\02-stakeholders.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:BA_AUTO = '1' }
if ($Answers) { $env:BA_ANSWERS = $Answers }


$OutputFile = Join-Path $script:BAOutputDir "02-stakeholders.md"
$Area       = "Stakeholder Mapping"

$startDebts = Get-BA-DebtCount

$script:StakeCount   = 0
$script:Stakeholders = @()

function Capture-Stakeholder {
  param([string]$Type)
  $script:StakeCount++
  Write-Host ""
  Write-Host "  ── $Type ──" -ForegroundColor Cyan

  $name = Ask-BA-Text "  What is their role or title? (e.g. 'Sales Manager', 'End Customer')"
  if ([string]::IsNullOrWhiteSpace($name)) {
    $name = "TBD"
    Add-BA-Debt -Area $Area -Title "Stakeholder role name missing" `
      -Description "A $Type stakeholder was identified but not named" `
      -Impact "Requirements may not reflect their needs"
  }

  Write-Host ""
  $tech = Ask-BA-Choice "  How technical are they?" @(
    "Not technical at all",
    "Some technical knowledge",
    "Very technical / developer"
  )

  Write-Host ""
  Write-BA-Dim "  What is the ONE thing they most need from this system?"
  $need = Ask-BA-Text "  (e.g. 'See all customer orders in one place')"
  if ([string]::IsNullOrWhiteSpace($need)) {
    $need = "TBD"
    Add-BA-Debt -Area $Area -Title "Key need for $name not captured" `
      -Description "Stakeholder '$name' has no documented primary need" `
      -Impact "Requirements may miss critical features for this group"
  }

  $script:Stakeholders += "| **$Type** | $name | $tech | $need |"
}

# ── Header ────────────────────────────────────────────────────────────────────
Write-BA-Banner "👥  Step 2 of 7 — Stakeholder Mapping"
Write-BA-Dim "  A stakeholder is anyone who uses or is affected by this system."
Write-BA-Dim "  We'll go through each type. Answer y/n to whether they exist."
Write-Host ""

# ── Primary users ─────────────────────────────────────────────────────────────
Write-Host "Primary Users" -ForegroundColor Cyan
Write-BA-Dim "  These are the people who will use the system every day."
$hasPrimary = Ask-BA-YN "Does your system have primary daily users?"
if ($hasPrimary -eq "yes") {
  Write-BA-Dim "  How many different types of primary user are there?"
  $numPrimaryChoice = Ask-BA-Choice "Select:" @("1", "2", "3", "4 or more (I'll add them one by one)")
  if ($numPrimaryChoice -eq "4 or more (I'll add them one by one)") {
    $numPrimary = 4
  } else {
    $numPrimary = [int]$numPrimaryChoice
  }
  for ($i = 1; $i -le $numPrimary; $i++) {
    Write-BA-Dim "  Primary user $i of $numPrimary:"
    Capture-Stakeholder "Primary User"
  }
} else {
  Add-BA-Debt -Area $Area -Title "No primary users identified" `
    -Description "No primary daily users were identified" `
    -Impact "Cannot write user stories without knowing who uses the system"
}

# ── Secondary users ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Secondary Users" -ForegroundColor Cyan
Write-BA-Dim "  People who use the system occasionally or consume its reports/exports."
$hasSecondary = Ask-BA-YN "Are there secondary or occasional users?"
if ($hasSecondary -eq "yes") {
  Capture-Stakeholder "Secondary User"
  while ((Ask-BA-YN "  Add another secondary user?") -eq "yes") {
    Capture-Stakeholder "Secondary User"
  }
}

# ── Decision makers ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Decision Makers" -ForegroundColor Cyan
Write-BA-Dim "  Who approves the requirements and signs off on the project?"
$hasDecision = Ask-BA-YN "Is there a decision maker or sponsor for this project?"
if ($hasDecision -eq "yes") {
  Capture-Stakeholder "Decision Maker / Sponsor"
} else {
  Add-BA-Debt -Area $Area -Title "No decision maker identified" `
    -Description "No one has been named as project owner or sponsor" `
    -Impact "Requirements changes and scope decisions will have no authority"
}

# ── External parties ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "External Parties" -ForegroundColor Cyan
Write-BA-Dim "  Third-party vendors, regulators, partner systems, or customers."
$hasExternal = Ask-BA-YN "Are there any external organisations or systems this project interacts with?"
if ($hasExternal -eq "yes") {
  Capture-Stakeholder "External Party"
  while ((Ask-BA-YN "  Add another external party?") -eq "yes") {
    Capture-Stakeholder "External Party"
  }
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-BA-SuccessRule ("✅ Stakeholder Summary ({0} stakeholders identified)" -f $script:StakeCount)
foreach ($s in $script:Stakeholders) { Write-Host "  $s" }
Write-Host ""

if (-not (Confirm-BA-Save "Does this look right? (y=save / n=redo)")) {
  & $PSCommandPath
  return
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$lines  = @()
$lines += "# Stakeholder Map"
$lines += ""
$lines += "> Captured: $DateNow"
$lines += ""
$lines += "## Identified Stakeholders"
$lines += ""
$lines += "| Type | Role / Title | Technical Level | Primary Need |"
$lines += "|---|---|---|---|"
foreach ($s in $script:Stakeholders) { $lines += $s }
$lines += ""
$lines += "## Notes"
$lines += ""
$lines += "Total stakeholders identified: $($script:StakeCount)"
$lines += ""
$lines | Set-Content -Path $OutputFile -Encoding UTF8

$endDebts = Get-BA-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host "  Saved to: $OutputFile" -ForegroundColor Green
if ($newDebts -gt 0) { Write-Host "  ⚠  $newDebts debt(s) logged." -ForegroundColor Yellow }
Write-Host ""
