# =============================================================================
# design-cases.ps1 — Phase 2: Test Case Design (PowerShell 5.1+)
# Writes detailed test cases with positive, negative, and boundary scenarios.
# Output: $env:TEST_OUTPUT_DIR\02-test-cases.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:TEST_AUTO = '1' }
if ($Answers) { $env:TEST_ANSWERS = $Answers }


$OutputFile = "$script:TSTOutputDir\02-test-cases.md"
$Area = "Test Case Design"

$startDebts = Get-TST-DebtCount

# ── Header ────────────────────────────────────────────────────────────────────
Write-TST-Banner "📝  Step 2 of 4 — Test Case Design"
Write-TST-Dim "  Let's write detailed test cases. I'll ask you several questions."
Write-TST-Dim "  Test cases will follow Given/When/Then format for clarity."
Write-Host ""

# ── Q1: User story selection ──────────────────────────────────────────────────
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 1 / 6 — Which User Story?$($script:TSTNc)"
Write-TST-Dim "  What is the user story or feature you want to test?"
Write-TST-Dim "  Example: 'US-01: User login with email and password'"
Write-Host ""
$UserStory = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($UserStory)) {
  $UserStory = "Unspecified User Story"
  Add-TST-Debt -Area $Area -Title "User story not specified" `
    -Description "Test case design started without selecting a user story" `
    -Impact "Test case coverage and traceability"
}

# ── Q2: Positive scenarios ────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 2 / 6 — Positive Scenarios$($script:TSTNc)"
Write-TST-Dim "  What are the happy-path workflows? (main success scenarios)"
Write-TST-Dim "  Example: 'Valid login, user redirected to dashboard'"
Write-Host ""
$Positive = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($Positive)) {
  $Positive = "TBD"
  Add-TST-Debt -Area $Area -Title "Positive scenarios not identified" `
    -Description "Main success paths for this user story are not documented" `
    -Impact "Test case completeness and coverage"
}

# ── Q3: Negative scenarios ────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 3 / 6 — Negative Scenarios$($script:TSTNc)"
Write-TST-Dim "  What error conditions must be handled?"
Write-TST-Dim "  Example: 'Invalid password, account locked, user not found'"
Write-Host ""
$Negative = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($Negative)) {
  $Negative = "TBD"
  Add-TST-Debt -Area $Area -Title "Negative scenarios not identified" `
    -Description "Error conditions and edge cases are not documented" `
    -Impact "Test case completeness and risk coverage"
}

# ── Q4: Boundary scenarios ────────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 4 / 6 — Boundary Scenarios$($script:TSTNc)"
Write-TST-Dim "  What edge cases should be tested?"
Write-TST-Dim "  Example: 'Empty password, 255-char email, SQL injection attempt'"
Write-Host ""
$Boundary = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($Boundary)) {
  $Boundary = "TBD"
  Add-TST-Debt -Area $Area -Title "Boundary scenarios not identified" `
    -Description "Edge cases and limit testing scenarios are not documented" `
    -Impact "Test case completeness"
}

# ── Q5: Test data requirements ────────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 5 / 6 — Test Data Requirements$($script:TSTNc)"
Write-TST-Dim "  What data is needed to run these test cases?"
Write-TST-Dim "  Example: '5 test users with different roles, 10 products, 100 transactions'"
Write-Host ""
$TestData = Ask-TST-Text "Your answer:"
if ([string]::IsNullOrWhiteSpace($TestData)) {
  $TestData = "TBD"
  Add-TST-Debt -Area $Area -Title "Test data not specified" `
    -Description "Specific test data needed for this story is not documented" `
    -Impact "Test execution planning and data setup"
}

# ── Q6: Expected results format ───────────────────────────────────────────────
Write-Host ""
Write-Host "$($script:TSTCyan)$($script:TSTBold)Question 6 / 6 — Expected Results Format$($script:TSTNc)"
Write-Host ""
$ResultsFormat = Ask-TST-Choice "What level of detail for expected results?" @(
  "Pass/Fail only",
  "Pass/Fail + error message",
  "Detailed assertions (UI, API, database state)"
)

# ── Summary ───────────────────────────────────────────────────────────────────
Write-TST-SuccessRule "✅ Test Case Design Summary"
Write-Host "  $($script:TSTBold)User Story:$($script:TSTNc)      $UserStory"
Write-Host "  $($script:TSTBold)Positive:$($script:TSTNc)        $Positive"
Write-Host "  $($script:TSTBold)Negative:$($script:TSTNc)        $Negative"
Write-Host "  $($script:TSTBold)Boundary:$($script:TSTNc)        $Boundary"
Write-Host "  $($script:TSTBold)Test Data:$($script:TSTNc)       $TestData"
Write-Host "  $($script:TSTBold)Results Format:$($script:TSTNc)  $ResultsFormat"
Write-Host ""

if (-not (Confirm-TST-Save "Does this look correct? (y=save / n=redo)")) {
  Write-TST-Dim "  Restarting step 2..."
  & pwsh $MyInvocation.MyCommand.Path
  exit
}

# ── Write output ──────────────────────────────────────────────────────────────
$DateNow = Get-Date -Format "yyyy-MM-dd"
$Content = @"
# Test Cases

> Captured: $DateNow

## User Story

**Story:** $UserStory

## Test Scenarios

### Positive (Happy Path)

$Positive

### Negative (Error Conditions)

$Negative

### Boundary (Edge Cases)

$Boundary

## Test Data

$TestData

## Expected Results Format

$ResultsFormat

## Test Case Template

### TC-001: [Scenario]

**Given** [Preconditions]
**When** [User action]
**Then** [Expected result]

"@

Set-Content -Path $OutputFile -Value $Content

$endDebts = Get-TST-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host "$($script:TSTGreen)  Saved to: $OutputFile$($script:TSTNc)"
if ($newDebts -gt 0) {
  Write-Host "$($script:TSTYellow)  ⚠  $newDebts test quality debt(s) logged to: $script:TSTDebtFile$($script:TSTNc)"
}
Write-Host ""
