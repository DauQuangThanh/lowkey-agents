---
name: ops-infrastructure
description: "Design Infrastructure-as-Code strategy: IaC tool selection, cloud provider alignment, resource inventory, state management, module structure, secret management, tagging strategy, and cost estimation. Produces detailed IaC architecture with Terraform/CloudFormation skeleton, module layout, and governance policies."
license: MIT
compatibility: "Bash 3.2+ / PowerShell 5.1+"
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 2
---

# Phase 2: Infrastructure as Code Design

## Overview

This skill guides you through designing Infrastructure-as-Code: tool selection, cloud provider strategy, resource inventory, state management, module structure, secret management, tagging, and cost estimation.

## Session Flow

1. Loads output directory and debt file paths
2. Reads architecture decisions from arch-output/ (if available)
3. Asks 8 strategic questions about IaC preferences
4. Generates a detailed IaC specification including:
   - IaC tool rationale and project structure
   - Resource inventory and organization
   - State management strategy
   - Secret management approach
   - Tagging and governance policies
   - Cost estimation baseline

## Key Decisions

- **IaC Tool**: Terraform, Pulumi, CloudFormation, Bicep, Ansible, CDK, OpenTofu
- **Cloud Provider**: AWS, Azure, GCP, Multi-cloud, On-prem (from architecture)
- **Resource Inventory**: Compute, storage, networking, database, cache, queue
- **State Management**: Remote state with locking, local state (not recommended)
- **Module Structure**: Mono-repo, poly-repo, hub-and-spoke
- **Secret Management**: Vault, AWS Secrets Manager, Azure Key Vault, SOPS, Sealed Secrets
- **Tagging Strategy**: Environment, cost center, owner, service, automation markers
- **Cost Estimation**: Infracost, CloudHealth, native cloud tools

## Output

- `ops-output/02-infrastructure.md`: Complete IaC specification
- `ops-output/07-ops-debts.md`: Updated with infrastructure-related debt

## Usage

```bash
# Bash (Linux/macOS)
./scripts/infrastructure.sh

# PowerShell (Windows)
./scripts/infrastructure.ps1
```

## Notes

- Infrastructure parity is critical: dev, staging, and prod should be as similar as possible.
- All infrastructure should be declarative and version-controlled.
- Never commit secrets to git; use secret management systems.
