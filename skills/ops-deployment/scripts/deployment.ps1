# OPS Skill: ops-deployment (Phase 5)
# Deployment Strategy Design

param()

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:OPS_AUTO = '1' }
if ($Answers) { $env:OPS_ANSWERS = $Answers }


$outputFile = Join-Path $script:OPSOutputDir "05-deployment-strategy.md"

Write-OPS-Banner "Phase 5: Deployment Strategy Design"

Ask-OPS-Choice "Deployment Pattern?" "Rolling (gradual replacement)", "Blue-green (parallel environments)", "Canary (traffic %-based)", "Recreate (with downtime)", "A-B testing" | Out-Null

$content = @"
# Phase 5: Deployment Strategy Design

## Status

This is a placeholder. Full implementation includes:

1. **Deployment Pattern** - Rolling, blue-green, canary, recreate, A-B
2. **Rollback Strategy** - Instant, gradual, database snapshot
3. **Database Migrations** - Expand-contract, zero-downtime, maintenance window
4. **Feature Flags** - LaunchDarkly, Unleash, custom, none
5. **Zero-Downtime Requirements** - 24/7, business hours, windows
6. **Deployment Window** - Continuous, scheduled, on-demand, weekly
7. **Smoke Test Strategy** - Synthetic, canary, manual, automated e2e
8. **Disaster Recovery** - RTO/RPO targets, backup frequency, failover

## Deployment Patterns

- **Rolling**: Gradual replacement, no downtime, slower
- **Blue-Green**: Parallel environments, instant cutover, 2x cost
- **Canary**: Production testing, detected issues early
- **Recreate**: Simple, downtime-based, risky

## Next Steps

Run the full skill for complete deployment strategy design.

"@

$content | Set-Content $outputFile

Write-OPS-SuccessRule "Deployment strategy placeholder written to $outputFile"
Write-Host ""
Write-Host "Next: Run ops-environment skill."
Write-Host ""
