#Requires -Version 5.1
# =============================================================================
# patterns.ps1 — Phase 3: Design Pattern & Architecture Compliance (PowerShell)
#
# Usage:
#   pwsh <SKILL_DIR>/cqr-patterns/scripts/patterns.ps1 [-Auto] [-Answers <file>]
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/_common.ps1"

if ($Auto) { $env:CQR_AUTO = '1'; $script:CQRAuto = $true }
if ($Answers) { $env:CQR_ANSWERS = $Answers; $script:CQRAnswers = $Answers }

$OutputFile  = Join-Path $script:CQROutputDir "03-patterns-review.md"
$ExtractFile = Join-Path $script:CQROutputDir "03-patterns-review.extract"

$DefPattern  = "Layered (Presentation / Domain / Data)"
$DefSolid    = "All five — balanced priority"
$DefDry      = "None identified"
$DefSoc      = "Separated: services for logic, repositories for persistence, controllers for HTTP"
$DefErrors   = "Exceptions for exceptional flows + custom exception types"
$DefLogging  = "Structured logs + level discipline (DEBUG/INFO/WARN/ERROR)"

Write-CQR-Banner "Phase 3: Design Pattern & Architecture Compliance"

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

$PATTERN = Get-CQR-Choice -Key "PATTERN" -Prompt "Expected pattern:" -Options @(
  "Layered (Presentation / Domain / Data)",
  "Hexagonal / Ports & Adapters",
  "Domain-Driven Design (DDD)",
  "MVC","Microservices","Monolith with modules",
  "Event-driven","CQRS",
  "Other — specify","Not sure — use default ($DefPattern) and log debt")
$PATTERN = Resolve-OrDefault $PATTERN "PATTERN_SPECIFY" $DefPattern "Patterns" "PATTERN"

$SOLID = Get-CQR-Choice -Key "SOLID" -Prompt "SOLID priority:" -Options @(
  "All five — balanced priority",
  "S + D (SRP + DI) — most common critical pair",
  "S only — keep classes focused",
  "O only — extension over modification",
  "D only — dependency inversion / testability",
  "Other — specify","Not sure — use default ($DefSolid) and log debt")
$SOLID = Resolve-OrDefault $SOLID "SOLID_SPECIFY" $DefSolid "Patterns" "SOLID"

$DRY = Get-CQR-Answer -Key "DRY" -Prompt "Known duplication areas (or 'None')" -Default $DefDry
if (-not $DRY) { $DRY = $DefDry }

$SOC = Get-CQR-Choice -Key "SOC" -Prompt "Current state of SoC:" -Options @(
  "Well separated (services / repos / controllers)",
  "Some leakage (business logic touching SQL or HTTP)",
  "Significant leakage (mixed responsibilities)",
  "Not assessed",
  "Other — specify","Not sure — use default ($DefSoc) and log debt")
$SOC = Resolve-OrDefault $SOC "SOC_SPECIFY" $DefSoc "Patterns" "SOC"

$ERRORS = Get-CQR-Choice -Key "ERRORS" -Prompt "Error handling approach:" -Options @(
  "Exceptions + custom exception types",
  "Result<T,E> / Either<L,R> (functional style)",
  "Error codes / tuple returns (Go, Rust-style)",
  "Panic/recover or unchecked (language default)",
  "Inconsistent — mixed approaches",
  "Other — specify","Not sure — use default ($DefErrors) and log debt")
$ERRORS = Resolve-OrDefault $ERRORS "ERRORS_SPECIFY" $DefErrors "Patterns" "ERRORS"

$LOGGING = Get-CQR-Choice -Key "LOGGING" -Prompt "Logging pattern:" -Options @(
  "Structured + level discipline (DEBUG/INFO/WARN/ERROR)",
  "Structured logs only (JSON)",
  "Plain text with levels","Plain text ad-hoc (no levels)",
  "No logging","Other — specify",
  "Not sure — use default ($DefLogging) and log debt")
$LOGGING = Resolve-OrDefault $LOGGING "LOGGING_SPECIFY" $DefLogging "Patterns" "LOGGING"

$timestamp = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$mode = if (Test-CQR-Auto) { "Auto" } else { "Interactive" }

$md = @"
# Phase 3: Design Pattern & Architecture Compliance

**Timestamp:** $timestamp
**Status:** Complete
**Mode:** $mode

## Analysis Parameters

| Parameter | Value |
|---|---|
| **Expected pattern** | $PATTERN |
| **SOLID priority** | $SOLID |
| **DRY concerns** | $DRY |
| **Separation of concerns** | $SOC |
| **Error handling** | $ERRORS |
| **Logging** | $LOGGING |

## Next Phase

Run: ``pwsh <SKILL_DIR>/cqr-report/scripts/report.ps1``

---
"@

$md | Out-File -Path $OutputFile -Encoding UTF8 -Force

Write-CQR-Extract -Path $ExtractFile -Pairs @{
  PATTERN = $PATTERN
  SOLID   = $SOLID
  DRY     = $DRY
  SOC     = $SOC
  ERRORS  = $ERRORS
  LOGGING = $LOGGING
}

Write-CQR-SuccessRule
Write-Host "✅ Phase 3 Complete."
Write-Host "  Markdown: $OutputFile"
Write-Host "  Extract:  $ExtractFile"
Write-Host "`nNext: Phase 4 — pwsh <SKILL_DIR>/cqr-report/scripts/report.ps1`n"
