# strategy.ps1 — Phase 1: Test Strategy Design
#Requires -Version 5.1

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:TA_AUTO = '1' }
if ($Answers) { $env:TA_ANSWERS = $Answers }


Write-TA-Banner "Phase 1: Test Strategy Design"

$OutputFile = Join-Path $script:TAOutputDir "01-test-strategy.md"

# Check for upstream BA output
$BAFinal = Join-Path $script:TABAInputDir "REQUIREMENTS-FINAL.md"
if (Test-Path $BAFinal) {
  Write-TA-Dim "✓ Found BA output at $BAFinal"
  Write-TA-Dim "  Reading requirements..."
}

# Initialize debt file if not present
if (-not (Test-Path $script:TADebtFile)) {
  $debtHeader = @"
# Test Architecture Debt Register

**Project:** TBD
**Version:** 1.0
**Last Updated:** $(Get-Date -AsUTC -Format 'yyyy-MM-dd')

"@
  Set-Content -Path $script:TADebtFile -Value $debtHeader
}

# Q1: Test Approach
Write-Host "$($script:TAColours.Cyan)`nQuestion 1/8: Test Approach$($script:TAColours.NC)"
Write-TA-Dim "What testing methodology will guide decisions?"
$testApproach = Ask-TA-Choice "Choose test approach:" `
  "Risk-based (focus on high-risk areas)" `
  "Requirement-based (cover all specified requirements)" `
  "Exploratory (ad-hoc testing with skilled testers)" `
  "Hybrid (combination of the above)"

# Q2: Test Levels
Write-Host "$($script:TAColours.Cyan)`nQuestion 2/8: Test Levels$($script:TAColours.NC)"
Write-TA-Dim "Which test levels are in scope? (comma-separated from: Unit, Integration, System, E2E, UAT)"
$testLevels = Ask-TA-Text "Enter test levels in scope:"
if ([string]::IsNullOrWhiteSpace($testLevels)) {
  $testLevels = "Unit, Integration, System, E2E"
  Write-TA-Dim "Using default: $testLevels"
}

# Q3: Test Types
Write-Host "$($script:TAColours.Cyan)`nQuestion 3/8: Test Types$($script:TAColours.NC)"
Write-TA-Dim "Which test types are required? (comma-separated from: Functional, Performance, Security, Accessibility, Compatibility, Usability)"
$testTypes = Ask-TA-Text "Enter test types in scope:"
if ([string]::IsNullOrWhiteSpace($testTypes)) {
  $testTypes = "Functional, Performance, Security"
  Write-TA-Dim "Using default: $testTypes"
}

# Q4: Automation Ratio
Write-Host "$($script:TAColours.Cyan)`nQuestion 4/8: Automation vs Manual Ratio$($script:TAColours.NC)"
Write-TA-Dim "Target split (e.g. 80 for 80% automated, 20% manual)"
$automationRatio = Ask-TA-Text "Enter automation % target:"
if ([string]::IsNullOrWhiteSpace($automationRatio)) {
  $automationRatio = "80"
  Write-TA-Dim "Using default: 80%"
}

# Q5: Test Data Management
Write-Host "$($script:TAColours.Cyan)`nQuestion 5/8: Test Data Management$($script:TAColours.NC)"
$testData = Ask-TA-Choice "How will you manage test data?" `
  "Production replica (masked PII)" `
  "Synthetic generation (factories, faker libraries)" `
  "Embedded fixtures (git-versioned data sets)" `
  "On-the-fly creation (API factories during test run)"

# Q6: Defect Management Process
Write-Host "$($script:TAColours.Cyan)`nQuestion 6/8: Defect Management$($script:TAColours.NC)"
$defectTool = Ask-TA-Text "What tool will you use for defect tracking? (e.g. Jira, GitHub Issues, Azure DevOps)"
if ([string]::IsNullOrWhiteSpace($defectTool)) {
  $defectTool = "TBD"
  Write-TA-Dim "Will determine later"
}

# Q7: Test Metrics
Write-Host "$($script:TAColours.Cyan)`nQuestion 7/8: Test Metrics & KPIs$($script:TAColours.NC)"
Write-TA-Dim "Which KPIs matter most? (comma-separated from: Code Coverage %, Requirements Coverage %, Defect Escape Rate, Test Execution Time, Defect Density)"
$testMetrics = Ask-TA-Text "Enter key metrics:"
if ([string]::IsNullOrWhiteSpace($testMetrics)) {
  $testMetrics = "Code Coverage %, Requirements Coverage %, Defect Escape Rate"
  Write-TA-Dim "Using default: $testMetrics"
}

# Q8: Test Exit Criteria
Write-Host "$($script:TAColours.Cyan)`nQuestion 8/8: Test Exit Criteria$($script:TAColours.NC)"
Write-TA-Dim "When is testing done? (comma-separated from: All critical requirements tested, Code coverage threshold met, Zero critical defects, Smoke tests passed, UAT sign-off)"
$exitCriteria = Ask-TA-Text "Enter test exit criteria:"
if ([string]::IsNullOrWhiteSpace($exitCriteria)) {
  $exitCriteria = "All critical requirements tested, Code coverage threshold met, Zero critical defects, UAT sign-off"
  Write-TA-Dim "Using default"
}

# Generate output
Write-Host "`n"
Write-TA-SuccessRule "Generating test strategy document..."

$content = @"
# 1. Test Strategy

**Project:** TBD
**Version:** 1.0
**Date:** $(Get-Date -AsUTC -Format 'yyyy-MM-dd')
**Owner:** TBD

## Overview

This test strategy outlines the overall testing approach for the project.

## 1.1 Test Approach

We will use **$testApproach** testing.

## 1.2 Test Levels & Scope

In scope: $testLevels

## 1.3 Test Types

Test types: $testTypes

## 1.4 Automation vs. Manual Ratio

Target: $automationRatio% automated, $([100 - [int]$automationRatio])% manual

## 1.5 Test Data Management

Approach: $testData

## 1.6 Defect Management

Tool: $defectTool

## 1.7 Test Metrics & KPIs

Metrics: $testMetrics

## 1.8 Test Exit Criteria

Criteria: $exitCriteria

"@

Set-Content -Path $OutputFile -Value $content
Write-Host "$($script:TAColours.Green)✓$($script:TAColours.NC) Output saved to: $OutputFile"

Write-TA-SuccessRule "Phase 1 Complete: Test Strategy"
