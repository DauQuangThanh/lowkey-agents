#Requires -Version 5.1
param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:TA_AUTO = '1' }
if ($Answers) { $env:TA_ANSWERS = $Answers }


Write-TA-Banner "Phase 4: Quality Gate Definitions"

$OutputFile = Join-Path $script:TAOutputDir "04-quality-gates.md"

Write-Host "$($script:TAColours.Cyan)`nQuestion 1/6: Gate Checkpoints$($script:TAColours.NC)"
$checkpoints = Ask-TA-Text "When do gates apply? (e.g. per-commit, per-sprint, pre-release):"
if ([string]::IsNullOrWhiteSpace($checkpoints)) { $checkpoints = "Per-commit, Per-release" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 2/6: Pass/Fail Criteria$($script:TAColours.NC)"
$criteria = Ask-TA-Text "What must pass? (e.g. tests pass, coverage threshold, zero critical defects):"
if ([string]::IsNullOrWhiteSpace($criteria)) { $criteria = "All tests pass, coverage >= 80%, zero critical defects" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 3/6: Code Coverage Threshold$($script:TAColours.NC)"
$coverageUnit = Ask-TA-Text "Unit test coverage % target (default 90):"
if ([string]::IsNullOrWhiteSpace($coverageUnit)) { $coverageUnit = "90" }
$coverageIntegration = Ask-TA-Text "Integration test coverage % target (default 60):"
if ([string]::IsNullOrWhiteSpace($coverageIntegration)) { $coverageIntegration = "60" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 4/6: Performance Benchmarks$($script:TAColours.NC)"
$perf = Ask-TA-Text "Enter performance SLAs (e.g. API p95 < 200ms, page load < 3s):"
if ([string]::IsNullOrWhiteSpace($perf)) { $perf = "TBD" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 5/6: Security Scan Requirements$($script:TAColours.NC)"
$security = Ask-TA-Text "Which scans required? (e.g. SAST, DAST, dependency scanning, OWASP):"
if ([string]::IsNullOrWhiteSpace($security)) { $security = "SAST, dependency scanning" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 6/6: Manual Approval Gates$($script:TAColours.NC)"
$approvals = Ask-TA-Text "Which gates require manual approval? (e.g. security, release, UAT):"
if ([string]::IsNullOrWhiteSpace($approvals)) { $approvals = "Release, UAT" }

Write-Host "`n"
Write-TA-SuccessRule "Generating quality gate definitions..."

$content = @"
# 4. Quality Gate Definitions

**Project:** TBD
**Version:** 1.0
**Date:** $(Get-Date -AsUTC -Format 'yyyy-MM-dd')

## 4.1 Gate Checkpoints

$checkpoints

## 4.2 Pass/Fail Criteria

$criteria

## 4.3 Code Coverage Thresholds

- Unit tests: $coverageUnit%
- Integration tests: $coverageIntegration%

## 4.4 Performance Benchmarks

$perf

## 4.5 Security Scan Requirements

$security

## 4.6 Manual Approval Gates

$approvals

"@

Set-Content -Path $OutputFile -Value $content
Write-Host "$($script:TAColours.Green)✓$($script:TAColours.NC) Output saved to: $OutputFile"

Write-TA-SuccessRule "Phase 4 Complete: Quality Gates"
