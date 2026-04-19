#Requires -Version 5.1
# =============================================================================
# run-all.ps1 — Code Quality Reviewer Workflow Orchestrator (PowerShell)
#
# Purpose:
#   Runs all 4 phases of the code quality review sequentially:
#   Phase 1: Standards Review
#   Phase 2: Complexity Analysis
#   Phase 3: Pattern & Architecture Review
#   Phase 4: Quality Report & Recommendations
#
# Usage:
#   pwsh <SKILL_DIR>/cqr-workflow/scripts/run-all.ps1
#
# Output:
#   cqr-output/01-standards-review.md
#   cqr-output/02-complexity-report.md
#   cqr-output/03-patterns-review.md
#   cqr-output/04-quality-report.md
#   cqr-output/05-cq-debts.md
#   cqr-output/CQR-FINAL.md
#
# =============================================================================

param([switch]$Auto, [string]$Answers = "")



# Step 1: accept --auto / --answers
if ($Auto) { $env:CQR_AUTO = '1' }
if ($Answers) { $env:CQR_ANSWERS = $Answers }
if (Get-Command Invoke-CQR-ParseFlags -ErrorAction SilentlyContinue) { Invoke-CQR-ParseFlags -Args $args }

$ErrorActionPreference = 'Stop'

# Resolve script paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptDir))

# Phase script locations
$standardsScript = "$projectRoot\cqr-standards\scripts\standards.ps1"
$complexityScript = "$projectRoot\cqr-complexity\scripts\complexity.ps1"
$patternsScript = "$projectRoot\cqr-patterns\scripts\patterns.ps1"
$reportScript = "$projectRoot\cqr-report\scripts\report.ps1"

# Source common helpers
. "$projectRoot\cqr-standards\scripts\_common.ps1"

# =============================================================================
# VALIDATION
# =============================================================================

Write-CQR-Banner "Code Quality Reviewer — Complete Workflow"

Write-Host @"

This workflow will guide you through a comprehensive code quality review:

  Phase 1: Coding Standards Review (8 questions)
  Phase 2: Complexity & Maintainability Analysis (6 questions)
  Phase 3: Design Pattern & Architecture Review (6 questions)
  Phase 4: Quality Report & Recommendations (automated)

Estimated time: 20–30 minutes

"@

# Verify all phase scripts exist
$scripts = @($standardsScript, $complexityScript, $patternsScript, $reportScript)
foreach ($script in $scripts) {
  if (-not (Test-Path -Path $script -PathType Leaf)) {
    Write-Host "$($script:CQRRed)ERROR: Phase script not found: $script$($script:CQRNc)"
    exit 1
  }
}

Write-Host "$($script:CQRGreen)✓ All phase scripts found$($script:CQRNc)`n"

# =============================================================================
# PHASE 1: STANDARDS REVIEW
# =============================================================================

Write-Host "$($script:CQRBold)Running Phase 1 (Standards Review)...$($script:CQRNc)`n"
& $standardsScript

# =============================================================================
# PHASE 2: COMPLEXITY ANALYSIS
# =============================================================================

Write-Host "`n$($script:CQRBold)Running Phase 2 (Complexity Analysis)...$($script:CQRNc)`n"
& $complexityScript

# =============================================================================
# PHASE 3: PATTERN & ARCHITECTURE REVIEW
# =============================================================================

Write-Host "`n$($script:CQRBold)Running Phase 3 (Pattern & Architecture Review)...$($script:CQRNc)`n"
& $patternsScript

# =============================================================================
# PHASE 4: QUALITY REPORT
# =============================================================================

Write-Host "`n$($script:CQRBold)Running Phase 4 (Quality Report & Recommendations)...$($script:CQRNc)`n"
& $reportScript

# =============================================================================
# COMPLETION
# =============================================================================

Write-CQR-Banner "Code Quality Review Complete"

Write-Host @"

All output files have been written to: $script:CQROutputDir

Main Reports:
  * 01-standards-review.md  — Coding standards baseline and findings
  * 02-complexity-report.md — Complexity metrics and hotspots
  * 03-patterns-review.md   — SOLID audit and pattern compliance
  * 04-quality-report.md    — Detailed findings by severity
  * CQR-FINAL.md            — Executive summary and recommendations
  * 05-cq-debts.md          — Technical debt registry

Next Steps:
  1. Review CQR-FINAL.md for executive summary
  2. Review 04-quality-report.md for detailed findings
  3. Use the top 10 priority actions to plan refactoring sprints
  4. Track CQDEBT-NN entries in your backlog

Quality Improvement Roadmap:
  Week 1: Fix critical issues (security, stability)
  Week 2: Begin major refactoring (complexity, SOLID violations)
  Week 3: Complete refactoring and add documentation
  Week 4: Validation and follow-up analysis

---

"@

Write-Host "$($script:CQRGreen)✅ Workflow complete!$($script:CQRNc)`n"
