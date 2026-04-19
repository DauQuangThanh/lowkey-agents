#Requires -Version 5.1
param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:TA_AUTO = '1' }
if ($Answers) { $env:TA_ANSWERS = $Answers }


Write-TA-Banner "Phase 3: Test Coverage Analysis"

$OutputFile = Join-Path $script:TAOutputDir "03-coverage-matrix.md"

Write-Host "$($script:TAColours.Cyan)`nQuestion 1/6: Requirements to Cover$($script:TAColours.NC)"
$requirements = Ask-TA-Text "Describe requirements to cover (functional, non-functional, user stories):"
if ([string]::IsNullOrWhiteSpace($requirements)) { $requirements = "TBD" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 2/6: Coverage Target %$($script:TAColours.NC)"
$coverageTarget = Ask-TA-Text "Enter code coverage % target (default 80):"
if ([string]::IsNullOrWhiteSpace($coverageTarget)) { $coverageTarget = "80" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 3/6: Traceability Approach$($script:TAColours.NC)"
$traceability = Ask-TA-Choice "How will you map requirements to test cases?" `
  "Spreadsheet/Matrix (requirement ID → test case IDs)" `
  "Test management tool (TestRail, Zephyr)" `
  "Git-versioned traceability matrix (CSV/markdown)" `
  "Code-embedded via comments/annotations"

Write-Host "$($script:TAColours.Cyan)`nQuestion 4/6: Risk-Based Prioritization$($script:TAColours.NC)"
$riskAreas = Ask-TA-Text "List high-risk areas requiring 100% coverage:"
if ([string]::IsNullOrWhiteSpace($riskAreas)) { $riskAreas = "Critical business flows, high-complexity components" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 5/6: Coverage Metrics$($script:TAColours.NC)"
$metrics = Ask-TA-Text "Which metrics to track (comma-separated: Statement, Branch, Requirement, Feature, User Journey):"
if ([string]::IsNullOrWhiteSpace($metrics)) { $metrics = "Statement, Branch, Requirement" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 6/6: Gap Analysis$($script:TAColours.NC)"
$gaps = Ask-TA-Text "Identify under-tested areas:"
if ([string]::IsNullOrWhiteSpace($gaps)) { $gaps = "TBD" }

Write-Host "`n"
Write-TA-SuccessRule "Generating test coverage matrix..."

$content = @"
# 3. Test Coverage Analysis

**Project:** TBD
**Version:** 1.0
**Date:** $(Get-Date -AsUTC -Format 'yyyy-MM-dd')

## 3.1 Requirements to Cover

$requirements

## 3.2 Coverage Target

Target: $coverageTarget% code coverage

## 3.3 Traceability Approach

Approach: $traceability

## 3.4 Risk-Based Prioritization

High-risk areas: $riskAreas

## 3.5 Coverage Metrics

Metrics: $metrics

## 3.6 Gap Analysis

Under-tested areas: $gaps

"@

Set-Content -Path $OutputFile -Value $content
Write-Host "$($script:TAColours.Green)✓$($script:TAColours.NC) Output saved to: $OutputFile"

Write-TA-SuccessRule "Phase 3 Complete: Test Coverage Analysis"
