---
name: requirement-debt-tracker
description: Phase 6 of the Business Analyst workflow — surfaces, enriches, and prioritises all Requirement Debts collected during the session. A Requirement Debt is any piece of information needed to properly define the system that is currently unknown, unclear, conflicting, or unconfirmed. Reviews existing debts (auto-logged by earlier phases), lets the user assign owners and due dates, and captures any new debts the user knows about. Produces a prioritised register with Blocking/Important/Can-Wait traffic-light categories.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "6"
---

# Requirement Debt Tracker

## When to use

Phase 6 of the Business Analyst workflow. Run after phases 1–5 have logged auto-detected debts. Also useful standalone whenever the user wants to review, triage, or extend the open-questions register.

## What a "Requirement Debt" is

Any of the following is tracked as a debt:

1. "I'm not sure" / "TBD" / "it depends" answers
2. Contradictory requirements
3. Stakeholders not yet consulted
4. Vague business rules ("standard discount")
5. Requirements with no acceptance criteria
6. Unspecified external systems or integrations
7. Suspected but unconfirmed compliance requirements
8. Unclear feature scope ("something like Facebook")

## What it does

1. Reads `ba-output/06-requirement-debts.md` and shows every existing debt.
2. Prompts for a default owner (name or role) and updates every `Owner: TBD` to that person.
3. Offers to add new manual debts — each with area, impact, owner, priority (🔴 Blocking / 🟡 Important / 🟢 Can Wait), and target date.
4. Prints a summary with a count per priority level.
5. Warns loudly if any 🔴 Blocking debts remain.

## How to invoke

```bash
bash <SKILL_DIR>/requirement-debt-tracker/scripts/debt-tracker.sh
```

```powershell
pwsh <SKILL_DIR>/requirement-debt-tracker/scripts/debt-tracker.ps1
```

## Output

`ba-output/06-requirement-debts.md` — enriched debt register (updated in place). New debts are appended with monotonic `DEBT-NN` IDs that continue from the existing count.
