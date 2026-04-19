# OPS Skill: ops-monitoring (Phase 4)
# Monitoring & Observability Design

param()

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:OPS_AUTO = '1' }
if ($Answers) { $env:OPS_ANSWERS = $Answers }


$outputFile = Join-Path $script:OPSOutputDir "04-monitoring.md"

Write-OPS-Banner "Phase 4: Monitoring & Observability Design"

Ask-OPS-Choice "Logging Platform?" "ELK Stack", "Loki", "CloudWatch", "Splunk", "Datadog", "Not decided yet" | Out-Null

$content = @"
# Phase 4: Monitoring & Observability Design

## Status

This is a placeholder. Full implementation includes:

1. **Logs** - ELK, Loki, CloudWatch, Splunk, Datadog selection
2. **Metrics** - Prometheus, CloudWatch, Datadog, New Relic
3. **Traces** - Jaeger, Zipkin, OpenTelemetry, X-Ray
4. **Alerting Rules** - Critical thresholds, escalation policies
5. **On-Call Rotation** - PagerDuty, OpsGenie, or custom
6. **SLO/SLI Definitions** - Availability, latency, error rate targets
7. **Dashboard Specifications** - Key metrics per service
8. **Incident Response Playbook** - Escalation and communication

## Three Pillars

- **Logs**: Application and infrastructure logs for debugging
- **Metrics**: Time-series data for performance monitoring
- **Traces**: Request flows across distributed systems

## Next Steps

Run the full skill for complete observability architecture.

"@

$content | Set-Content $outputFile

Write-OPS-SuccessRule "Monitoring specification placeholder written to $outputFile"
Write-Host ""
Write-Host "Next: Run ops-deployment skill."
Write-Host ""
