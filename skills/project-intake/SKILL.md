---
name: project-intake
description: Phase 1 of the Business Analyst workflow — gathers baseline project context with minimal user effort. Captures project name, problem statement, development methodology (Agile/Scrum, Kanban, Waterfall, Hybrid), timeline, team size, budget, hard deadline, and out-of-scope items. Use at the start of a requirements engagement, or whenever the user wants to define or refresh the high-level project profile. All answers are y/n, numbered choices, or one-line text. Missing/unclear answers are auto-logged as Requirement Debts.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# Project Intake

## When to use

This is the first phase of the Business Analyst workflow. Run it when:

- A new software project is being scoped.
- The user says "I want to start defining requirements" / "let's kick off planning".
- The existing intake file (`ba-output/01-project-intake.md`) is missing or stale.

## What it captures

Eight questions, all answered via numbered choices, y/n, or a short sentence:

1. Project name
2. One-sentence problem statement
3. Development methodology (Agile/Scrum, Kanban, Waterfall, Hybrid, Not decided)
4. Estimated timeline (under 1 month through over 1 year)
5. Hard deadline (y/n → date)
6. Team size
7. Budget (y/n → range)
8. What is out of scope

Any blank or "not decided" answer is logged to `ba-output/06-requirement-debts.md` with an explanation of its impact.

## How to invoke

```bash
bash <SKILL_DIR>/project-intake/scripts/intake.sh
```

```powershell
pwsh <SKILL_DIR>/project-intake/scripts/intake.ps1
```

## Output

`ba-output/01-project-intake.md` — a markdown summary of the project profile, plus any debts appended to `ba-output/06-requirement-debts.md`.
