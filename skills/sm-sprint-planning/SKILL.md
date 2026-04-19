---
name: sm-sprint-planning
description: Phase 1 of the Scrum Master workflow — facilitates sprint planning with team capacity estimation, story selection, and acceptance criteria review. Captures sprint goal, duration, team capacity (story points or hours), committed user stories, DoD (Definition of Done) confirmation, and risk assessment. Generates a comprehensive sprint backlog with committed work and baseline metrics. Invoke at the start of each sprint cycle.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# Sprint Planning

## When to use

This is Phase 1 of the Scrum Master workflow. Run it when:

- A new sprint is about to begin (typically at the end of the previous sprint or start of a new one)
- The user wants to formally plan and commit to a sprint scope
- Team velocity history exists or team capacity is known
- Stories from the product backlog (ba-output/ or po-output/) are ready for estimation

## What it captures

Eight interactive questions covering:

1. Sprint number and sprint goal
2. Sprint duration (1/2/3/4 weeks)
3. Team capacity (story points or hours available)
4. User stories to commit (from backlog if available)
5. Acceptance criteria review
6. Definition of Done (DoD) confirmation
7. Known risks to sprint goal
8. Sprint notes and assumptions

Output files with committed scope, velocity baseline, and impediment flags.

## How to invoke

```bash
bash <SKILL_DIR>/sm-sprint-planning/scripts/sprint-planning.sh
```

```powershell
pwsh <SKILL_DIR>/sm-sprint-planning/scripts/sprint-planning.ps1
```

## Output

`sm-output/01-sprint-plan.md` — Sprint goal, committed stories, acceptance criteria checklist, DoD, risks, and baseline metrics.
