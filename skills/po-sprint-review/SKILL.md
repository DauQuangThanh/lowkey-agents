---
name: po-sprint-review
description: Phase 5 of the Product Owner workflow — prepares sprint review documentation. Captures sprint number, stories completed, stories not completed with reasons, demo items, stakeholder feedback, and backlog adjustments. Use after each sprint to document what was delivered and lessons learned. Output to po-output/05-sprint-review.md.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "5"
---

# Sprint Review Preparation

## When to use

This is the fifth phase of the Product Owner workflow. Run it when:

- A sprint is complete and you need to document results.
- The user says "I want to prepare a sprint review" / "what did we deliver this sprint".
- The existing sprint review file (`po-output/05-sprint-review.md`) is missing or stale.

## What it captures

Six structured questions:

1. Sprint number and dates
2. Stories completed (with sizing)
3. Stories not completed (with reasons)
4. Demo items and highlights
5. Stakeholder feedback and insights
6. Backlog adjustments and next sprint planning

Any missing or unclear information is logged to `po-output/06-po-debts.md`.

## How to invoke

```bash
bash <SKILL_DIR>/po-sprint-review/scripts/sprint-review.sh
```

```powershell
pwsh <SKILL_DIR>/po-sprint-review/scripts/sprint-review.ps1
```

## Output

`po-output/05-sprint-review.md` — sprint results summary, velocity, blockers, and retrospective insights, plus debts appended to `po-output/06-po-debts.md`.
