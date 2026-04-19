# =============================================================================
# execute.ps1 — Phase 3: Test Execution & Bug Tracking (PowerShell 5.1+)
#
# Records pass/fail/blocked counts AND captures structured bug entries that
# the bug-fixer subagent consumes. Writes:
#   - $TSTOutputDir/03-test-execution.md
#   - $TSTOutputDir/bugs.md
#   - $TSTOutputDir/bugs.extract
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

if ($Auto)    { $env:TEST_AUTO = '1' }
if ($Answers) { $env:TEST_ANSWERS = $Answers }

$OutputFile   = "$script:TSTOutputDir\03-test-execution.md"
$BugsFile     = "$script:TSTOutputDir\bugs.md"
$BugsExtract  = "$script:TSTOutputDir\bugs.extract"
$Area         = "Test Execution"

$startDebts = Get-TST-DebtCount

function Ensure-BugsFile {
  if (-not (Test-Path $BugsFile)) {
@'
# Bug Register

> One section per bug. The bug-fixer subagent parses this file, so keep the
> schema consistent: `## BUG-NN: <title>` heading, fields in the order shown,
> and `### Steps to Reproduce / ### Expected / ### Actual / ### Evidence /
> ### Regression Risk / ### Suggested Fix` sub-headings. Add new bugs at the
> bottom; never renumber or remove an existing entry.

---

'@ | Set-Content -Path $BugsFile -Encoding UTF8
  }
}

function Get-BugsCount {
  if (-not (Test-Path $BugsFile)) { return 0 }
  $matches = @(Select-String -Path $BugsFile -Pattern "^## BUG-" -AllMatches -ErrorAction SilentlyContinue)
  return $matches.Count
}

function Get-NextBugId {
  $n = Get-BugsCount
  return ("BUG-{0:D3}" -f ($n + 1))
}

function Append-Bug {
  param(
    [string]$Id, [string]$Title, [string]$Severity, [string]$Priority,
    [string]$Component, [string]$Story, [string]$TestCase, [string]$Environment,
    [string]$Steps, [string]$Expected, [string]$Actual, [string]$Evidence,
    [string]$Regression, [string]$Suggested, [string]$Reporter
  )
  Ensure-BugsFile
  $found = Get-Date -Format "yyyy-MM-dd"
  $entry = @"
## $Id`: $Title

**Severity:** $Severity
**Priority:** $Priority
**Status:** Open
**Found:** $found
**Found in:** $Environment
**Component:** $Component
**Related story:** $Story
**Related test case:** $TestCase
**Reporter:** $Reporter

### Steps to Reproduce

$Steps

### Expected

$Expected

### Actual

$Actual

### Evidence

$Evidence

### Regression Risk

$Regression

### Suggested Fix

$Suggested

---

"@
  Add-Content -Path $BugsFile -Value $entry -Encoding UTF8
}

Write-TST-Banner "▶️  Step 3 of 4 — Test Execution & Bug Tracking"
Write-TST-Dim "  Record test execution results and log each bug in full detail."
Write-TST-Dim "  The bug-fixer subagent reads bugs.md — richer entries mean"
Write-TST-Dim "  faster, safer fixes."
Write-Host ""

$RoundId = Ask-TST-Text "Question 1/6 — Execution Round ID (e.g. 'Round 1', 'Sprint 3 UAT'):"
if ([string]::IsNullOrWhiteSpace($RoundId)) { $RoundId = "Round $((Get-Date).ToString('yyMMddHHmm'))" }

$Summary = Ask-TST-Text "Question 2/6 — Execution summary (e.g. '45 passed, 4 failed, 1 blocked'):"
if ([string]::IsNullOrWhiteSpace($Summary)) {
  $Summary = "TBD"
  Add-TST-Debt -Area $Area -Title "Test execution summary not recorded" `
    -Description "Execution results (passed/failed/blocked counts) not documented" `
    -Impact "Test reporting and metrics"
}

$EnvDetails = Ask-TST-Text "Question 3/6 — Environment (OS, browser, version, config):"
if ([string]::IsNullOrWhiteSpace($EnvDetails)) { $EnvDetails = "TBD" }

$Reporter = Ask-TST-Text "Question 4/6 — Reporter (tester name):"
if ([string]::IsNullOrWhiteSpace($Reporter)) { $Reporter = "QA" }

$BugIdList = New-Object System.Collections.Generic.List[string]
$bugsInRound = 0

Write-Host ""
Write-Host "Question 5/6 — Bug logging loop"
Write-TST-Dim "  11 fields per bug. Schema matches bugs.md so the fixer can parse."
Write-Host ""

if (Test-TST-Auto) {
  Write-TST-Dim "  [Auto mode] Skipping interactive bug loop."
} else {
  while ($true) {
    if ((Ask-TST-YN "Add a bug from this round?") -ne "yes") { break }

    $BugId = Get-NextBugId
    Write-Host "  Logging $BugId — 11 fields"

    $Title    = Ask-TST-Text "1/11  Title (one line):"
    if ([string]::IsNullOrWhiteSpace($Title)) { $Title = "Untitled" }

    $Severity = Ask-TST-Choice -Prompt "2/11  Severity:" -Options @(
      "Critical — system unusable / data loss / security breach",
      "Major — core feature broken / significant user impact",
      "Minor — peripheral feature broken / workaround exists",
      "Trivial — cosmetic or very low impact")
    $Severity = ($Severity -split " — ")[0]

    $Priority = Ask-TST-Choice -Prompt "3/11  Priority:" -Options @(
      "P0 — drop everything, fix now",
      "P1 — fix this sprint",
      "P2 — fix next sprint",
      "P3 — backlog")
    $Priority = ($Priority -split " — ")[0]

    $Component = Ask-TST-Text "4/11  Component (module or file path, e.g. src/auth/login.ts):"
    if ([string]::IsNullOrWhiteSpace($Component)) {
      $Component = "Unknown"
      Add-TST-Debt -Area $Area -Title "$BugId component not identified" `
        -Description "Bug logged without component hint" `
        -Impact "Bug-fixer has to search the codebase blindly"
    }

    $Story    = Ask-TST-Text "5/11  Related story / requirement (e.g. FR-03):"
    if ([string]::IsNullOrWhiteSpace($Story)) { $Story = "N/A" }

    $TestCase = Ask-TST-Text "6/11  Test case that detected this (e.g. TC-12):"
    if ([string]::IsNullOrWhiteSpace($TestCase)) { $TestCase = "N/A" }

    $Steps = ""
    $stepNum = 1
    while ($true) {
      $line = Ask-TST-Text "    Step $stepNum (blank to finish):"
      if ([string]::IsNullOrWhiteSpace($line)) { break }
      $Steps += "$stepNum. $line`n"
      $stepNum++
    }
    if ([string]::IsNullOrWhiteSpace($Steps)) {
      $Steps = "(not captured)"
      Add-TST-Debt -Area $Area -Title "$BugId reproduction steps missing" `
        -Description "Bug logged without reproducible steps" `
        -Impact "Bug-fixer cannot verify the fix works"
    }

    $Expected   = Ask-TST-Text "8/11  Expected behaviour:"
    if ([string]::IsNullOrWhiteSpace($Expected))   { $Expected = "(not captured)" }
    $Actual     = Ask-TST-Text "9/11  Actual behaviour:"
    if ([string]::IsNullOrWhiteSpace($Actual))     { $Actual = "(not captured)" }
    $Evidence   = Ask-TST-Text "10/11 Evidence (stack trace, error code, log snippet, screenshot path):"
    if ([string]::IsNullOrWhiteSpace($Evidence))   { $Evidence = "None attached" }
    $Regression = Ask-TST-Text "11/11 Regression risk (what else might break if we fix this?):"
    if ([string]::IsNullOrWhiteSpace($Regression)) { $Regression = "None obvious" }
    $Suggested  = Ask-TST-Text "(opt) Suggested fix:"
    if ([string]::IsNullOrWhiteSpace($Suggested))  { $Suggested = "Leave to bug-fixer" }

    Append-Bug -Id $BugId -Title $Title -Severity $Severity -Priority $Priority `
               -Component $Component -Story $Story -TestCase $TestCase `
               -Environment $EnvDetails -Steps $Steps -Expected $Expected `
               -Actual $Actual -Evidence $Evidence -Regression $Regression `
               -Suggested $Suggested -Reporter $Reporter

    $BugIdList.Add($BugId)
    $bugsInRound++
    Write-Host "  ✅ $BugId logged.`n"
  }
}

$BugIdsStr = if ($BugIdList.Count -gt 0) { [string]::Join(", ", $BugIdList) } else { "None" }

$Blocked = Ask-TST-Text "Question 6/6 — Blocked tests (or 'none'):"
if ([string]::IsNullOrWhiteSpace($Blocked)) { $Blocked = "None" }

$Retests = Ask-TST-Text "             Retests passing (e.g. 'BUG-001: fixed, passed'):"
if ([string]::IsNullOrWhiteSpace($Retests)) { $Retests = "None" }

Write-TST-SuccessRule "✅ Test Execution Summary"
Write-Host "  Round:        $RoundId"
Write-Host "  Results:      $Summary"
Write-Host "  Environment:  $EnvDetails"
Write-Host "  Bugs logged:  $bugsInRound ($BugIdsStr)"
Write-Host "  Blocked:      $Blocked"
Write-Host "  Retests:      $Retests"
Write-Host ""

if (-not (Confirm-TST-Save "Does this look correct? (y=save / n=redo)")) {
  Write-TST-Dim "  Restarting step 3..."
  & pwsh $MyInvocation.MyCommand.Path
  exit
}

$DateNow = Get-Date -Format "yyyy-MM-dd"
$TotalBugs = Get-BugsCount

$bugsSection = if ($bugsInRound -gt 0) {
  "- $bugsInRound new bug(s): $BugIdsStr`n- Full details: [bugs.md](./bugs.md)"
} else {
  "- None"
}

$Content = @"
# Test Execution Report

> Execution Round: $RoundId
> Date: $DateNow
> Reporter: $Reporter

## Execution Summary

$Summary

## Environment

$EnvDetails

## Bugs Logged This Round

$bugsSection

## Blocked Tests

$Blocked

## Retests

$Retests

"@

Set-Content -Path $OutputFile -Value $Content -Encoding UTF8

Write-TST-Extract -Path $BugsExtract -Pairs @{
  BUGS_FILE             = $BugsFile
  BUGS_TOTAL            = $TotalBugs
  BUGS_NEW_THIS_ROUND   = $bugsInRound
  BUGS_IDS_THIS_ROUND   = $BugIdsStr
  ROUND_ID              = $RoundId
  REPORTER              = $Reporter
  ENVIRONMENT           = $EnvDetails
}

$endDebts = Get-TST-DebtCount
$newDebts = $endDebts - $startDebts

Write-Host "  Saved execution report: $OutputFile"
Write-Host "  Bug register:           $BugsFile  ($TotalBugs total)"
Write-Host "  Extract for bug-fixer:  $BugsExtract"
if ($newDebts -gt 0) {
  Write-Host "  ⚠  $newDebts test quality debt(s) logged to: $script:TSTDebtFile"
}
Write-Host ""
