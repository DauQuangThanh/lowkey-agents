# =============================================================================
# tracking.ps1 — Phase 2: Status Tracking & Reporting (PowerShell)
# Captures: reporting period, RAG status, accomplishments, activities,
# blockers/issues, and budget status.
# Output: pm-output/02-status-report.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:PM_AUTO = '1' }
if ($Answers) { $env:PM_ANSWERS = $Answers }


Write-PM-Banner "Phase 2: Status Tracking & Reporting"

# Question 1: Reporting Period
$period = Ask-PM-Choice `
  "What is your reporting period?" `
  @("Weekly", "Bi-weekly", "Monthly", "Per-milestone")
Write-PM-Dim "Reporting period: $period"

# Question 2: RAG Status
$ragStatus = Ask-PM-Choice `
  "What is the overall project RAG status?" `
  @("🟢 GREEN (On track)", "🟡 AMBER (At risk)", "🔴 RED (Off track)")
Write-PM-Dim "Status: $ragStatus"

# Question 3: Key Accomplishments
Write-Host ""
Write-PMColor "▶ List key accomplishments this period." $script:PMYellow
Write-Host ""
Write-PM-Dim "   (Examples: Completed design review, Deployed to staging, Fixed critical bugs)"
Write-PM-Dim "   When done, press Enter with empty input."
Write-Host ""

$accomplishments = @()
while ($true) {
  $item = Ask-PM-Text "Add accomplishment (or press Enter to finish)"
  if ([string]::IsNullOrWhiteSpace($item)) { break }
  $accomplishments += $item
  Write-PM-Dim "Added: $item"
}

if ($accomplishments.Count -eq 0) {
  Write-PM-Dim "No accomplishments recorded — logging as debt."
  Add-PM-Debt "Tracking" "No accomplishments recorded" "No progress documented this period" "Cannot track momentum or communicate success"
  $accomplishments = @("(None documented)")
}

# Question 4: Planned Activities
Write-Host ""
Write-PMColor "▶ List planned activities for the next period." $script:PMYellow
Write-Host ""
Write-PM-Dim "   (Examples: Start development, User acceptance testing, Deploy to production)"
Write-PM-Dim "   When done, press Enter with empty input."
Write-Host ""

$activities = @()
while ($true) {
  $item = Ask-PM-Text "Add planned activity (or press Enter to finish)"
  if ([string]::IsNullOrWhiteSpace($item)) { break }
  $activities += $item
  Write-PM-Dim "Added: $item"
}

if ($activities.Count -eq 0) {
  Write-PM-Dim "No planned activities defined — logging as debt."
  Add-PM-Debt "Tracking" "No planned activities" "Next period activities are undefined" "Cannot manage expectations or dependencies"
  $activities = @("(TBD)")
}

# Question 5: Blockers & Issues
Write-Host ""
Write-PMColor "▶ Identify any blockers or issues preventing progress." $script:PMYellow
Write-Host ""
Write-PM-Dim "   (Format: Issue description | Owner | Target resolution date)"
Write-PM-Dim "   When done, press Enter with empty input."
Write-Host ""

$blockers = @()
while ($true) {
  $item = Ask-PM-Text "Add blocker/issue (or press Enter to finish)"
  if ([string]::IsNullOrWhiteSpace($item)) { break }
  $blockers += $item
  Write-PM-Dim "Added: $item"
}

if ($blockers.Count -eq 0) {
  Write-PM-Dim "No blockers identified."
}

# Question 6: Budget Status
Write-Host ""
Write-PMColor "▶ What is the current budget status?" $script:PMYellow
Write-Host ""
$budgetStatus = Ask-PM-Choice `
  "Budget status:" `
  @("On track", "Over budget", "Under budget", "Not tracking budget")
Write-PM-Dim "Budget: $budgetStatus"

$budgetVariance = ""
if ($budgetStatus -ne "Not tracking budget") {
  $budgetVariance = Ask-PM-Text "What is the budget variance? (e.g., +5%, -10%, or `$5000 under)"
  Write-PM-Dim "Variance: $budgetVariance"
}

# Confirmation
Write-Host ""
$saveConfirm = Confirm-PM-Save "Save this status report?"
if (-not $saveConfirm) {
  Write-PM-Dim "Report discarded. Exiting."
  exit 0
}

# Write Output
$outputFile = Join-Path $script:PMOutputDir "02-status-report.md"

$statusIndicator = "🟢 GREEN"
if ($ragStatus -like "*AMBER*") { $statusIndicator = "🟡 AMBER" }
if ($ragStatus -like "*RED*") { $statusIndicator = "🔴 RED" }

$outputContent = @"
# Status Report

**Period:** $(Get-Date -Format 'dd/MM/yyyy')
**Reporting Cadence:** $period

## Overall Status
**RAG: $statusIndicator**

[One paragraph covering overall health — to be completed by project manager]

## Key Accomplishments This Period
$($accomplishments | ForEach-Object { "1. $_" } | Out-String)
## Planned Activities Next Period
$($activities | ForEach-Object { "1. $_" } | Out-String)
## Budget Status
**Status:** $budgetStatus
$(if ($budgetVariance) { "**Variance:** $budgetVariance`n" })

## Blockers & Issues
$(if ($blockers.Count -gt 0) {
  "### Active Issues`n"
  $blockers | ForEach-Object { "- $_" }
} else {
  "- None at this time"
})

## Risks Escalated This Period
- [Add any newly escalated risks]

## Next Steps & Decisions Required
1. [Decision needed]: Owner [Name], due [Date]
2. [Approval needed]: Owner [Name], due [Date]
"@

Set-Content -Path $outputFile -Value $outputContent

Write-PM-SuccessRule "Status report written to $outputFile"
Write-Host ""

# Final Summary
Write-PM-Dim "Summary:"
Write-PM-Dim "  Reporting Period: $period"
Write-PM-Dim "  RAG Status: $statusIndicator"
Write-PM-Dim "  Accomplishments: $($accomplishments.Count) items"
Write-PM-Dim "  Planned Activities: $($activities.Count) items"
Write-PM-Dim "  Budget Status: $budgetStatus"
if ($blockers.Count -gt 0) {
  Write-PM-Dim "  Blockers: $($blockers.Count) identified"
}

$debtCount = Get-PM-DebtCount
if ($debtCount -gt 0) {
  Write-Host ""
  Write-Host "⚠ $debtCount open PM debt(s) to resolve — see $script:PMDebtFile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✓ Phase 2 complete." -ForegroundColor Green
Write-Host ""
