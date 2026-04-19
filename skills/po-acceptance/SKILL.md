---
name: po-acceptance
description: Phase 2 of the Product Owner workflow — defines acceptance criteria and definition of done. For each backlog story, captures Given/When/Then scenarios, edge cases, non-functional criteria, and DoD checklist items. Use after po-backlog to detail what "done" means for each story. Output to po-output/02-acceptance-criteria.md with structured acceptance criteria per story.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Acceptance Criteria & Definition of Done

## When to use

This is the second phase of the Product Owner workflow. Run it when:

- Backlog stories are ready to be detailed with acceptance criteria.
- The user says "I want to define acceptance criteria" / "what does 'done' look like".
- The existing acceptance file (`po-output/02-acceptance-criteria.md`) is missing or stale.

## What it captures

Six structured questions per story:

1. Select a story from the backlog to define acceptance criteria for
2. Given/When/Then BDD scenarios (loop: multiple scenarios per story)
3. Edge cases and error handling
4. Non-functional acceptance criteria (performance, security, etc.)
5. Global DoD checklist items that apply to all stories
6. Story-specific DoD items

Any unclear or missing criteria is logged to `po-output/06-po-debts.md`.

## How to invoke

```bash
bash <SKILL_DIR>/po-acceptance/scripts/acceptance.sh
```

```powershell
pwsh <SKILL_DIR>/po-acceptance/scripts/acceptance.ps1
```

## Output

`po-output/02-acceptance-criteria.md` — structured acceptance criteria per story with BDD scenarios, plus debts appended to `po-output/06-po-debts.md`.
