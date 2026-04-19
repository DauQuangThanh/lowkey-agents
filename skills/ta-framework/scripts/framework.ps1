# framework.ps1 — Phase 2: Test Automation Framework Design
#Requires -Version 5.1

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:TA_AUTO = '1' }
if ($Answers) { $env:TA_ANSWERS = $Answers }


Write-TA-Banner "Phase 2: Test Automation Framework Design"

$OutputFile = Join-Path $script:TAOutputDir "02-automation-framework.md"

# Q1: Tech Stack
Write-Host "$($script:TAColours.Cyan)`nQuestion 1/8: Tech Stack$($script:TAColours.NC)"
Write-TA-Dim "What is the frontend framework (React, Vue, Angular, Svelte, server-rendered)?"
$frontendFw = Ask-TA-Text "Enter frontend framework:"
if ([string]::IsNullOrWhiteSpace($frontendFw)) { $frontendFw = "TBD" }

Write-TA-Dim "What is the backend language and framework?"
$backendStack = Ask-TA-Text "Enter backend language/framework:"
if ([string]::IsNullOrWhiteSpace($backendStack)) { $backendStack = "TBD" }

# Q2: Automation Tool Selection
Write-Host "$($script:TAColours.Cyan)`nQuestion 2/8: Automation Tool Selection$($script:TAColours.NC)"
Write-TA-Dim "What will you use for UI/E2E testing?"
$uiTool = Ask-TA-Choice "Choose UI/E2E automation tool:" `
  "Playwright (multi-browser, fast)" `
  "Cypress (single-browser, excellent DX)" `
  "Selenium (mature, cross-browser)" `
  "Other (specify)"
if ($uiTool -eq "Other (specify)") {
  $uiTool = Ask-TA-Text "Enter tool name:"
}

Write-TA-Dim "What will you use for API testing?"
$apiTool = Ask-TA-Choice "Choose API testing tool:" `
  "Postman + Newman (user-friendly, CI-friendly)" `
  "REST Assured (powerful, Java-based)" `
  "Karate (API+performance, open-source)" `
  "Other (specify)"
if ($apiTool -eq "Other (specify)") {
  $apiTool = Ask-TA-Text "Enter tool name:"
}

# Q3: Framework Pattern
Write-Host "$($script:TAColours.Cyan)`nQuestion 3/8: Framework Pattern$($script:TAColours.NC)"
$frameworkPattern = Ask-TA-Choice "Choose framework pattern:" `
  "Page Object Model (POM - maintainable)" `
  "Screenplay Pattern (OOP, readable)" `
  "Keyword-Driven (low-code)" `
  "BDD (Gherkin - Given/When/Then)" `
  "Hybrid (combination)"

# Q4: Test Runner & Framework
Write-Host "$($script:TAColours.Cyan)`nQuestion 4/8: Test Runner & Framework$($script:TAColours.NC)"
$testRunner = Ask-TA-Text "What test runner/framework? (e.g. Jest, JUnit, Pytest, Mocha)"
if ([string]::IsNullOrWhiteSpace($testRunner)) { $testRunner = "TBD" }

# Q5: Reporting & Observability
Write-Host "$($script:TAColours.Cyan)`nQuestion 5/8: Reporting & Observability$($script:TAColours.NC)"
Write-TA-Dim "Where will test reports be generated?"
$reporting = Ask-TA-Text "Enter reporting tool/approach (e.g. HTML, Allure, ReportPortal):"
if ([string]::IsNullOrWhiteSpace($reporting)) { $reporting = "HTML reports" }

# Q6: CI/CD Integration
Write-Host "$($script:TAColours.Cyan)`nQuestion 6/8: CI/CD Integration$($script:TAColours.NC)"
$cicdTool = Ask-TA-Text "What CI/CD platform? (e.g. GitHub Actions, GitLab CI, Azure DevOps, Jenkins)"
if ([string]::IsNullOrWhiteSpace($cicdTool)) { $cicdTool = "TBD" }

Write-TA-Dim "When should tests be triggered?"
$cicdTrigger = Ask-TA-Choice "Choose CI/CD trigger:" `
  "On every commit/PR (fast feedback)" `
  "On merge to develop (gated promotion)" `
  "Scheduled nightly (slower, comprehensive)" `
  "Manual + scheduled (flexible)"

# Q7: Parallel Execution Strategy
Write-Host "$($script:TAColours.Cyan)`nQuestion 7/8: Parallel Execution Strategy$($script:TAColours.NC)"
Write-TA-Dim "How many test workers/browsers in parallel?"
$parallelWorkers = Ask-TA-Text "Enter number of parallel workers (default 4):"
if ([string]::IsNullOrWhiteSpace($parallelWorkers)) { $parallelWorkers = "4" }

# Q8: Test Environment Requirements
Write-Host "$($script:TAColours.Cyan)`nQuestion 8/8: Test Environment Requirements$($script:TAColours.NC)"
Write-TA-Dim "What browsers to test? (comma-separated: Chrome, Firefox, Safari, Edge)"
$browsers = Ask-TA-Text "Enter browsers:"
if ([string]::IsNullOrWhiteSpace($browsers)) { $browsers = "Chrome (latest), Firefox (latest)" }

# Generate output
Write-Host "`n"
Write-TA-SuccessRule "Generating test automation framework document..."

$content = @"
# 2. Test Automation Framework Design

**Project:** TBD
**Version:** 1.0
**Date:** $(Get-Date -AsUTC -Format 'yyyy-MM-dd')
**Owner:** TBD

## 2.1 Tech Stack Summary

| Component | Technology |
|-----------|---|
| Frontend | $frontendFw |
| Backend | $backendStack |

## 2.2 Automation Tool Selection

UI/E2E Testing: **$uiTool**

API Testing: **$apiTool**

## 2.3 Framework Pattern

Chosen: **$frameworkPattern**

## 2.4 Test Runner & Framework

Runner: $testRunner

## 2.5 Reporting & Observability

Tool: $reporting

## 2.6 CI/CD Integration

Platform: $cicdTool
Trigger: $cicdTrigger

## 2.7 Parallel Execution Strategy

Workers: $parallelWorkers

## 2.8 Test Environment Requirements

Browsers: $browsers

"@

Set-Content -Path $OutputFile -Value $content
Write-Host "$($script:TAColours.Green)✓$($script:TAColours.NC) Output saved to: $OutputFile"

Write-TA-SuccessRule "Phase 2 Complete: Test Automation Framework"
