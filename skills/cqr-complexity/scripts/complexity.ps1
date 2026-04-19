#Requires -Version 5.1
# =============================================================================
# complexity.ps1 — Phase 2: Complexity & Maintainability Analysis (PowerShell)
#
# Usage:
#   pwsh <SKILL_DIR>/cqr-complexity/scripts/complexity.ps1 [-Auto] [-Answers <file>]
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/_common.ps1"

if ($Auto) { $env:CQR_AUTO = '1'; $script:CQRAuto = $true }
if ($Answers) { $env:CQR_ANSWERS = $Answers; $script:CQRAnswers = $Answers }

$OutputFile  = Join-Path $script:CQROutputDir "02-complexity-report.md"
$ExtractFile = Join-Path $script:CQROutputDir "02-complexity-report.extract"

$DefModules   = "entire codebase"
$DefCc        = "≤10 (standard)"
$DefFuncLen   = "30 lines (balanced)"
$DefFileLen   = "300 lines (balanced)"
$DefCoupling  = "None suspected"
$DefDebtAreas = "None known"

Write-CQR-Banner "Phase 2: Complexity & Maintainability Analysis"

function Resolve-OrDefault {
  param([string]$Value, [string]$OtherKey, [string]$Default, [string]$Area, [string]$KeyName)
  if ($Value -eq "Other — specify") {
    return (Get-CQR-Answer -Key $OtherKey -Prompt "Specify:" -Default $Default)
  } elseif ($Value -like "Not sure*") {
    Add-CQR-DebtAuto -Area $Area -Title "$KeyName not confirmed" `
      -Description "User did not confirm $KeyName" -Impact "Defaulting to $Default"
    return $Default
  }
  return $Value
}

$MODULES = Get-CQR-Answer -Key "MODULES" -Prompt "Files/modules to analyze (free text)" -Default $DefModules

$CC_THRESHOLD = Get-CQR-Choice -Key "CC_THRESHOLD" -Prompt "Max CC per function:" -Options @(
  "≤5 (strict)","≤10 (standard)","≤15 (lenient)","≤20 (legacy tolerance)",
  "Other — specify","Not sure — use default ($DefCc) and log debt")
$CC_THRESHOLD = Resolve-OrDefault $CC_THRESHOLD "CC_THRESHOLD_SPECIFY" $DefCc "Complexity" "CC_THRESHOLD"

$FUNC_LEN = Get-CQR-Choice -Key "FUNC_LEN" -Prompt "Max function length:" -Options @(
  "20 lines (Python-style)","30 lines (balanced)","50 lines (typical JS/Go/Java)",
  "100 lines (lenient)","Other — specify","Not sure — use default ($DefFuncLen) and log debt")
$FUNC_LEN = Resolve-OrDefault $FUNC_LEN "FUNC_LEN_SPECIFY" $DefFuncLen "Complexity" "FUNC_LEN"

$FILE_LEN = Get-CQR-Choice -Key "FILE_LEN" -Prompt "Max file length:" -Options @(
  "200 lines (strict SRP)","300 lines (balanced)","500 lines (moderate)",
  "1000 lines (lenient, OK for Go/Java)","Other — specify",
  "Not sure — use default ($DefFileLen) and log debt")
$FILE_LEN = Resolve-OrDefault $FILE_LEN "FILE_LEN_SPECIFY" $DefFileLen "Complexity" "FILE_LEN"

$COUPLING = Get-CQR-Answer -Key "COUPLING" -Prompt "Suspected high coupling or cycles" -Default $DefCoupling
if (-not $COUPLING) { $COUPLING = $DefCoupling }

$DEBT_AREAS = Get-CQR-Answer -Key "DEBT_AREAS" -Prompt "Known technical debt / complex areas" -Default $DefDebtAreas
if (-not $DEBT_AREAS) { $DEBT_AREAS = $DefDebtAreas }

$timestamp = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$mode = if (Test-CQR-Auto) { "Auto" } else { "Interactive" }

$md = @"
# Phase 2: Complexity & Maintainability Analysis

**Timestamp:** $timestamp
**Status:** Complete
**Mode:** $mode

## Analysis Parameters

| Parameter | Value |
|---|---|
| **Scope** | $MODULES |
| **CC threshold** | $CC_THRESHOLD |
| **Function length limit** | $FUNC_LEN |
| **File size limit** | $FILE_LEN |
| **Coupling concerns** | $COUPLING |
| **Known debt areas** | $DEBT_AREAS |

## Next Phase

Run: ``pwsh <SKILL_DIR>/cqr-patterns/scripts/patterns.ps1``

---
"@

$md | Out-File -Path $OutputFile -Encoding UTF8 -Force

Write-CQR-Extract -Path $ExtractFile -Pairs @{
  MODULES      = $MODULES
  CC_THRESHOLD = $CC_THRESHOLD
  FUNC_LEN     = $FUNC_LEN
  FILE_LEN     = $FILE_LEN
  COUPLING     = $COUPLING
  DEBT_AREAS   = $DEBT_AREAS
}

Write-CQR-SuccessRule
Write-Host "✅ Phase 2 Complete."
Write-Host "  Markdown: $OutputFile"
Write-Host "  Extract:  $ExtractFile"
Write-Host "`nNext: Phase 3 — pwsh <SKILL_DIR>/cqr-patterns/scripts/patterns.ps1`n"
