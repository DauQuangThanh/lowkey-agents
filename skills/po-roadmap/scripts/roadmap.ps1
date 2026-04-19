# =============================================================================
# roadmap.ps1 — Phase 3: Product Roadmap Planning (PowerShell)
# Output: $POOutputDir\03-product-roadmap.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ScriptDir = $PSScriptRoot
. (Join-Path $ScriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:PO_AUTO = '1' }
if ($Answers) { $env:PO_ANSWERS = $Answers }


$OutputFile = Join-Path $script:POOutputDir "03-product-roadmap.md"
$Area       = "Product Roadmap"

$startDebts = Get-PO-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-PO-Banner "🗺   Phase 3 — Product Roadmap"
Write-PO-Dim "  Let's plan when features ship and communicate product direction."
Write-Host ""

# ── Q1: Roadmap horizon ───────────────────────────────────────────────────────
Write-Host "Question 1 / 6 — Roadmap Horizon" -ForegroundColor Cyan
Write-PO-Dim "  How far ahead should we plan?"
Write-Host ""
$Horizon = Ask-PO-Choice "Select roadmap horizon:" @(
  "1 Quarter (3 months)",
  "2 Quarters (6 months)",
  "1 Year (12 months)",
  "18 Months",
  "Custom (you'll specify)"
)

if ($Horizon -eq "Custom (you'll specify)") {
  $Horizon = Ask-PO-Text "Enter custom horizon (e.g. '9 months', '2 years'):"
}

# ── Q2: Release cadence ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 2 / 6 — Release Cadence" -ForegroundColor Cyan
Write-PO-Dim "  How often do you release new versions?"
Write-Host ""
$Cadence = Ask-PO-Choice "Release frequency:" @(
  "Weekly",
  "Bi-weekly (every 2 weeks)",
  "Monthly",
  "Quarterly",
  "Custom (you'll specify)"
)

if ($Cadence -eq "Custom (you'll specify)") {
  $Cadence = Ask-PO-Text "Enter custom cadence (e.g. 'every 2 weeks', '3 times per quarter'):"
}

# ── Q3: Release themes and periods ────────────────────────────────────────────
Write-Host ""
Write-Host "Question 3 / 6 — Release Themes & Goals" -ForegroundColor Cyan
Write-PO-Dim "  Define what each release or period focuses on."
Write-Host ""

$ReleaseNames   = @()
$ReleaseDates   = @()
$ReleaseThemes  = @()
$ReleaseGoals   = @()

$releaseCount = 0

while ($true) {
  $releaseNum = $releaseCount + 1
  $response = Read-Host "▶ Add release #$releaseNum`? (y/n)"
  if ($response -notin "y", "yes") {
    break
  }

  $Name = Ask-PO-Text "Release name (e.g. 'v1.0', 'Spring 2026', 'MVP'):"
  if ([string]::IsNullOrWhiteSpace($Name)) { $Name = "Release $($releaseCount + 1)" }
  $ReleaseNames += $Name

  $Date = Ask-PO-Text "Planned date (e.g. 'End of March 2026', 'Q2 2026'):"
  if ([string]::IsNullOrWhiteSpace($Date)) { $Date = "TBD" }
  $ReleaseDates += $Date

  $Theme = Ask-PO-Text "Release theme (main focus):"
  if ([string]::IsNullOrWhiteSpace($Theme)) { $Theme = "No theme defined" }
  $ReleaseThemes += $Theme

  $Goals = Ask-PO-Text "Key goals/highlights (comma-separated):"
  if ([string]::IsNullOrWhiteSpace($Goals)) { $Goals = "TBD" }
  $ReleaseGoals += $Goals

  $releaseCount++
}

if ($releaseCount -eq 0) {
  Add-PO-Debt -Area $Area -Title "No releases defined" `
    -Description "Roadmap has no release periods" `
    -Impact "Stakeholder communication, team planning"
}

# ── Q4: Key milestones ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 4 / 6 — Key Milestones" -ForegroundColor Cyan
Write-PO-Dim "  Major dates, events, or deliverables beyond releases."
Write-PO-Dim "  Example: 'Beta launch - June 2026', 'GA release - Q3 2026'"
Write-Host ""
$Milestones = Ask-PO-Text "Your answer (comma-separated, or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($Milestones)) { $Milestones = "Not yet defined" }

# ── Q5: External dependencies ─────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 5 / 6 — External Dependencies" -ForegroundColor Cyan
Write-PO-Dim "  Dependencies on other teams, vendors, or events."
Write-PO-Dim "  Example: 'Waiting for vendor API - May 2026'"
Write-Host ""
$Dependencies = Ask-PO-Text "Your answer (or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($Dependencies)) { $Dependencies = "None identified" }

# ── Q6: Success metrics ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "Question 6 / 6 — Success Metrics per Release" -ForegroundColor Cyan
Write-PO-Dim "  How will you measure success for each release?"
Write-PO-Dim "  Example: 'User adoption > 1000', 'Page load < 200ms'"
Write-Host ""
$Metrics = Ask-PO-Text "Your answer (or press Enter to skip):"
if ([string]::IsNullOrWhiteSpace($Metrics)) { $Metrics = "Not yet defined" }

# ── Summary ───────────────────────────────────────────────────────────────────
Write-PO-SuccessRule "✅ Roadmap Summary"
Write-Host "  Horizon:        $Horizon"
Write-Host "  Cadence:        $Cadence"
Write-Host "  Releases:       $releaseCount releases"
Write-Host "  Milestones:     $($Milestones.Substring(0, [Math]::Min(40, $Milestones.Length)))..."
Write-Host ""

if (-not (Confirm-PO-Save "Does this look correct? (y=save / n=redo)")) {
  Write-PO-Dim "  Restarting phase 3..."
  & $PSCommandPath
  exit
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$output = @"
# Product Roadmap

> Captured: $DateNow

## Roadmap Overview

**Horizon:** $Horizon

**Release Cadence:** $Cadence

## Release Schedule

"@

if ($releaseCount -gt 0) {
  $output += "| Release | Planned Date | Theme | Goals |`n"
  $output += "|---------|--------------|-------|-------|`n"
  for ($i = 0; $i -lt $releaseCount; $i++) {
    $goalsShort = $ReleaseGoals[$i].Substring(0, [Math]::Min(30, $ReleaseGoals[$i].Length))
    $output += "| $($ReleaseNames[$i]) | $($ReleaseDates[$i]) | $($ReleaseThemes[$i]) | $goalsShort... |`n"
  }
  $output += "`n### Release Details`n`n"
  for ($i = 0; $i -lt $releaseCount; $i++) {
    $output += @"
#### $($ReleaseNames[$i])

**Planned Date:** $($ReleaseDates[$i])

**Theme:** $($ReleaseThemes[$i])

**Goals:**

"@
    $goalItems = $ReleaseGoals[$i] -split ', '
    foreach ($goal in $goalItems) {
      $output += "- $goal`n"
    }
    $output += "`n"
  }
} else {
  $output += "(No releases defined)`n`n"
}

$output += @"
## Key Milestones

$Milestones

## External Dependencies

$Dependencies

## Success Metrics

$Metrics

"@

Set-Content -Path $OutputFile -Value $output -Encoding UTF8

Write-PO-SuccessRule "✅ Product Roadmap saved"
Write-Host "  Output: $OutputFile" -ForegroundColor Green
Write-Host ""

# ── Log new debts ─────────────────────────────────────────────────────────────
$endDebts = Get-PO-DebtCount
if ($endDebts -gt $startDebts) {
  $newDebts = $endDebts - $startDebts
  Write-PO-Dim "  Logged $newDebts debt(s) — see po-output/06-po-debts.md"
}
Write-Host ""
