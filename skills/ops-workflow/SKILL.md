---
name: ops-workflow
description: "Orchestrate all DevOps phases (1-6) in sequence: CI/CD design, Infrastructure-as-Code, containerization, monitoring, deployment strategy, and environment management. Compiles a comprehensive OPS-FINAL.md handbook with decisions, templates, debt tracker, and action plan."
license: MIT
compatibility: "Bash 3.2+ / PowerShell 5.1+"
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 0
---

# Phase 0: DevOps Workflow Orchestrator

## Overview

This is the orchestrator skill that runs all six DevOps phases (1-6) in sequence and compiles a comprehensive operations handbook.

## What It Does

1. **Initializes session**: Loads context, project name, team size, deployment frequency expectations
2. **Runs phases 1-6 sequentially**:
   - ops-cicd: CI/CD Pipeline Design
   - ops-infrastructure: Infrastructure-as-Code
   - ops-containerization: Containerization & Orchestration
   - ops-monitoring: Monitoring & Observability
   - ops-deployment: Deployment Strategy
   - ops-environment: Environment Management
3. **Aggregates outputs**: Reads all phase outputs from ops-output/
4. **Compiles final handbook**: Creates `OPS-FINAL.md` with:
   - Executive summary of decisions
   - Complete decision matrix across all phases
   - Consolidated debt tracker (all OPSDEBT-NN items)
   - Ready-to-implement action plan (phase-by-phase)
   - Quick reference (glossary, checklists, templates)

## Session Flow

1. Display banner and project context
2. Ask user to confirm start (or skip individual phases)
3. Run each phase sequentially
4. Aggregate outputs into OPS-FINAL.md
5. Display summary and next steps

## Output

- `ops-output/01-cicd-pipeline.md` (Phase 1 output)
- `ops-output/02-infrastructure.md` (Phase 2 output)
- `ops-output/03-containerization.md` (Phase 3 output)
- `ops-output/04-monitoring.md` (Phase 4 output)
- `ops-output/05-deployment-strategy.md` (Phase 5 output)
- `ops-output/06-environment-plan.md` (Phase 6 output)
- `ops-output/07-ops-debts.md` (Consolidated debt tracker)
- `ops-output/OPS-FINAL.md` (Comprehensive handbook)

## Usage

```bash
# Bash (Linux/macOS)
./scripts/run-all.sh

# PowerShell (Windows)
./scripts/run-all.ps1
```

## Timing

Expect full workflow to take 60-90 minutes (15 minutes per phase with Q&A).

## Notes

- All phases can be run independently, but orchestrator provides cohesive final output.
- User can skip individual phases if already completed.
- All debt items are tracked for prioritization and follow-up.
- OPS-FINAL.md is the source of truth for implementation.
