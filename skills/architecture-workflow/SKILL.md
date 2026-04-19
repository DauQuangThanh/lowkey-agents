---
name: architecture-workflow
description: Orchestrates the full Architect workflow end-to-end. Runs every phase in sequence (architecture intake, technology research, ADR building, C4 documentation, risk & trade-off register, validation) and compiles the final ARCHITECTURE-FINAL.md. Use when the user wants to go through the complete architecture design process in one session, or resume a paused session (with --skip-to N). Between each phase the user can start (y), skip (s), or pause (q). Works alongside the business-analyst's ba-workflow — picks up after requirements are captured.
license: MIT
compatibility: Requires Bash 3.2+ (macOS/Linux) or PowerShell 5.1+/7+ (Windows/any). Optional `WebSearch`/`WebFetch` for technology research.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "0"
---

# Architect — Full Workflow Orchestrator

## When to use

Use this skill when the user wants to run the complete Architect workflow end-to-end. It chains
the six phase skills together, lets the user skip or pause between phases, and compiles the
final architecture document at the end.

## Overview

The workflow progresses through six phases in order:

1. **Architecture Intake** — drivers, constraints, operational envelope, deployment preference
2. **Technology Research** — candidate technologies per decision area with comparison tables
3. **ADR Building** — Architecture Decision Records, one per significant decision (Michael
   Nygard template)
4. **C4 Architecture** — System Context → Container → Component diagrams (Mermaid)
5. **Risk & Trade-off Register** — risks and technical debts, prioritised
6. **Validation & Sign-Off** — automated + manual checks → `ARCHITECTURE-FINAL.md`

Between each phase the user can choose: `y` to start, `s` to skip, `q` to pause.

## Handover from business-analyst

On startup, the orchestrator looks for `ba-output/REQUIREMENTS-FINAL.md` (or individual phase
files). If found, it summarises the requirements and asks the user to confirm them as the basis
for the architecture work. If not found, it proceeds but recommends running the BA workflow
first for best results.

## How to invoke

On Linux / macOS:

```bash
bash <SKILL_DIR>/architecture-workflow/scripts/run-all.sh
```

On Windows (PowerShell 7+):

```powershell
pwsh <SKILL_DIR>/architecture-workflow/scripts/run-all.ps1
```

To resume at a specific step:

```bash
bash <SKILL_DIR>/architecture-workflow/scripts/run-all.sh --skip-to 4
```

## Output

All outputs land in `./arch-output/` (or `$ARCH_OUTPUT_DIR` if set):

- `01-architecture-intake.md`
- `02-technology-research.md`
- `03-adr-index.md` + `adr/ADR-NNNN-*.md`
- `04-architecture.md` + `diagrams/*.mmd`
- `05-technical-debts.md`
- `06-architecture-validation.md`
- `ARCHITECTURE-FINAL.md` (auto-compiled)

## Environment variables

- `ARCH_OUTPUT_DIR` — override the output folder (default: `./arch-output`)
- `ARCH_BA_INPUT_DIR` — override where to read BA outputs from (default: `./ba-output`)
