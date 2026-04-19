# =============================================================================
# run-all.ps1 — Orchestrator: Runs all 4 testing phases in sequence (PowerShell 5.1+)
# Executes: test-planning → test-case-design → test-execution → test-report
# Output: All test artifacts in test-output/ plus consolidated debts
# =============================================================================

param([switch]$Auto, [string]$Answers = "")



# Step 1: accept --auto / --answers
if ($Auto) { $env:TEST_AUTO = '1' }
if ($Answers) { $env:TEST_ANSWERS = $Answers }
if (Get-Command Invoke-TEST-ParseFlags -ErrorAction SilentlyContinue) { Invoke-TEST-ParseFlags -Args $args }

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

# ── Header ────────────────────────────────────────────────────────────────────
Write-TST-Banner "🧪  TESTER WORKFLOW — Complete Testing Lifecycle"
Write-TST-Dim "  This will run all 4 phases: Planning → Design → Execution → Report"
Write-TST-Dim "  Estimated time: 30–60 minutes depending on project scope."
Write-Host ""

if (Test-TEST-Auto) {
  $HasConfirmed = "yes"
} else {
  $HasConfirmed = Ask-TST-YN "Ready to begin the complete testing workflow?"
}
if ($HasConfirmed -ne "yes") {
  Write-Host "  Cancelled."
  exit 0
}

Write-Host ""

# ── Phase 1: Test Planning ────────────────────────────────────────────────────
Write-Host "$($script:TSTCyan)$($script:TSTBold)Phase 1 / 4 — Test Planning$($script:TSTNc)"
Write-TST-Dim "  Running: pwsh <SKILL_DIR>/test-planning/scripts/plan.ps1"
Write-Host ""

$PlanningScript = Join-Path $ScriptDir "..\..\test-planning\scripts\plan.ps1"
if (Test-Path $PlanningScript) {
  & pwsh $PlanningScript
} else {
  Write-TST-Dim "  ⚠  Script not found. Skipping Phase 1."
}

Write-Host ""
Write-Host "$($script:TSTMagenta)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:TSTNc)"
Write-Host ""

# ── Phase 2: Test Case Design ────────────────────────────────────────────────
Write-Host "$($script:TSTCyan)$($script:TSTBold)Phase 2 / 4 — Test Case Design$($script:TSTNc)"
Write-TST-Dim "  Running: pwsh <SKILL_DIR>/test-case-design/scripts/design-cases.ps1"
Write-Host ""

$DesignScript = Join-Path $ScriptDir "..\..\test-case-design\scripts\design-cases.ps1"
if (Test-Path $DesignScript) {
  & pwsh $DesignScript
} else {
  Write-TST-Dim "  ⚠  Script not found. Skipping Phase 2."
}

Write-Host ""
Write-Host "$($script:TSTMagenta)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:TSTNc)"
Write-Host ""

# ── Phase 3: Test Execution ───────────────────────────────────────────────────
Write-Host "$($script:TSTCyan)$($script:TSTBold)Phase 3 / 4 — Test Execution & Bug Tracking$($script:TSTNc)"
Write-TST-Dim "  Running: pwsh <SKILL_DIR>/test-execution/scripts/execute.ps1"
Write-Host ""

$ExecutionScript = Join-Path $ScriptDir "..\..\test-execution\scripts\execute.ps1"
if (Test-Path $ExecutionScript) {
  & pwsh $ExecutionScript
} else {
  Write-TST-Dim "  ⚠  Script not found. Skipping Phase 3."
}

Write-Host ""
Write-Host "$($script:TSTMagenta)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:TSTNc)"
Write-Host ""

# ── Phase 4: Test Summary Report ──────────────────────────────────────────────
Write-Host "$($script:TSTCyan)$($script:TSTBold)Phase 4 / 4 — Test Summary Report & Release Recommendation$($script:TSTNc)"
Write-TST-Dim "  Running: pwsh <SKILL_DIR>/test-report/scripts/report.ps1"
Write-Host ""

$ReportScript = Join-Path $ScriptDir "..\..\test-report\scripts\report.ps1"
if (Test-Path $ReportScript) {
  & pwsh $ReportScript
} else {
  Write-TST-Dim "  ⚠  Script not found. Skipping Phase 4."
}

Write-Host ""
Write-Host "$($script:TSTMagenta)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$($script:TSTNc)"
Write-Host ""

# ── Completion ────────────────────────────────────────────────────────────────
Write-TST-SuccessRule "✅ TESTER WORKFLOW COMPLETE"

Write-TST-Dim "All test artifacts have been created in: $script:TSTOutputDir"
Write-Host ""
Write-TST-Dim "Output files:"
Get-ChildItem "$script:TSTOutputDir\*.md" 2>$null | ForEach-Object { Write-Host "  $($_.Name)" }
Write-Host ""

$DebtCount = Get-TST-DebtCount
if ($DebtCount -gt 0) {
  Write-Host "$($script:TSTYellow)⚠  $DebtCount test quality debt(s) recorded.$($script:TSTNc)"
  Write-TST-Dim "Review: $script:TSTDebtFile"
  Write-Host ""
}

Write-TST-Dim "Next steps:"
Write-TST-Dim "  1. Review: $script:TSTOutputDir\01-test-plan.md"
Write-TST-Dim "  2. Review: $script:TSTOutputDir\02-test-cases.md"
Write-TST-Dim "  3. Review: $script:TSTOutputDir\03-test-execution.md"
Write-TST-Dim "  4. Review: $script:TSTOutputDir\TESTER-FINAL.md (executive summary)"
Write-Host ""
