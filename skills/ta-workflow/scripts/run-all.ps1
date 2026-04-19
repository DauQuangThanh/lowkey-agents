# run-all.ps1 — Test Architect Workflow Orchestrator
#Requires -Version 5.1

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "_common.ps1")


# Step 1: accept --auto / --answers
if ($Auto) { $env:TA_AUTO = '1' }
if ($Answers) { $env:TA_ANSWERS = $Answers }
if (Get-Command Invoke-TA-ParseFlags -ErrorAction SilentlyContinue) { Invoke-TA-ParseFlags -Args $args }

Write-TA-Banner "Test Architect Workflow — All Phases"

# Check for upstream outputs
Write-Host "$($script:TAColours.Cyan)`nChecking for upstream outputs...$($script:TAColours.NC)"

$BAFinal = Join-Path $script:TABAInputDir "REQUIREMENTS-FINAL.md"
$ArchFinal = Join-Path $script:TAArchInputDir "ARCHITECTURE-FINAL.md"

if (Test-Path $BAFinal) {
  Write-TA-Dim "✓ Found BA output: $BAFinal"
}

if (Test-Path $ArchFinal) {
  Write-TA-Dim "✓ Found Architect output: $ArchFinal"
}

Write-Host "`n"

# Run Phase 1: Test Strategy
Write-Host "$($script:TAColours.Cyan)`nRunning Phase 1: Test Strategy Design$($script:TAColours.NC)"
Write-TA-Dim "This phase captures your overall test approach, levels, types, automation ratio, and exit criteria."
& (Join-Path $PSScriptRoot ".." ".." "ta-strategy" "scripts" "strategy.ps1") -ErrorAction Continue

Write-Host "`n"

# Run Phase 2: Test Framework
Write-Host "$($script:TAColours.Cyan)`nRunning Phase 2: Test Automation Framework Design$($script:TAColours.NC)"
Write-TA-Dim "This phase selects automation tools and designs your framework pattern."
& (Join-Path $PSScriptRoot ".." ".." "ta-framework" "scripts" "framework.ps1") -ErrorAction Continue

Write-Host "`n"

# Run Phase 3: Coverage
Write-Host "$($script:TAColours.Cyan)`nRunning Phase 3: Test Coverage Analysis$($script:TAColours.NC)"
Write-TA-Dim "This phase maps requirements to test cases and identifies gaps."
& (Join-Path $PSScriptRoot ".." ".." "ta-coverage" "scripts" "coverage.ps1") -ErrorAction Continue

Write-Host "`n"

# Run Phase 4: Quality Gates
Write-Host "$($script:TAColours.Cyan)`nRunning Phase 4: Quality Gate Definitions$($script:TAColours.NC)"
Write-TA-Dim "This phase defines quality checkpoints and pass/fail criteria."
& (Join-Path $PSScriptRoot ".." ".." "ta-quality-gates" "scripts" "quality-gates.ps1") -ErrorAction Continue

Write-Host "`n"

# Run Phase 5: Environments
Write-Host "$($script:TAColours.Cyan)`nRunning Phase 5: Test Environment Planning$($script:TAColours.NC)"
Write-TA-Dim "This phase plans your test infrastructure and data needs."
& (Join-Path $PSScriptRoot ".." ".." "ta-environment" "scripts" "environment.ps1") -ErrorAction Continue

Write-Host "`n"

# Compile final output
Write-TA-SuccessRule "Compiling final deliverable..."

$FinalFile = Join-Path $script:TAOutputDir "TA-FINAL.md"

$finalContent = @"
# Test Architecture — Final Deliverable

**Generated:** $(Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ')

## Executive Summary

This document consolidates the test architecture for your project.

---

"@

# Add each phase output
$phases = @(
  "01-test-strategy.md",
  "02-automation-framework.md",
  "03-coverage-matrix.md",
  "04-quality-gates.md",
  "05-environment-plan.md"
)

foreach ($phase in $phases) {
  $phaseFile = Join-Path $script:TAOutputDir $phase
  if (Test-Path $phaseFile) {
    $content = Get-Content -Path $phaseFile -Raw
    $finalContent += "`n$content`n---`n`n"
  }
}

$finalContent += @"
## Test Debt Register

"@

if (Test-Path $script:TADebtFile) {
  $debtContent = Get-Content -Path $script:TADebtFile -Raw
  $finalContent += $debtContent
} else {
  $finalContent += "No debts recorded.`n`n"
}

$finalContent += @"

## Sign-Off Block

**Approved by:**
- Test Lead: ________________  Date: __________
- Engineering Lead: ________________  Date: __________
- Product Owner: ________________  Date: __________

"@

Set-Content -Path $FinalFile -Value $finalContent

Write-Host "$($script:TAColours.Green)✓$($script:TAColours.NC) All phases complete! Output saved to:`n  $FinalFile"

Write-TA-SuccessRule "Test Architecture Workflow Complete"

Write-Host "$($script:TAColours.Cyan)`n"
Write-TA-Dim "Next steps:"
Write-TA-Dim "  1. Review all outputs in ta-output/"
Write-TA-Dim "  2. Address any TADEBTs in 06-ta-debts.md"
Write-TA-Dim "  3. Share TA-FINAL.md with stakeholders for sign-off"
Write-TA-Dim "  4. Hand over to developers and testers"
Write-Host "$($script:TAColours.NC)`n"
