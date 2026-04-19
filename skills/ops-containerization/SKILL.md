---
name: ops-containerization
description: "Design containerization and orchestration strategy: container runtime, base image strategy, orchestration platform, resource management, health checks, service mesh, and image scanning. Produces Dockerfile template, Kubernetes manifests skeleton, and container lifecycle policies."
license: MIT
compatibility: "Bash 3.2+ / PowerShell 5.1+"
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 3
---

# Phase 3: Containerization & Orchestration Design

## Overview

This skill guides you through designing containerization and orchestration: container runtime, base images, orchestration platforms, resource management, health checks, service mesh, and image scanning.

## Session Flow

1. Loads output directory and debt file paths
2. Asks 8 strategic questions about container and orchestration preferences
3. Generates detailed containerization specification including:
   - Container runtime and base image strategy
   - Orchestration platform and cluster design
   - Resource request/limit policy
   - Health check patterns and probes
   - Service mesh (if applicable)
   - Image scanning and vulnerability management
   - Dockerfile best practices template
   - Kubernetes manifests skeleton (if applicable)

## Key Decisions

- **Container Runtime**: Docker, Podman, containerd, Serverless (no containers)
- **Base Image Strategy**: Distroless (minimal), Alpine (small), Ubuntu (familiar), Custom
- **Orchestration Platform**: Kubernetes (EKS/AKS/GKE), ECS, Docker Compose, Nomad, None
- **Cluster Strategy**: Single cluster, multi-cluster, multi-region
- **Resource Management**: CPU/memory requests and limits
- **Health Checks**: Liveness, readiness, startup probes
- **Service Mesh**: Istio, Linkerd, None
- **Image Scanning**: Trivy, Snyk, Aqua, None

## Output

- `ops-output/03-containerization.md`: Complete containerization specification
- `ops-output/07-ops-debts.md`: Updated with containerization-related debt

## Usage

```bash
# Bash (Linux/macOS)
./scripts/containerization.sh

# PowerShell (Windows)
./scripts/containerization.ps1
```

## Notes

- Container security is paramount: minimize base image, scan for CVEs, run as non-root.
- Resource limits prevent noisy neighbor problems and uncontrolled scaling.
- Orchestration adds complexity; use only if you need multi-node orchestration.
