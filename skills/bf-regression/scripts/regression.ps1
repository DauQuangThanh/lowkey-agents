# =============================================================================
# regression.ps1 — Phase 3: regression test stubs (PowerShell 5.1+)
# =============================================================================

param([switch]$Auto, [string]$Answers = "", [string]$Branch = "", [switch]$DryRun)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\_common.ps1"

if ($Auto)    { $env:BF_AUTO = '1' }
if ($Answers) { $env:BF_ANSWERS = $Answers }

$OutputFile  = Join-Path $script:BFOutputDir "03-regression-tests.md"
$ExtractFile = Join-Path $script:BFOutputDir "03-regression-tests.extract"
$FixExtract  = Join-Path $script:BFOutputDir "02-fixes.extract"
$TestOutputDir = if ($env:TEST_OUTPUT_DIR) { $env:TEST_OUTPUT_DIR } else { Join-Path (Get-Location) "test-output" }
$BugsFile    = Join-Path $TestOutputDir "bugs.md"

Write-BF-Banner "Phase 3 — Regression test stubs"

if (-not (Test-Path $FixExtract)) {
  Write-Host "ERROR: Phase 2 extract not found: $FixExtract" -ForegroundColor Red
  exit 1
}

$FixedIds = Read-BF-Extract -Path $FixExtract -Key "FIXED_IDS"
$Branch   = Read-BF-Extract -Path $FixExtract -Key "BRANCH"

if ([string]::IsNullOrWhiteSpace($FixedIds) -or $FixedIds -eq "(none)") {
  $ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
@"
# Phase 3 — Regression tests

**Timestamp:** $ts

_No fixes applied in Phase 2 — no regression tests needed this round._
"@ | Set-Content -Path $OutputFile -Encoding UTF8

  Write-BF-Extract -Path $ExtractFile -Pairs @{
    TESTS_CREATED = 0
    TEST_IDS = ""
    SOURCE_FIXED_IDS = $FixedIds
  }
  Write-BF-SuccessRule "✅ Phase 3 Complete — no fixes to cover"
  exit 0
}

$Framework  = Get-BF-Answer -Key "REGRESSION_TEST_FRAMEWORK" -Prompt "Test framework:" -Default "Jest"
$TestPath   = Get-BF-Answer -Key "REGRESSION_TEST_PATH" -Prompt "Target test path:" -Default "tests/regression/"

function Get-BugField {
  param([string]$BugId, [string]$Field)
  if (-not (Test-Path $BugsFile)) { return "" }
  $inBug = $false
  foreach ($line in Get-Content -Path $BugsFile) {
    if ($line -match "^## $BugId\: ") { $inBug = $true; continue }
    if ($inBug -and $line -match "^## ") { break }
    if ($inBug -and $line -match "^\*\*${Field}:\*\* *(.+?) *$") { return $Matches[1] }
  }
  return ""
}

function Get-BugSection {
  param([string]$BugId, [string]$Heading)
  if (-not (Test-Path $BugsFile)) { return "" }
  $inBug = $false; $inSec = $false
  $out = @()
  foreach ($line in Get-Content -Path $BugsFile) {
    if ($line -match "^## $BugId\: ") { $inBug = $true; continue }
    if ($inBug -and $line -match "^## ") { break }
    if ($inBug -and $line -match "^### $Heading") { $inSec = $true; continue }
    if ($inSec -and $line -match "^### ") { break }
    if ($inSec -and $line -match "^--- *$") { break }
    if ($inSec) { $out += $line }
  }
  return ($out -join "`n").Trim()
}

$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$header = @"
# Phase 3 — Regression tests

**Timestamp:** $ts
**Branch:** $Branch
**Framework hint:** $Framework
**Test path:** $TestPath

Each regression test below is a stub. It captures the reproduction steps from
bugs.md plus the expected outcome so the tester agent can merge it into
``test-output/02-test-cases.md`` on its next run.

"@
Set-Content -Path $OutputFile -Value $header -Encoding UTF8

$testIds = New-Object System.Collections.Generic.List[string]
$n = 1
foreach ($id in $FixedIds -split ",") {
  if ([string]::IsNullOrWhiteSpace($id)) { continue }
  $title     = Get-BugField   $id "Title"
  $component = Get-BugField   $id "Component"
  $severity  = Get-BugField   $id "Severity"
  $priority  = Get-BugField   $id "Priority"
  $steps     = Get-BugSection $id "Steps to Reproduce"
  $expected  = Get-BugSection $id "Expected"

  $tcId = "TC-BF-{0:D3}" -f $n

  $stepsText    = if ($steps)    { $steps }    else { "_(Steps to Reproduce missing — check $id in bugs.md.)_" }
  $expectedText = if ($expected) { $expected } else { "_(Expected missing.)_" }

  $section = @"
## $tcId — Regression for $id

**Covers bug:** $id
**Severity:** $(if ($severity) { $severity } else { 'unknown' })
**Priority:** $(if ($priority) { $priority } else { 'unknown' })
**Component:** $(if ($component) { $component } else { 'unknown' })
**Framework:** $Framework
**Target location:** $TestPath

### Precondition

A clean test environment as described in ``$id``'s ``Found in`` field.

### Steps

$stepsText

### Expected

$expectedText

### Regression guard

Assert the test fails on the pre-fix commit AND passes on the fix commit.

``````
# Framework-specific stub — translate the steps above into code for $Framework.
# test('${id}: ${title}', () => { /* setup / exercise / assert */ });
``````

---

"@
  Add-Content -Path $OutputFile -Value $section -Encoding UTF8
  $testIds.Add($tcId)
  $n++
}

$testIdsStr = [string]::Join(",", $testIds)

Write-BF-Extract -Path $ExtractFile -Pairs @{
  TESTS_CREATED    = $testIds.Count
  TEST_IDS         = $testIdsStr
  SOURCE_FIXED_IDS = $FixedIds
  FRAMEWORK        = $Framework
  TEST_PATH_HINT   = $TestPath
}

Write-BF-SuccessRule "✅ Phase 3 Complete — $($testIds.Count) regression test stub(s)"
Write-Host "  Markdown: $OutputFile"
Write-Host "`nNext: Phase 4 — pwsh <SKILL_DIR>/bf-change-register/scripts/register.ps1`n"
