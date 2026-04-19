---
name: sm-workflow
description: Orchestrator skill — runs all 5 Scrum Master phases in sequence (sprint planning → standup → retrospective → impediments → team health) and compiles a comprehensive SM-FINAL.md report. Use this for end-to-end sprint execution, or invoke individual phase skills for targeted ceremonies.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "0"
---

# Scrum Master Workflow (Orchestrator)

## When to use

Run this skill when:

- You want to execute a **complete sprint cycle** from planning through health check
- You need all 5 phases captured in one session
- You want a consolidated final report with all sprint data

Alternatively, invoke individual phase skills for targeted work:
- `sm-sprint-planning` — Phase 1 only
- `sm-standup` — Phase 2 only
- `sm-retrospective` — Phase 3 only
- `sm-impediments` — Phase 4 only
- `sm-team-health` — Phase 5 only

## What it does

Runs phases 1-5 sequentially:

1. **Phase 1** — Sprint Planning (goal, capacity, commitment)
2. **Phase 2** — Daily Standup (team updates, blockers)
3. **Phase 3** — Sprint Retrospective (Start/Stop/Continue)
4. **Phase 4** — Impediment Tracker (blockers, escalations)
5. **Phase 5** — Team Health (velocity, morale, coaching)

Then compiles all outputs into `sm-output/SM-FINAL.md` for executive reporting.

## How to invoke

```bash
bash <SKILL_DIR>/sm-workflow/scripts/run-all.sh
```

```powershell
pwsh <SKILL_DIR>/sm-workflow/scripts/run-all.ps1
```

## Output

- Individual phase files: `01-sprint-plan.md`, `02-standup-log.md`, `03-retrospective.md`, `04-impediment-log.md`, `05-team-health.md`
- Consolidated report: `sm-output/SM-FINAL.md`
- Debts register: `sm-output/06-sm-debts.md`
