# OPS Skill: ops-environment (Phase 6)
# Environment Management Design

param()

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:OPS_AUTO = '1' }
if ($Answers) { $env:OPS_ANSWERS = $Answers }


$outputFile = Join-Path $script:OPSOutputDir "06-environment-plan.md"

Write-OPS-Banner "Phase 6: Environment Management Design"

Ask-OPS-Choice "How many environments?" "dev + staging + prod (3)", "dev + qa + staging + prod (4)", "dev + qa + staging + pre-prod + prod (5)", "Custom" | Out-Null

$content = @"
# Phase 6: Environment Management Design

## Status

This is a placeholder. Full implementation includes:

1. **Environment Definitions** - dev, QA, staging, pre-prod, prod
2. **Environment Parity** - Identical, right-sized, custom
3. **Configuration Management** - Env vars, config files, config server, ConfigMap
4. **Access Control** - Role-based (developer/QA/ops/admin)
5. **Data Management** - Seeding, masking, refresh cadence
6. **Environment Provisioning** - Fully automated, semi-automated, manual

## Environment Matrix

| Name | Purpose | Replicas | CPU | Memory | Access |
|------|---------|----------|-----|--------|--------|
| dev | Developer testing | 1 | 0.5 | 512Mi | All engineers |
| qa | QA testing | 1 | 1 | 1Gi | QA + engineers |
| staging | Production-like | 2 | 1 | 2Gi | QA + ops + PM |
| prod | Live traffic | 3+ | 2+ | 4Gi+ | Ops + on-call |

## Next Steps

Run the full skill for complete environment management design.

"@

$content | Set-Content $outputFile

Write-OPS-SuccessRule "Environment plan placeholder written to $outputFile"
Write-Host ""
Write-Host "All phases complete. Run ops-workflow to compile final handbook."
Write-Host ""
