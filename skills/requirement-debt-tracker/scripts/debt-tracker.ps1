# =============================================================================
# debt-tracker.ps1 — Phase 6: Requirement Debt Tracker (PowerShell)
# Reviews all debts collected during the session, assigns owners, and captures
# any new manual debts.
# Output: $BAOutputDir\06-requirement-debts.md (enriches existing file)
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:BA_AUTO = '1' }
if ($Answers) { $env:BA_ANSWERS = $Answers }


$Area = "Requirement Debt Tracker"

# ── Header ────────────────────────────────────────────────────────────────────
Write-BA-Banner "🔍  Step 6 of 7 — Requirement Debt Review"
Write-BA-Dim "  A 'Requirement Debt' is anything that is unknown, unclear, or unconfirmed"
Write-BA-Dim "  that MUST be resolved before or during development."
Write-Host ""

# ── Show existing debts ───────────────────────────────────────────────────────
$ExistingCount = Get-BA-DebtCount

if ($ExistingCount -gt 0) {
  Write-Host ("  ⚠  Found {0} requirement debt(s) from earlier steps:" -f $ExistingCount) -ForegroundColor Yellow
  Write-Host ""
  if (Test-Path $script:BADebtFile) {
    $lines = Get-Content $script:BADebtFile -Encoding UTF8
    foreach ($line in $lines) {
      if ($line -match '^## DEBT-')         { Write-Host ("  🔴  " + ($line -replace '^## ', ''))               -ForegroundColor Red }
      elseif ($line -match '^\*\*Area:\*\* ')        { Write-Host ("     📂 Area: " + ($line -replace '^\*\*Area:\*\* ', '')) }
      elseif ($line -match '^\*\*Description:\*\* ') { Write-Host ("     📝 "      + ($line -replace '^\*\*Description:\*\* ', '')) }
      elseif ($line -match '^\*\*Priority:\*\* ')    { Write-Host ("     🚦 Priority: " + ($line -replace '^\*\*Priority:\*\* ', '')) }
    }
  }
  Write-Host ""
  Write-BA-Dim "  These will be included in your final requirements document."
} else {
  Write-Host "  ✅ No requirement debts were logged in earlier steps!" -ForegroundColor Green
  Write-Host ""
}

# ── Update owners for existing debts ──────────────────────────────────────────
if ($ExistingCount -gt 0) {
  Write-Host ""
  Write-Host "── Assigning Owners ──" -ForegroundColor Cyan
  Write-BA-Dim "  For each debt, who is the best person to resolve it?"
  Write-BA-Dim "  We'll add a general owner for now — you can update per-item later."
  Write-Host ""
  $defaultOwner = Ask-BA-Text "  Who is the primary person responsible for answering open questions? (name or role, e.g. 'Product Owner', 'Thanh')"
  if ([string]::IsNullOrWhiteSpace($defaultOwner)) { $defaultOwner = "Product Owner" }

  # Cross-platform replace: read, transform, rewrite.
  if (Test-Path $script:BADebtFile) {
    $content = Get-Content $script:BADebtFile -Raw -Encoding UTF8
    $content = $content -replace '\*\*Owner:\*\* TBD', ("**Owner:** " + $defaultOwner)
    Set-Content -Path $script:BADebtFile -Value $content -Encoding UTF8 -NoNewline
  }
  Write-Host ("  ✅ Owner set to `"$defaultOwner`" for all open debts.") -ForegroundColor Green
}

# ── Add new debts ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "── Adding New Debts ──" -ForegroundColor Cyan
Write-BA-Dim "  Are there any other open questions, unknowns, or risks you know about"
Write-BA-Dim "  that haven't been captured yet?"
Write-Host ""
Write-BA-Dim "  Common areas to check:"
Write-BA-Dim "  • Business rules that are vague or assumed"
Write-BA-Dim "  • Stakeholders who haven't been consulted yet"
Write-BA-Dim "  • Technical dependencies not yet confirmed"
Write-BA-Dim "  • Legal or compliance questions"
Write-BA-Dim "  • Budget or resource constraints not yet finalised"
Write-Host ""

function Add-ManualDebt {
  $currentCount = Get-BA-DebtCount
  $newId = "{0:D2}" -f ($currentCount + 1)

  Write-Host ""
  Write-Host ("  New Debt #{0}" -f $newId) -ForegroundColor Cyan

  $title = Ask-BA-Text "  Briefly describe what is unknown or unclear:"
  if ([string]::IsNullOrWhiteSpace($title)) { $title = "Unknown item" }

  $area = Ask-BA-Choice "  Which area does this relate to?" @(
    "Project scope / goals",
    "Stakeholders / decision making",
    "Functional requirements",
    "Non-functional requirements",
    "Integrations / external systems",
    "Legal / compliance",
    "Technical / infrastructure",
    "Other"
  )

  $impact = Ask-BA-Text "  What is the impact if this is NOT resolved? (one sentence):"
  if ([string]::IsNullOrWhiteSpace($impact)) { $impact = "Unknown impact — needs assessment" }

  $owner = Ask-BA-Text "  Who should resolve this? (name or role):"
  if ([string]::IsNullOrWhiteSpace($owner)) { $owner = "Product Owner" }

  $priority = Ask-BA-Choice "  How urgent is this?" @(
    "🔴 Blocking — Must resolve before development starts",
    "🟡 Important — Resolve in first sprint/phase",
    "🟢 Can Wait — Resolve before feature is built"
  )

  $dueDate = Ask-BA-Text "  Target resolution date? (e.g. 30 Jun 2026, or press Enter for TBD):"
  if ([string]::IsNullOrWhiteSpace($dueDate)) { $dueDate = "TBD" }

  $entry = @"

## DEBT-${newId}: $title
**Area:** $area
**Description:** $title
**Impact:** $impact
**Owner:** $owner
**Priority:** $priority
**Target Date:** $dueDate
**Status:** Open

"@
  Add-Content -Path $script:BADebtFile -Value $entry -Encoding UTF8

  Write-Host ("  ✅ Debt DEBT-{0} logged." -f $newId) -ForegroundColor Green
}

$addMore = Ask-BA-YN "Do you want to add a new requirement debt?"
while ($addMore -eq "yes") {
  Add-ManualDebt
  Write-Host ""
  $addMore = Ask-BA-YN "Add another debt?"
}

# ── Debt priority summary ─────────────────────────────────────────────────────
Write-Host ""
$FinalCount     = Get-BA-DebtCount
$BlockingCount  = 0
$ImportantCount = 0
$WaitCount      = 0

if (Test-Path $script:BADebtFile) {
  $content = Get-Content $script:BADebtFile -Raw -Encoding UTF8
  $BlockingCount  = ([regex]::Matches($content, 'Blocking')).Count
  $ImportantCount = ([regex]::Matches($content, 'Important')).Count
  $WaitCount      = ([regex]::Matches($content, 'Can Wait')).Count
}

Write-BA-SuccessRule "✅ Requirement Debt Register Summary"
Write-Host ("  Total debts:     {0}" -f $FinalCount)
Write-Host ("  🔴 Blocking:     {0} — must resolve before development" -f $BlockingCount)
Write-Host ("  🟡 Important:    {0} — resolve in first sprint" -f $ImportantCount)
Write-Host ("  🟢 Can Wait:     {0} — resolve before feature is built" -f $WaitCount)
Write-Host ""

if ($BlockingCount -gt 0) {
  Write-Host ("  ⚠  WARNING: You have {0} blocking debt(s)." -f $BlockingCount) -ForegroundColor Red
  Write-Host "     These must be resolved before development can begin." -ForegroundColor Red
  Write-Host ""
}

# ── Add header to debt file if it doesn't have one ───────────────────────────
if (Test-Path $script:BADebtFile) {
  $content = Get-Content $script:BADebtFile -Raw -Encoding UTF8
  if ($content -notmatch '^# Requirement Debt Register') {
    $DateNow = Get-Date -Format "yyyy-MM-dd"
    $header = @"
# Requirement Debt Register

> Last updated: $DateNow

A requirement debt is any unknown, unclear, or unconfirmed piece of information
needed to properly define, build, or test the system.

| Priority | Meaning |
|---|---|
| 🔴 Blocking | Must resolve before development starts |
| 🟡 Important | Must resolve before the related feature is built |
| 🟢 Can Wait | Should resolve before the related story is accepted |

---

"@
    Set-Content -Path $script:BADebtFile -Value ($header + $content) -Encoding UTF8 -NoNewline
  }
}

Write-Host ("  Debt register saved to: {0}" -f $script:BADebtFile) -ForegroundColor Green
Write-Host ""
