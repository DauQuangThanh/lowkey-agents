---
name: ops-deployment
description: "Design deployment strategy: deployment pattern (rolling, blue-green, canary), rollback strategy, database migrations, feature flags, zero-downtime requirements, smoke tests, and disaster recovery plan. Produces deployment runbook, feature flag policy, and DR procedures."
license: MIT
compatibility: "Bash 3.2+ / PowerShell 5.1+"
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 5
---

# Phase 5: Deployment Strategy Design

## Overview

This skill guides you through designing a deployment strategy: deployment pattern, rollback, database migrations, feature flags, zero-downtime, smoke tests, and disaster recovery.

## Session Flow

1. Loads output directory and debt file paths
2. Asks 8 strategic questions about deployment preferences
3. Generates detailed deployment specification including:
   - Deployment pattern strategy and execution plan
   - Rollback procedures and automation
   - Database migration approach
   - Feature flag system and governance
   - Zero-downtime deployment validation
   - Smoke test scenarios
   - Disaster recovery RTO/RPO matrix
   - Deployment runbook skeleton

## Key Decisions

- **Deployment Pattern**: Rolling, blue-green, canary, recreate, A-B testing
- **Rollback Strategy**: Instant (code revert), gradual (reverse canary), database snapshot
- **Database Migrations**: Expand-contract, zero-downtime tools, maintenance window
- **Feature Flags**: LaunchDarkly, Unleash, custom, none
- **Zero-Downtime**: Yes (24/7), yes (business hours), no (windows acceptable)
- **Deployment Window**: Continuous, scheduled, on-demand, weekly
- **Smoke Tests**: Synthetic, canary validation, manual, automated e2e
- **Disaster Recovery**: RTO/RPO targets, backup frequency, failover strategy

## Output

- `ops-output/05-deployment-strategy.md`: Complete deployment specification
- `ops-output/07-ops-debts.md`: Updated with deployment-related debt

## Usage

```bash
# Bash (Linux/macOS)
./scripts/deployment.sh

# PowerShell (Windows)
./scripts/deployment.ps1
```

## Notes

- Deployment pattern choice affects blast radius and risk: choose carefully.
- Feature flags decouple deployment from release: essential for continuous delivery.
- Database migrations are the hardest deployment problem; plan ahead.
- Disaster recovery is not optional: test regularly, measure RTO/RPO.
