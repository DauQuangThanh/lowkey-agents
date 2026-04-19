---
name: ops-environment
description: "Design environment strategy: dev/QA/staging/prod environment definitions, parity policies, configuration management, access control, data management, and provisioning automation. Produces environment matrix, configuration hierarchy, IAM policy, and data seeding strategy."
license: MIT
compatibility: "Bash 3.2+ / PowerShell 5.1+"
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 6
---

# Phase 6: Environment Management Design

## Overview

This skill guides you through designing environment strategy: dev, QA, staging, production definitions, parity, configuration management, access control, data handling, and provisioning.

## Session Flow

1. Loads output directory and debt file paths
2. Asks 6 strategic questions about environment preferences
3. Generates detailed environment specification including:
   - Environment matrix (name, purpose, specs, access)
   - Configuration hierarchy (global, environment, service)
   - IAM/RBAC policy per environment
   - Data seeding and masking strategy
   - Environment refresh schedule
   - Provisioning automation workflow

## Key Decisions

- **Environments**: dev, QA, staging, pre-prod, prod, custom
- **Parity Strategy**: Identical (same IaC, scaling), right-sized, custom
- **Configuration Management**: Env vars, config files, config server, ConfigMap
- **Access Control**: Role-based, environment separation, audit logging
- **Data Management**: Seeding, masking, refresh cadence, test data
- **Provisioning**: Fully automated, semi-automated, manual

## Output

- `ops-output/06-environment-plan.md`: Complete environment specification
- `ops-output/07-ops-debts.md`: Updated with environment-related debt

## Usage

```bash
# Bash (Linux/macOS)
./scripts/environment.sh

# PowerShell (Windows)
./scripts/environment.ps1
```

## Notes

- Environment parity prevents "it works in dev but fails in prod" surprises.
- Configuration must be injectable and environment-specific; no hardcoding.
- Access control is security-critical: enforce least privilege.
- Data masking is essential for GDPR/CCPA compliance in non-prod.
