#Requires -Version 5.1
# =============================================================================
# report.ps1 — Phase 4: Quality Report & Recommendations (PowerShell)
#
# Usage:
#   pwsh <SKILL_DIR>/cqr-report/scripts/report.ps1 [-Auto] [-Answers <file>]
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/_common.ps1"

if ($Auto) { $env:CQR_AUTO = '1'; $script:CQRAuto = $true }
if ($Answers) { $env:CQR_ANSWERS = $Answers; $script:CQRAnswers = $Answers }

$ReportFile   = Join-Path $script:CQROutputDir "04-quality-report.md"
$FinalFile    = Join-Path $script:CQROutputDir "CQR-FINAL.md"
$StandardsMd  = Join-Path $script:CQROutputDir "01-standards-review.md"
$ComplexityMd = Join-Path $script:CQROutputDir "02-complexity-report.md"
$PatternsMd   = Join-Path $script:CQROutputDir "03-patterns-review.md"
$StandardsEx  = Join-Path $script:CQROutputDir "01-standards-review.extract"
$ComplexityEx = Join-Path $script:CQROutputDir "02-complexity-report.extract"
$PatternsEx   = Join-Path $script:CQROutputDir "03-patterns-review.extract"

Write-CQR-Banner "Phase 4: Quality Report & Recommendations"

$missing = 0
foreach ($f in @($StandardsMd, $ComplexityMd, $PatternsMd)) {
  if (-not (Test-Path $f)) {
    Write-Host "  missing: $f" -ForegroundColor Yellow
    $missing = 1
  }
}
if ($missing -eq 1) {
  if (Test-CQR-Auto) {
    Add-CQR-DebtAuto -Area "Report" -Title "Missing upstream phase output" `
      -Description "One or more CQR phase outputs are missing" `
      -Impact "Final report will have TBD fields; run missing phases first"
  } else {
    Write-Host "`nOne or more phase outputs are missing. Run phases 1–3 first." -ForegroundColor Yellow
    exit 1
  }
}

function Count-DebtBySeverity {
  param([string]$Severity)
  if (-not (Test-Path $script:CQRDebtFile)) { return 0 }
  $matches = @(Select-String -Path $script:CQRDebtFile -Pattern "\*\*Severity\*\* \| $Severity" -AllMatches -ErrorAction SilentlyContinue)
  return $matches.Count
}

$crit  = Count-DebtBySeverity "Critical"
$major = Count-DebtBySeverity "Major"
$minor = Count-DebtBySeverity "Minor"
$info  = Count-DebtBySeverity "Info"
$total = Get-CQR-DebtCount

$score = 100 - ($crit * 20) - ($major * 5) - ($minor * 2) - $info
if ($score -lt 0) { $score = 0 }

$status = "Fair"
if     ($score -ge 80) { $status = "Excellent ✅" }
elseif ($score -ge 70) { $status = "Good ✓" }
elseif ($score -ge 60) { $status = "Fair (improvement needed)" }
elseif ($score -ge 50) { $status = "Poor (significant work needed)" }
else                   { $status = "Critical (immediate action)" }

$langVal    = Read-CQR-Extract -Path $StandardsEx  -Key "LANGUAGE"
$styleVal   = Read-CQR-Extract -Path $StandardsEx  -Key "STYLE"
$ccVal      = Read-CQR-Extract -Path $ComplexityEx -Key "CC_THRESHOLD"
$patternVal = Read-CQR-Extract -Path $PatternsEx   -Key "PATTERN"
if (-not $langVal)    { $langVal    = "(unknown — Phase 1 missing)" }
if (-not $styleVal)   { $styleVal   = "(unknown)" }
if (-not $ccVal)      { $ccVal      = "(unknown — Phase 2 missing)" }
if (-not $patternVal) { $patternVal = "(unknown — Phase 3 missing)" }

$timestamp = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$mode = if (Test-CQR-Auto) { "Auto" } else { "Interactive" }

$critDecr  = $crit  * 20
$majorDecr = $major * 5
$minorDecr = $minor * 2

$report = @"
# Phase 4: Quality Report & Recommendations

**Timestamp:** $timestamp
**Status:** Complete
**Mode:** $mode

## Composite Quality Score

**$score/100 — $status**

| Dimension | Debt count | Impact on score |
|---|---|---|
| 🔴 Critical | $crit | -$critDecr |
| 🟠 Major | $major | -$majorDecr |
| 🟡 Minor | $minor | -$minorDecr |
| ℹ️ Info | $info | -$info |

## Snapshot

| Dimension | Value | Source |
|---|---|---|
| Primary language | $langVal | Phase 1 |
| Style guide | $styleVal | Phase 1 |
| CC threshold | $ccVal | Phase 2 |
| Expected pattern | $patternVal | Phase 3 |

## Technical Debt Register

Total entries: $total (critical $crit, major $major, minor $minor, info $info)

---
"@
$report | Out-File -Path $ReportFile -Encoding UTF8 -Force

$final = @"
# Code Quality Review — Final Report

**Timestamp:** $timestamp
**Mode:** $mode

## Headline

**Composite Quality Score: $score/100 — $status**

$total debt entries tracked (🔴 $crit critical · 🟠 $major major · 🟡 $minor minor · ℹ️ $info info).

## Key Context

| Dimension | Value |
|---|---|
| Primary language | $langVal |
| Style guide | $styleVal |
| CC threshold | $ccVal |
| Expected architectural pattern | $patternVal |

## Success Criteria

| Metric | Current | Target |
|---|---|---|
| Composite score | $score | 80+ |
| Critical debts | $crit | 0 |
| Major debts | $major | ≤2 |

---
"@
$final | Out-File -Path $FinalFile -Encoding UTF8 -Force

Write-CQR-SuccessRule
Write-Host "✅ Code Quality Review Complete — Score: $score/100 ($status)"
