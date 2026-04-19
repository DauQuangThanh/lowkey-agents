#!/bin/bash

# OPS Skill: ops-containerization (Phase 3)
# Containerization & Orchestration Design

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ops_parse_flags "$@"


OUTPUT_FILE="$OPS_OUTPUT_DIR/03-containerization.md"

ops_banner "Phase 3: Containerization & Orchestration Design"

ops_ask_choice "Container Runtime?" \
    "Docker" \
    "Podman" \
    "containerd" \
    "Serverless (no containers)" > /dev/null

{
    cat <<'EOF'
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

EOF
} > "$OUTPUT_FILE"

ops_success_rule "Containerization specification placeholder written to $OUTPUT_FILE"
echo ""
echo "Next: Run ops-monitoring skill."
echo ""
