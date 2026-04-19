#Requires -Version 5.1
param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:TA_AUTO = '1' }
if ($Answers) { $env:TA_ANSWERS = $Answers }


Write-TA-Banner "Phase 5: Test Environment Planning"

$OutputFile = Join-Path $script:TAOutputDir "05-environment-plan.md"

Write-Host "$($script:TAColours.Cyan)`nQuestion 1/6: Environments Needed$($script:TAColours.NC)"
$envs = Ask-TA-Text "Which environments? (e.g. Dev, QA, Staging, Production):"
if ([string]::IsNullOrWhiteSpace($envs)) { $envs = "Dev, QA, Staging" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 2/6: Data Requirements$($script:TAColours.NC)"
$dataReq = Ask-TA-Text "Data volume per environment? (e.g. Dev: 10 users, QA: 100 users, Staging: 10k users):"
if ([string]::IsNullOrWhiteSpace($dataReq)) { $dataReq = "Dev: small, QA: medium, Staging: large" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 3/6: Infrastructure Needs$($script:TAColours.NC)"
$infra = Ask-TA-Text "What infrastructure is needed? (e.g. VMs, databases, mocks, device farm):"
if ([string]::IsNullOrWhiteSpace($infra)) { $infra = "Virtual machines, PostgreSQL, service mocks" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 4/6: Test Data Masking$($script:TAColours.NC)"
$masking = Ask-TA-Choice "How will you handle PII?" `
  "Production replica (masked PII)" `
  "Synthetic generation (no real data)" `
  "Hybrid (some masked, some synthetic)"

Write-Host "$($script:TAColours.Cyan)`nQuestion 5/6: Refresh Frequency$($script:TAColours.NC)"
$refresh = Ask-TA-Text "How often to refresh test environments? (e.g. nightly, weekly, on-demand):"
if ([string]::IsNullOrWhiteSpace($refresh)) { $refresh = "Nightly" }

Write-Host "$($script:TAColours.Cyan)`nQuestion 6/6: Access Control$($script:TAColours.NC)"
$access = Ask-TA-Text "How will test credentials be secured? (e.g. Vault, GitHub Secrets, environment variables):"
if ([string]::IsNullOrWhiteSpace($access)) { $access = "Environment variables, secrets manager" }

Write-Host "`n"
Write-TA-SuccessRule "Generating test environment plan..."

$content = @"
# 5. Test Environment Plan

**Project:** TBD
**Version:** 1.0
**Date:** $(Get-Date -AsUTC -Format 'yyyy-MM-dd')

## 5.1 Environments Needed

$envs

## 5.2 Data Requirements

$dataReq

## 5.3 Infrastructure & Services

$infra

## 5.4 Test Data Masking

Approach: $masking

## 5.5 Environment Refresh Frequency

$refresh

## 5.6 Access Control & Security

$access

"@

Set-Content -Path $OutputFile -Value $content
Write-Host "$($script:TAColours.Green)✓$($script:TAColours.NC) Output saved to: $OutputFile"

Write-TA-SuccessRule "Phase 5 Complete: Test Environment Plan"
