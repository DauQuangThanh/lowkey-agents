# =============================================================================
# risk.ps1 — Phase 3: Risk Management (PowerShell)
# Captures risks with likelihood, impact, mitigation, contingency, owner, category.
# Computes risk scores and generates a risk register.
# Output: pm-output/03-risk-register.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:PM_AUTO = '1' }
if ($Answers) { $env:PM_ANSWERS = $Answers }


Write-PM-Banner "Phase 3: Risk Management"

$risks = @()
$riskCount = 0

# Loop: Add risks one at a time
while ($true) {
  Write-Host ""
  Write-PMColor "▶ Add a risk (or press Enter to finish)." $script:PMYellow
  Write-Host ""
  $riskDesc = Ask-PM-Text "Risk description (what could go wrong?)"
  if ([string]::IsNullOrWhiteSpace($riskDesc)) { break }

  $likelihood = Ask-PM-Choice `
    "How likely is this risk?" `
    @("1 - Rare (< 10%)", "2 - Unlikely (10-30%)", "3 - Possible (30-50%)", "4 - Likely (50-75%)", "5 - Almost certain (> 75%)")
  $likelihoodNum = $likelihood[0]
  Write-PM-Dim "Likelihood: $likelihood"

  $impact = Ask-PM-Choice `
    "What is the impact if this risk occurs?" `
    @("1 - Negligible (minor inconvenience)", "2 - Minor (small delay or cost)", "3 - Moderate (noticeable effect)", "4 - Major (significant impact)", "5 - Critical (project-threatening)")
  $impactNum = $impact[0]
  Write-PM-Dim "Impact: $impact"

  $score = [int]$likelihoodNum * [int]$impactNum
  $severity = if ($score -ge 15) { "🔴 RED" } elseif ($score -ge 8) { "🟡 AMBER" } else { "🟢 GREEN" }
  Write-PM-Dim "Score: $score ($severity)"

  $category = Ask-PM-Choice `
    "Risk category:" `
    @("Technical", "Schedule", "Resource", "Budget", "Scope", "External", "Other")
  Write-PM-Dim "Category: $category"

  $mitigation = Ask-PM-Text "Mitigation strategy (what will you do to prevent/reduce this risk?)"
  Write-PM-Dim "Mitigation: $mitigation"

  $contingency = Ask-PM-Text "Contingency plan (what if the risk occurs anyway?)"
  Write-PM-Dim "Contingency: $contingency"

  $owner = Ask-PM-Text "Who owns this risk? (name/role)"
  Write-PM-Dim "Owner: $owner"

  $riskCount++
  $riskId = "RISK-{0:D2}" -f $riskCount
  $riskEntry = @{
    Id = $riskId
    Description = $riskDesc
    Likelihood = $likelihoodNum
    Impact = $impactNum
    Score = $score
    Severity = $severity
    Category = $category
    Mitigation = $mitigation
    Contingency = $contingency
    Owner = $owner
  }
  $risks += $riskEntry

  Write-Host ""
  $continue = Ask-PM-YN "Add another risk?"
  if ($continue -eq "no") { break }
}

if ($riskCount -eq 0) {
  Write-PM-Dim "No risks identified."
  Add-PM-Debt "Risk" "No risks identified" "No project risks were documented" "Cannot manage or mitigate emerging issues"
}

# Confirmation
Write-Host ""
$saveConfirm = Confirm-PM-Save "Save this risk register?"
if (-not $saveConfirm) {
  Write-PM-Dim "Risk register discarded. Exiting."
  exit 0
}

# Write Output
$outputFile = Join-Path $script:PMOutputDir "03-risk-register.md"

$redCount = ($risks | Where-Object { $_.Severity -eq "🔴 RED" } | Measure-Object).Count
$amberCount = ($risks | Where-Object { $_.Severity -eq "🟡 AMBER" } | Measure-Object).Count
$greenCount = ($risks | Where-Object { $_.Severity -eq "🟢 GREEN" } | Measure-Object).Count

$risksContent = ""
if ($riskCount -gt 0) {
  $risksContent = $risks | ForEach-Object {
    @"
### $($_.Id): $($_.Description)
**Severity:** $($_.Severity)
**Likelihood:** $($_.Likelihood) | **Impact:** $($_.Impact) | **Score:** $($_.Score)
**Category:** $($_.Category)
**Mitigation Strategy:** $($_.Mitigation)
**Contingency Plan:** $($_.Contingency)
**Owner:** $($_.Owner)
**Status:** Active

"@
  } | Out-String
}

$mitigationTable = ""
if ($riskCount -gt 0) {
  $mitigationTable = $risks | ForEach-Object {
    "| $($_.Id) | $($_.Mitigation) | $($_.Owner) | TBD |"
  } | Out-String
}

$outputContent = @"
# Risk Register

**Date:** $(Get-Date -Format 'dd/MM/yyyy')
**Total Risks:** $riskCount

## Risk Matrix Scoring
- **Score = Likelihood × Impact**
- **15+:** 🔴 RED (must mitigate immediately)
- **8-14:** 🟡 AMBER (plan mitigation)
- **5-7:** 🟢 GREEN (monitor)

## Risk Summary
| Severity | Count |
|---|---|
| 🔴 RED | $redCount |
| 🟡 AMBER | $amberCount |
| 🟢 GREEN | $greenCount |

## Risks

$risksContent

## Mitigation Actions
| Risk | Mitigation | Owner | Target Date |
|---|---|---|---|
$mitigationTable
"@

Set-Content -Path $outputFile -Value $outputContent

Write-PM-SuccessRule "Risk register written to $outputFile"
Write-Host ""

# Final Summary
Write-PM-Dim "Summary:"
Write-PM-Dim "  Total Risks: $riskCount"
if ($riskCount -gt 0) {
  Write-PM-Dim "  Red (15+): $redCount"
  Write-PM-Dim "  Amber (8-14): $amberCount"
  Write-PM-Dim "  Green (5-7): $greenCount"
}

$debtCount = Get-PM-DebtCount
if ($debtCount -gt 0) {
  Write-Host ""
  Write-Host "⚠ $debtCount open PM debt(s) to resolve — see $script:PMDebtFile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✓ Phase 3 complete." -ForegroundColor Green
Write-Host ""
