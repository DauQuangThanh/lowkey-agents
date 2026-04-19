---
name: ba-workflow
description: Orchestrates the full Business Analyst workflow end-to-end. Runs every phase in sequence (project intake, stakeholder mapping, requirements elicitation, user stories, non-functional requirements, debt review, validation) and compiles the final REQUIREMENTS-FINAL.md. Use when the user wants to go through the complete requirements gathering process in one session, or resume a paused session. Non-technical friendly — the user answers numbered choices and y/n prompts, one question at a time.
license: MIT
compatibility: Requires Bash 3.2+ (macOS/Linux) or PowerShell 5.1+/7+ (Windows/any). No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "0"
---

# Business Analyst — Full Workflow Orchestrator

## When to use

Use this skill when the user wants to run the complete Business Analyst workflow end-to-end. It chains the seven phase skills together, lets the user skip or pause between phases, and compiles the final requirements document at the end.

## Overview

The workflow progresses through seven phases in order:

1. Project Intake — basic context, methodology, timeline
2. Stakeholder Mapping — who uses or is affected by the system
3. Requirements Elicitation — functional requirements by category
4. User Story Building — stories with acceptance criteria
5. Non-Functional Requirements — quality attributes (performance, security, etc.)
6. Requirement Debt Review — surface and prioritise all unknowns
7. Validation & Sign-Off — compiles the final document

Between each phase the user can choose: `y` to start, `s` to skip, `q` to pause.

## How to invoke

On Linux / macOS:

```bash
bash <SKILL_DIR>/ba-workflow/scripts/run-all.sh
```

On Windows (PowerShell 7+):

```powershell
pwsh <SKILL_DIR>/ba-workflow/scripts/run-all.ps1
```

To resume at a specific step:

```bash
bash <SKILL_DIR>/ba-workflow/scripts/run-all.sh --skip-to 4
pwsh <SKILL_DIR>/ba-workflow/scripts/run-all.ps1 -SkipTo 4
```

## Outputs

All files are written to `ba-output/` under the current working directory:

- `01-project-intake.md`
- `02-stakeholders.md`
- `03-requirements.md`
- `04-user-stories.md`
- `05-nfr.md`
- `06-requirement-debts.md`
- `07-validation-report.md`
- `REQUIREMENTS-FINAL.md` (compiled)

## Requirements

- Bash 3.2+ (macOS default shell works) or PowerShell 5.1+/7+ on Windows
  (PowerShell 7+ recommended: <https://aka.ms/powershell>)

## Environment overrides

- `BA_OUTPUT_DIR` — override the default `./ba-output` directory.
