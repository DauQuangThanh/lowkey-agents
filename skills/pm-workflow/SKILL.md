---
name: pm-workflow
description: Orchestrator for the Project Manager workflow — runs all 5 phases in sequence (Planning, Tracking, Risk, Communication, Change Management) with y/s/q pauses between each step. Automatically reads project context from ba-output if available. Compiles all phase outputs into a final PM-FINAL.md document. Master skill for complete project management setup.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "0"
---

# Project Manager Workflow Orchestrator

## When to use

Use this master skill to run the entire Project Manager workflow end-to-end. Perfect for:

- Kicking off a new project with complete PM setup
- Running all phases in one session with controlled pacing
- Ensuring all PM areas are covered (planning, risk, communication, change)
- Generating a final compiled deliverable (PM-FINAL.md)

## What it does

1. **Loads project context** from `ba-output/` if available
2. **Runs Phase 1 (Planning)** — project plan, WBS, milestones, dependencies, DoD
3. **Runs Phase 2 (Tracking)** — status reporting template and cadence
4. **Runs Phase 3 (Risk)** — risk identification, assessment, mitigation
5. **Runs Phase 4 (Communication)** — stakeholder management, RACI, escalation
6. **Runs Phase 5 (Change Management)** — change request tracking
7. **Compiles PM-FINAL.md** — all phases stitched into one document

Between steps, user can:
- **y** — proceed to the phase
- **s** — skip the phase (recorded in skipped-steps.md)
- **q** — quit and resume later with `--skip-to N`

## How to invoke

```bash
bash <SKILL_DIR>/pm-workflow/scripts/run-all.sh
```

```bash
# Resume from step 3
bash <SKILL_DIR>/pm-workflow/scripts/run-all.sh --skip-to 3
```

```powershell
pwsh <SKILL_DIR>/pm-workflow/scripts/run-all.ps1
```

## Output files

- `pm-output/01-project-plan.md` — WBS, milestones, dependencies, resource plan
- `pm-output/02-status-report.md` — status template with RAG, accomplishments, blockers
- `pm-output/03-risk-register.md` — identified risks with scores and mitigation
- `pm-output/04-communication-plan.md` — stakeholder map, cadence, RACI, escalation
- `pm-output/05-change-log.md` — change requests with impact and approval status
- `pm-output/06-pm-debts.md` — all outstanding PM Debts (auto-generated)
- `pm-output/PM-FINAL.md` — complete compiled project management deliverable

## How it works

Each phase is a self-contained skill that can also be run individually:
- `bash <SKILL_DIR>/pm-planning/scripts/planning.sh`
- `bash <SKILL_DIR>/pm-tracking/scripts/tracking.sh`
- `bash <SKILL_DIR>/pm-risk/scripts/risk.sh`
- `bash <SKILL_DIR>/pm-communication/scripts/communication.sh`
- `bash <SKILL_DIR>/pm-change-management/scripts/change.sh`

The orchestrator manages sequencing, progress display, and final compilation.
