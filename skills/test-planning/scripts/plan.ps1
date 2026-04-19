# =============================================================================
# plan.ps1 — Phase 1: Test Planning (PowerShell 5.1+)
# Defines test scope, levels, approach, environments, entry/exit criteria,
# risk-based priorities, and schedule.
# Output: $env:TEST_OUTPUT_DIR\01-test-plan.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:TEST_AUTO = '1' }
if ($Answers) { $env:TEST_ANSWERS = $Answers }


$OutputFile = "$script:TSTOutputDir\01-test-plan.md"
$Area = "Test Planning"

$startDebts = Get-TST-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-TST-Banner "🧪  Step 1 of 4 — Test Planning"
Write-TST-Dim "  Let's define your test strategy. I'll ask you eight simple questions."
Write-TST-Dim "  There are no wrong answers — just share what you know."
Write-Host ""

# ── Q1: Test scope ────────────────────────────────────────────────────────────
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 1 / 8 — Test Scope$($script:TSTNc)"
Write-TST-Dim "  Which user stories or features are in scope for testing?"
Write-TST-Dim "  Example: 'Login, user profile, payment checkout, reporting'"
Write-Host ""
$TestScope = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($TestScope)) {
  $TestScope = "To be defined"
  Add-TST-Debt -Area $Area -Title "Test scope not defined" `
    -Description "Which user stories and features are in testing scope is not documented" `
    -Impact "Test case design and coverage planning"
}

# ── Q2: Test levels ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 2 / 8 — Test Levels$($script:TSTNc)"
Write-TST-Dim "  Which test levels do you need?"
Write-Host ""
$TestLevels = Ask-TST-Choice "Select one:" @(
  "Unit Testing — individual functions and modules",
  "Integration Testing — modules working together",
  "System Testing — end-to-end workflows",
  "User Acceptance Testing (UAT) — business users validate",
  "All of the above"
)

# ── Q3: Test approach ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 3 / 8 — Test Approach$($script:TSTNc)"
Write-TST-Dim "  How will testing be executed?"
Write-Host ""
$TestApproach = Ask-TST-Choice "Select one:" @(
  "All manual — testers execute every test by hand",
  "Mostly manual with some automation — 70% manual, 30% automated",
  "Hybrid — 50% manual, 50% automated",
  "Mostly automated — 30% manual, 70% automated"
)

# ── Q4: Test environments ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 4 / 8 — Test Environments$($script:TSTNc)"
Write-TST-Dim "  What environments are available for testing?"
Write-TST-Dim "  Example: 'Development, Staging, UAT, Production (read-only)'"
Write-Host ""
$TestEnvs = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($TestEnvs)) {
  $TestEnvs = "TBD"
  Add-TST-Debt -Area $Area -Title "Test environments not specified" `
    -Description "Available test environments (Dev, Staging, UAT) are not documented" `
    -Impact "Test execution planning and data refresh strategy"
}

# ── Q5: Entry criteria ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 5 / 8 — Entry Criteria$($script:TSTNc)"
Write-TST-Dim "  What must be true before testing can START?"
Write-TST-Dim "  Example: 'Code is built, test data is prepared, builds are stable'"
Write-Host ""
$EntryCriteria = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($EntryCriteria)) {
  $EntryCriteria = "TBD"
  Add-TST-Debt -Area $Area -Title "Entry criteria not defined" `
    -Description "Conditions for starting testing are not documented" `
    -Impact "Test readiness assessment and schedule"
}

# ── Q6: Exit criteria ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 6 / 8 — Exit Criteria$($script:TSTNc)"
Write-TST-Dim "  What must be true for testing to be COMPLETE and ready for release?"
Write-TST-Dim "  Example: 'All critical tests pass, all P1 bugs fixed, coverage >= 95%'"
Write-Host ""
$ExitCriteria = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($ExitCriteria)) {
  $ExitCriteria = "TBD"
  Add-TST-Debt -Area $Area -Title "Exit criteria not defined" `
    -Description "Conditions for completing testing and releasing are not documented" `
    -Impact "Release readiness assessment"
}

# ── Q7: Risk-based priorities ─────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 7 / 8 — Risk-Based Priorities$($script:TSTNc)"
Write-TST-Dim "  Which features or workflows are highest RISK and need the most testing?"
Write-TST-Dim "  Example: 'Login (critical), payment (high), UI polish (low)'"
Write-Host ""
$Priorities = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($Priorities)) {
  $Priorities = "TBD"
  Add-TST-Debt -Area $Area -Title "Risk priorities not identified" `
    -Description "Which features are highest risk and need most test coverage is not clear" `
    -Impact "Test case prioritization and resource allocation"
}

# ── Q8: Testing schedule ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 8 / 8 — Testing Schedule$($script:TSTNc)"
Write-TST-Dim "  Estimate the total testing effort (in hours or days)."
Write-TST-Dim "  Example: 'Unit: 8h, Integration: 12h, System: 24h, UAT: 16h = 60h total'"
Write-Host ""
$Schedule = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($Schedule)) {
  $Schedule = "TBD"
  Add-TST-Debt -Area $Area -Title "Testing schedule not estimated" `
    -Description "Total effort and timeline for testing is not documented" `
    -Impact "Sprint planning and resource allocation"
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-TST-SuccessRule "✅ Test Planning Summary"
Write-Host "  $($script:TSTBold)Scope:$($script:TSTNc)         $TestScope"
Write-Host "  $($script:TSTBold)Levels:$($script:TSTNc)        $TestLevels"
Write-Host "  $($script:TSTBold)Approach:$($script:TSTNc)      $TestApproach"
Write-Host "  $($script:TSTBold)Environments:$($script:TSTNc)  $TestEnvs"
Write-Host "  $($script:TSTBold)Entry Criteria:$($script:TSTNc) $EntryCriteria"
Write-Host "  $($script:TSTBold)Exit Criteria:$($script:TSTNc)  $ExitCriteria"
Write-Host "  $($script:TSTBold)Priorities:$($script:TSTNc)    $Priorities"
Write-Host "  $($script:TSTBold)Schedule:$($script:TSTNc)      $Schedule"
Write-Host ""

if (-not (Confirm-TST-Save "Does this look correct? (y=save / n=redo)")) {
  Write-TST-Dim "  Restarting step 1..."
  & pwsh $MyInvocation.MyCommand.Path
  exit
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$Content = @"
# Test Plan

> Captured: $DateNow

## Test Scope

**In Scope:**
$TestScope

## Test Levels

$TestLevels

## Test Approach

$TestApproach

## Test Environments

$TestEnvs

## Entry Criteria

$EntryCriteria

## Exit Criteria

$ExitCriteria

## Risk-Based Priorities

$Priorities

## Testing Schedule

$Schedule

"@

Set-Content -Path $OutputFile -Value $Content

$endDebts = Get-TST-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host "$($script:TSTGreen)  Saved to: $OutputFile$($script:TSTNc)"
if ($newDebts -gt 0) {
  Write-Host "$($script:TSTYellow)  ⚠  $newDebts test quality debt(s) logged to: $script:TSTDebtFile$($script:TSTNc)"
}
Write-Host ""
