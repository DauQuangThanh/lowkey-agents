#Requires -Version 5.1
# =============================================================================
# validate.ps1 — Phase 4: Design & Code Quality Validation
# Performs automated checks on design completeness and consistency,
# asks manual validation questions, then compiles into DEVELOPER-FINAL.md
# Writes output to $DEVOutputDir/04-validation-report.md and DEVELOPER-FINAL.md
# =============================================================================

param([switch]$Auto, [string]$Answers = "")

. $PSScriptRoot\_common.ps1

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:DEV_AUTO = '1' }
if ($Answers) { $env:DEV_ANSWERS = $Answers }


$ReportFile = Join-Path $script:DEVOutputDir "04-validation-report.md"
$FinalFile = Join-Path $script:DEVOutputDir "DEVELOPER-FINAL.md"
$Area = "Design Validation"

Write-DEV-Banner "✅  Phase 4 of 4 — Design & Code Quality Validation"
Write-DEV-Dim "  Confirm design is complete, consistent, and ready for implementation."
Write-Host ""

# ── Collect all phase files ──────────────────────────────────────────────────
$designFile = Join-Path $script:DEVOutputDir "01-detailed-design.md"
$codingFile = Join-Path $script:DEVOutputDir "02-coding-plan.md"
$testFile = Join-Path $script:DEVOutputDir "03-unit-test-plan.md"
$debtFile = Join-Path $script:DEVOutputDir "05-design-debts.md"

$phase1Ok = Test-Path $designFile
$phase2Ok = Test-Path $codingFile
$phase3Ok = Test-Path $testFile

if ($phase1Ok) {
  Write-Host "  ✓ Found: 01-detailed-design.md" -ForegroundColor Green
} else {
  Write-Host "  ✗ Missing: 01-detailed-design.md" -ForegroundColor Red
}

if ($phase2Ok) {
  Write-Host "  ✓ Found: 02-coding-plan.md" -ForegroundColor Green
} else {
  Write-Host "  ✗ Missing: 02-coding-plan.md" -ForegroundColor Red
}

if ($phase3Ok) {
  Write-Host "  ✓ Found: 03-unit-test-plan.md" -ForegroundColor Green
} else {
  Write-Host "  ✗ Missing: 03-unit-test-plan.md" -ForegroundColor Red
}

Write-Host ""

# ── Count DDEBTs ─────────────────────────────────────────────────────────────
$blockingDDebts = 0
$importantDDebts = 0
if (Test-Path $debtFile) {
  $blockingDDebts = @(Get-Content $debtFile | Select-String '🔴 Blocking' | Measure-Object).Count
  $importantDDebts = @(Get-Content $debtFile | Select-String '🟡 Important' | Measure-Object).Count
}

Write-Host "── Automated Checks ──" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Design Documents: Phase 1: $($phase1Ok ? '✓' : '✗') | Phase 2: $($phase2Ok ? '✓' : '✗') | Phase 3: $($phase3Ok ? '✓' : '✗')" -ForegroundColor DarkGray
Write-Host "  Design Debts: $blockingDDebts blocking | $importantDDebts important" -ForegroundColor DarkGray
Write-Host ""

# ── Manual Questions ─────────────────────────────────────────────────────────
Write-Host "── Manual Validation Questions ──" -ForegroundColor Cyan
Write-Host ""

$q1 = Ask-DEV-YN "Can a mid-level developer pick up any module and understand it in 30 minutes?"
$q2 = Ask-DEV-YN "Are error codes and validation rules consistent across modules?"
$q3 = Ask-DEV-YN "Is the primary business flow clearly documented?"
$q4 = Ask-DEV-YN "Is the testing strategy aligned with team skill and CI/CD capacity?"
$q5 = Ask-DEV-YN "Are all stakeholders aware of their dependencies and responsibilities?"

Write-Host ""

# ── Determine sign-off status ────────────────────────────────────────────────
Write-Host "── Sign-Off Assessment ──" -ForegroundColor Cyan
Write-Host ""

$allPhases = $phase1Ok -and $phase2Ok -and $phase3Ok
$allManual = ($q1 -eq "yes") -and ($q2 -eq "yes") -and ($q3 -eq "yes") -and ($q4 -eq "yes") -and ($q5 -eq "yes")

if ($allPhases -and ($blockingDDebts -eq 0) -and $allManual) {
  $status = "READY FOR CODE"
  $statusSymbol = "✅"
  $statusColor = "Green"
} elseif ($allPhases -and ($blockingDDebts -eq 0)) {
  $status = "READY WITH CAVEATS"
  $statusSymbol = "⚠️ "
  $statusColor = "Yellow"
} else {
  $status = "NOT READY"
  $statusSymbol = "❌"
  $statusColor = "Red"
}

Write-Host "  $statusSymbol $status" -ForegroundColor $statusColor
Write-Host ""

# ── Write validation report ──────────────────────────────────────────────────
$reportContent = @"
# Design & Code Quality Validation Report

**Date:** $(Get-Date -Format 'yyyy-MM-dd')
**Status:** $status

---

## Automated Checks

### Design Documents
| Phase | Status |
|---|---|
| 1. Detailed Design | $($phase1Ok ? '✓ Present' : '✗ Missing') |
| 2. Coding Standards | $($phase2Ok ? '✓ Present' : '✗ Missing') |
| 3. Unit Test Strategy | $($phase3Ok ? '✓ Present' : '✗ Missing') |

### Design Debts
- **Blocking:** $blockingDDebts
- **Important:** $importantDDebts
$($blockingDDebts -gt 0 ? '- ⚠️  _Blocking DDEBTs must be resolved before implementation_' : '')

---

## Manual Validation

| Question | Answer |
|---|---|
| Can a mid-level developer understand any module in 30 min? | $q1 |
| Are error codes & validation rules consistent? | $q2 |
| Is the primary business flow clearly documented? | $q3 |
| Is testing strategy aligned with team & CI/CD? | $q4 |
| Are all stakeholders aware of dependencies? | $q5 |

---

## Sign-Off Status

**$status**

$($status -eq 'READY FOR CODE' ? 'All design phases complete, no blocking debts, and all validation questions answered affirmatively. **Ready to begin implementation.**' : '')
$($status -eq 'READY WITH CAVEATS' ? 'Design is substantially complete with minor gaps tracked as DDEBTs. Implementation can proceed with awareness of open items.' : '')
$($status -eq 'NOT READY' ? 'Design has gaps or blocking debts that must be resolved before implementation starts.' : '')

"@

Set-Content -Path $ReportFile -Value $reportContent

Write-Host "  ✅ Saved validation report: $ReportFile" -ForegroundColor Green
Write-Host ""

# ── Compile final deliverable ────────────────────────────────────────────────
$designContent = if ($phase1Ok) { Get-Content $designFile -Raw } else { "_(Phase 1 not completed)_" }
$codingContent = if ($phase2Ok) { Get-Content $codingFile -Raw } else { "_(Phase 2 not completed)_" }
$testContent = if ($phase3Ok) { Get-Content $testFile -Raw } else { "_(Phase 3 not completed)_" }
$debtContent = if (Test-Path $debtFile) { Get-Content $debtFile -Raw } else { "_(No design debts logged)_" }

$finalContent = @"
# DEVELOPER-FINAL: Complete Design & Implementation Specification

**Compiled:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')
**Status:** $status
**Sign-Off:** $statusSymbol

This document consolidates all four phases of the Developer workflow:
detailed design, coding standards, unit test strategy, and validation.
It is the complete blueprint for implementation.

---

## 1. Detailed Design

$designContent

---

## 2. Coding Standards & Implementation Plan

$codingContent

---

## 3. Unit Test Strategy

$testContent

---

## 4. Design & Code Quality Validation

### Status: $status

**All Phases Completed:** $($allPhases ? 'Yes ✓' : 'No ✗')

**Blocking Design Debts:** $blockingDDebts

**Manual Validation Passed:** $($allManual ? 'Yes ✓' : 'Partial or No')

---

## 5. Design Debts Register

$debtContent

---

## Sign-Off Block

| Item | Status |
|---|---|
| Design phases complete | $($allPhases ? '✓' : '✗') |
| No blocking debts | $($blockingDDebts -eq 0 ? '✓' : '✗') |
| Manual validation passed | $($allManual ? '✓' : '✗') |
| **Ready for implementation** | $statusSymbol |

---

## Next Steps

$($status -eq 'READY FOR CODE' ? @"
1. Distribute this specification to all team members
2. Assign module owners and start implementation
3. Begin with Phase 1 modules and work through dependency graph
4. Follow coding standards (Phase 2) and test strategy (Phase 3)
5. Track design debt items and schedule resolutions
"@ : $status -eq 'READY WITH CAVEATS' ? @"
1. Review open DDEBTs and assign owners
2. Set target dates for DDEBT resolution
3. Begin implementation with awareness of known gaps
4. Resolve DDEBTs as they are encountered
"@ : @"
1. Review blocking items and gaps
2. Resolve before proceeding to implementation
3. Re-run validation once issues are addressed
"@)

"@

Set-Content -Path $FinalFile -Value $finalContent

Write-Host "  ✅ Saved final deliverable: $FinalFile" -ForegroundColor Green
Write-Host ""

Write-DEV-SuccessRule "✅ Design & Code Quality Validation Complete"
Write-Host "  Status: $status" -ForegroundColor $statusColor
Write-Host "  Report:  $ReportFile" -ForegroundColor Green
Write-Host "  Final:   $FinalFile" -ForegroundColor Green
Write-Host ""
