# OPS Skill: ops-containerization (Phase 3)
# Containerization & Orchestration Design

param()

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir "_common.ps1")

# Step 3: accept -Auto / -Answers
if ($Auto) { $env:OPS_AUTO = '1' }
if ($Answers) { $env:OPS_ANSWERS = $Answers }


$outputFile = Join-Path $script:OPSOutputDir "03-containerization.md"

Write-OPS-Banner "Phase 3: Containerization & Orchestration Design"

Ask-OPS-Choice "Container Runtime?" "Docker", "Podman", "containerd", "Serverless (no containers)" | Out-Null

$content = @"
# Phase 3: Containerization & Orchestration Design

## Status

This is a placeholder. Full implementation includes:

1. **Container Runtime** - Docker, Podman, containerd selection and configuration
2. **Base Image Strategy** - Distroless, Alpine, Ubuntu trade-offs
3. **Orchestration Platform** - Kubernetes, ECS, Docker Compose, or none
4. **Cluster Architecture** - Single, multi-cluster, multi-region strategies
5. **Resource Management** - CPU/memory requests and limits
6. **Health Checks** - Liveness, readiness, startup probe configuration
7. **Service Mesh** - Istio, Linkerd, or none
8. **Image Scanning** - Vulnerability detection and remediation

## Includes

- Dockerfile best practices template
- Kubernetes manifests skeleton (if applicable)
- Container security policies
- Resource limit governance

## Next Steps

Run the full skill for complete containerization architecture.

"@

$content | Set-Content $outputFile

Write-OPS-SuccessRule "Containerization specification placeholder written to $outputFile"
Write-Host ""
Write-Host "Next: Run ops-monitoring skill."
Write-Host ""
