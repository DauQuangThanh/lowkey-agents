# OPS Orchestrator: ops-workflow (Phase 0)
# Run all phases 1-6 and compile final handbook

param([switch]$Auto, [string]$Answers = "")

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "_common.ps1")


# Step 1: accept --auto / --answers
if ($Auto) { $env:OPS_AUTO = '1' }
if ($Answers) { $env:OPS_ANSWERS = $Answers }
if (Get-Command Invoke-OPS-ParseFlags -ErrorAction SilentlyContinue) { Invoke-OPS-ParseFlags -Args $args }

$finalOutput = Join-Path $script:OPSOutputDir "OPS-FINAL.md"
$skillsBase = Split-Path -Parent (Split-Path -Parent $scriptDir)

Write-OPS-Banner "DevOps Orchestrator: Full Workflow"

Write-Host -ForegroundColor Cyan "Welcome to the DevOps Orchestration Workflow!"
Write-Host ""
Write-Host "This workflow will guide you through designing a complete DevOps strategy:"
Write-Host "  Phase 1: CI/CD Pipeline Design"
Write-Host "  Phase 2: Infrastructure as Code"
Write-Host "  Phase 3: Containerization & Orchestration"
Write-Host "  Phase 4: Monitoring & Observability"
Write-Host "  Phase 5: Deployment Strategy"
Write-Host "  Phase 6: Environment Management"
Write-Host ""
Write-Host "Total time: ~60-90 minutes (15 min per phase)"
Write-Host ""

if (-not (Ask-OPS-YN "Ready to start the full workflow?")) {
    Write-Host "Exiting. You can run individual skills later."
    exit 0
}

# Phase 1: CI/CD
Write-Host ""
if (Ask-OPS-YN "Run Phase 1: CI/CD Pipeline Design?") {
    Write-Host "Launching ops-cicd..."
    & (Join-Path $skillsBase "ops-cicd/scripts/cicd.ps1") 2>&1 | Out-Null
} else {
    Write-Host "Skipped Phase 1"
}

# Phase 2: Infrastructure
Write-Host ""
if (Ask-OPS-YN "Run Phase 2: Infrastructure as Code?") {
    Write-Host "Launching ops-infrastructure..."
    & (Join-Path $skillsBase "ops-infrastructure/scripts/infrastructure.ps1") 2>&1 | Out-Null
} else {
    Write-Host "Skipped Phase 2"
}

# Phase 3: Containerization
Write-Host ""
if (Ask-OPS-YN "Run Phase 3: Containerization & Orchestration?") {
    Write-Host "Launching ops-containerization..."
    & (Join-Path $skillsBase "ops-containerization/scripts/containerization.ps1") 2>&1 | Out-Null
} else {
    Write-Host "Skipped Phase 3"
}

# Phase 4: Monitoring
Write-Host ""
if (Ask-OPS-YN "Run Phase 4: Monitoring & Observability?") {
    Write-Host "Launching ops-monitoring..."
    & (Join-Path $skillsBase "ops-monitoring/scripts/monitoring.ps1") 2>&1 | Out-Null
} else {
    Write-Host "Skipped Phase 4"
}

# Phase 5: Deployment
Write-Host ""
if (Ask-OPS-YN "Run Phase 5: Deployment Strategy?") {
    Write-Host "Launching ops-deployment..."
    & (Join-Path $skillsBase "ops-deployment/scripts/deployment.ps1") 2>&1 | Out-Null
} else {
    Write-Host "Skipped Phase 5"
}

# Phase 6: Environment
Write-Host ""
if (Ask-OPS-YN "Run Phase 6: Environment Management?") {
    Write-Host "Launching ops-environment..."
    & (Join-Path $skillsBase "ops-environment/scripts/environment.ps1") 2>&1 | Out-Null
} else {
    Write-Host "Skipped Phase 6"
}

# Compile final output
Write-OPS-Banner "Compiling Final DevOps Handbook"

$finalContent = @"
# OPS-FINAL: Complete DevOps Strategy Handbook

**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm UTC')

## Executive Summary

This comprehensive DevOps handbook consolidates all design decisions across six operational phases.

---

## Phase Outputs

"@

$phases = @(
    "01-cicd-pipeline",
    "02-infrastructure",
    "03-containerization",
    "04-monitoring",
    "05-deployment-strategy",
    "06-environment-plan"
)

foreach ($phase in $phases) {
    $phaseFile = Join-Path $script:OPSOutputDir "$phase.md"
    if (Test-Path $phaseFile) {
        $phaseName = $phase -replace "-", " " -replace "^\d+-", ""
        $finalContent += "`n### Phase: $phaseName`n`n"
        $finalContent += "``````n"
        $content = Get-Content $phaseFile -TotalCount 20
        $content | ForEach-Object { $finalContent += "  $_`n" }
        $finalContent += "``````n`n"
        $finalContent += "[See full details in $phase.md]`n"
    }
}

$finalContent += @"

---

## OPS Debt Tracker

"@

if (Test-Path $script:OPSDebtFile) {
    $finalContent += "### Tracked Debt Items`n`n"
    $debtContent = Get-Content $script:OPSDebtFile -Raw
    $finalContent += $debtContent
} else {
    $finalContent += "No debt items tracked yet.`n"
}

$finalContent += @"

---

## Implementation Roadmap

### Immediate (Week 1)
- [ ] Set up CI/CD pipeline repository
- [ ] Configure artifact storage
- [ ] Create deployment scripts

### Short-term (Month 1)
- [ ] Implement Infrastructure-as-Code
- [ ] Set up containerization (if applicable)
- [ ] Configure monitoring and alerting

### Medium-term (Month 3)
- [ ] Implement deployment strategy
- [ ] Set up multi-environment management
- [ ] Establish on-call rotation

### Long-term (Quarter 2+)
- [ ] Optimize DORA metrics
- [ ] Implement disaster recovery
- [ ] Continuous improvement and debt paydown

---

## Quick Reference

### Key Files
- \`01-cicd-pipeline.md\` - CI/CD architecture
- \`02-infrastructure.md\` - IaC strategy
- \`03-containerization.md\` - Container orchestration
- \`04-monitoring.md\` - Observability setup
- \`05-deployment-strategy.md\` - Deployment patterns
- \`06-environment-plan.md\` - Environment management
- \`07-ops-debts.md\` - Debt tracker

### Commands
- Run single phase: \`.\scripts\[phase].ps1\`
- View debt: \`Get-Content 07-ops-debts.md\`

---

**Status**: Handbook compiled and ready for implementation.
**Next**: Share this handbook with your team and start Phase 1 implementation.
"@

$finalContent | Set-Content $finalOutput

Write-OPS-SuccessRule "Final handbook compiled: $finalOutput"

Write-Host ""
Write-Host "Summary:"
Write-Host "  Output directory: $script:OPSOutputDir"
Write-Host "  Final handbook: $finalOutput"
Write-Host "  Debt tracker: $script:OPSDebtFile"
Write-Host ""
Write-Host "Next: Review $finalOutput and begin implementation."
Write-Host ""
