---
name: pm-planning
description: Phase 1 of the Project Manager workflow — establishes the project plan with WBS, milestones, dependencies, critical path, resource allocation, and definition of done. Asks 8 structured questions to lock down the plan that keeps the project on track. Writes output to `pm-output/01-project-plan.md`. Automatically reads project context from `ba-output/` if available.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# Project Planning

## When to use

This is the first phase of the Project Manager workflow. Run it when:

- A new software project is being kicked off and needs a plan
- The user says "I want to create a project plan" / "let's lock down milestones"
- The existing plan file (`pm-output/01-project-plan.md`) is missing or needs updating
- Starting after the Business Analyst phase (reads project context automatically)

## What it captures

Eight questions, all answered via numbered choices, y/n, or a short sentence:

1. Project name confirmation (from ba-output if available)
2. Development methodology (Agile/Scrum, Kanban, Waterfall, Hybrid)
3. Top-level work breakdown structure (WBS) items (e.g., Planning, Design, Dev, Testing, Deployment)
4. Key milestones and target dates (e.g., Requirements approved, Design review, Alpha, Go-live)
5. Resource allocation approach (Dedicated, Shared, Mixed, TBD)
6. Critical path items and dependencies (e.g., "Design must complete before Dev starts")
7. Communication plan cadence (Daily standup, Weekly, Bi-weekly, Monthly, As-needed)
8. Project-level definition of done (what makes a milestone/deliverable complete?)

Any unclear or "TBD" answer is logged to `pm-output/06-pm-debts.md` with an explanation of its impact.

## How to invoke

```bash
bash <SKILL_DIR>/pm-planning/scripts/planning.sh
```

```powershell
pwsh <SKILL_DIR>/pm-planning/scripts/planning.ps1
```

## Output

`pm-output/01-project-plan.md` — a markdown summary of the project plan with WBS, milestones table, dependencies, and resource allocation. Any uncertainties are appended to `pm-output/06-pm-debts.md`.
