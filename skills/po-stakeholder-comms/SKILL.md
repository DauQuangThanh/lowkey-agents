---
name: po-stakeholder-comms
description: Phase 4 of the Product Owner workflow — plans stakeholder communication. Captures stakeholder groups, communication needs per group, sprint review format, demo preparation, feedback collection, and escalation triggers. Use to define how product updates are communicated to executives, customers, and the team. Output to po-output/04-stakeholder-comms.md.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# Stakeholder Communication Plan

## When to use

This is the fourth phase of the Product Owner workflow. Run it when:

- The product has stakeholders who need regular updates on progress.
- The user says "I want to plan stakeholder updates" / "how do we communicate progress".
- The existing stakeholder comms file (`po-output/04-stakeholder-comms.md`) is missing or stale.

## What it captures

Six structured questions:

1. Stakeholder groups (executives, customers, team, etc.)
2. Communication needs per group (frequency, format, content)
3. Sprint review format and attendees
4. Demo preparation checklist
5. Feedback collection method
6. Escalation triggers and thresholds

Any gaps is logged to `po-output/06-po-debts.md`.

## How to invoke

```bash
bash <SKILL_DIR>/po-stakeholder-comms/scripts/stakeholder-comms.sh
```

```powershell
pwsh <SKILL_DIR>/po-stakeholder-comms/scripts/stakeholder-comms.ps1
```

## Output

`po-output/04-stakeholder-comms.md` — communication plan per stakeholder group, plus debts appended to `po-output/06-po-debts.md`.
