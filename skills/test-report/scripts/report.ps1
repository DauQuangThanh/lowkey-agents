# =============================================================================
# report.ps1 — Phase 4: Test Summary Report & Validation (PowerShell 5.1+)
# Analyzes test coverage, metrics, open defects, and generates release
# recommendation. Produces detailed report + executive summary.
# Output: $env:TEST_OUTPUT_DIR\04-test-report.md + TESTER-FINAL.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:TEST_AUTO = '1' }
if ($Answers) { $env:TEST_ANSWERS = $Answers }


$OutputFile = "$script:TSTOutputDir\04-test-report.md"
$FinalFile = "$script:TSTOutputDir\TESTER-FINAL.md"
$Area = "Test Report"

$startDebts = Get-TST-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-TST-Banner "📊  Step 4 of 4 — Test Summary Report"
Write-TST-Dim "  Let's create a final test summary and release recommendation."
Write-Host ""

# ── Q1: Coverage percentage ───────────────────────────────────────────────────
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 1 / 2 — Test Coverage$($script:TSTNc)"
Write-TST-Dim "  What percentage of requirements were tested?"
Write-TST-Dim "  (Target: 95%+ for critical, 80%+ for others)"
Write-Host ""
$Coverage = Ask-TST-Text "Coverage %:"
if ([string]::IsNullOrWhiteSpace($Coverage)) {
  $Coverage = "TBD"
  Add-TST-Debt -Area $Area -Title "Coverage percentage not recorded" `
    -Description "Test coverage percentage not documented" `
    -Impact "Release readiness assessment"
}

# ── Q2: Release recommendation ────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 2 / 2 — Release Readiness$($script:TSTNc)"
Write-TST-Dim "  Can we release this software to production?"
Write-Host ""
$ReleaseReady = Ask-TST-Choice "Select one:" @(
  "YES — Ready to release",
  "CONDITIONAL — Ready if P0/P1 bugs fixed",
  "NO — Not ready (blockers remain)"
)

# ── Summary ───────────────────────────────────────────────────────────────────
Write-TST-SuccessRule "✅ Test Report Summary"
Write-Host "  $($script:TSTBold)Coverage:$($script:TSTNc)          $Coverage"
Write-Host "  $($script:TSTBold)Release Status:$($script:TSTNc)    $ReleaseReady"
Write-Host ""

if (-not (Confirm-TST-Save "Does this look correct? (y=save / n=redo)")) {
  Write-TST-Dim "  Restarting step 4..."
  & pwsh $MyInvocation.MyCommand.Path
  exit
}

# ── Write detailed report ─────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$DetailedReport = @"
# Test Summary Report

> Report Date: $DateNow

## Executive Summary

**Overall Test Result:** $ReleaseReady
**Coverage:** $Coverage

## Test Metrics

### Coverage

- Functional Requirements tested: [Add from execution report]
- Non-Functional Requirements tested: [Add from execution report]
- Overall coverage: $Coverage

### Test Results

| Status | Count | % |
|---|---|---|
| Passed | [Add count] | [Add %] |
| Failed | [Add count] | [Add %] |
| Blocked | [Add count] | [Add %] |

### Defects

| Severity | Count | Status |
|---|---|---|
| Critical | [Add count] | [Add status] |
| High | [Add count] | [Add status] |
| Medium | [Add count] | [Add status] |
| Low | [Add count] | [Add status] |

## Open Issues

### Critical Blockers

[List P0 bugs and blockers, if any]

### Blocked Tests

[List blocked tests and what's blocking them]

## Test Quality Debts

[Auto-populated from 05-test-debts.md]

## Release Recommendation

**Status:** $ReleaseReady

**Next Steps:**
- [Action 1]
- [Action 2]
- [Action 3]

"@

Set-Content -Path $OutputFile -Value $DetailedReport

# ── Write executive summary ───────────────────────────────────────────────────
$ExecutiveSummary = @"
# Test Summary — Executive Report

> Date: $DateNow

## Release Readiness

**Status:** $ReleaseReady

| Metric | Target | Achieved | Status |
|---|---|---|---|
| Coverage | 95%+ | $Coverage | [✓/⚠/✗] |
| Pass Rate | 90%+ | [Add %] | [✓/⚠/✗] |
| P0 Bugs | 0 | [Add count] | [✓/✗] |
| Blockers | 0 | [Add count] | [✓/✗] |

## Summary

[Add 2–3 sentence summary of test results, key findings, and recommendation]

## Next Steps

- [Top priority action]
- [Second priority]
- [Third priority]

"@

Set-Content -Path $FinalFile -Value $ExecutiveSummary

$endDebts = Get-TST-DebtCount
$newDebts = $endDebts - $startDebts

Write-TST-SuccessRule "✅ Test Reports Complete"
Write-Host "$($script:TSTGreen)  Detailed report: $OutputFile$($script:TSTNc)"
Write-Host "$($script:TSTGreen)  Executive summary: $FinalFile$($script:TSTNc)"
if ($newDebts -gt 0) {
  Write-Host "$($script:TSTYellow)  ⚠  $newDebts test quality debt(s) logged to: $script:TSTDebtFile$($script:TSTNc)"
}
Write-Host ""
