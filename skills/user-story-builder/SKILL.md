---
name: user-story-builder
description: Phase 4 of the Business Analyst workflow — expresses requirements as user stories following the "As a [who], I want to [what], so that [why]" pattern. For each story, walks the user through six parts (role, action, benefit, MoSCoW priority, complexity estimate, acceptance criteria), adding stories one at a time until the user says stop. Stories with missing parts or no acceptance criteria are auto-logged as Requirement Debts. Stories are numbered US-001 upward.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# User Story Builder

## When to use

Phase 4 of the Business Analyst workflow. Run after functional requirements are captured (phase 3). Also useful standalone whenever the user wants to add user stories to an existing backlog.

## What it captures

Per story:

1. WHO — role of the user ("As a …")
2. WHAT — action they want to take ("I want to …")
3. WHY — benefit they gain ("so that …")
4. PRIORITY — MoSCoW (Must / Should / Could / Won't Have)
5. COMPLEXITY — Small / Medium / Large / Unknown
6. ACCEPTANCE CRITERIA — 2+ bullet items, added one at a time

Optional notes for assumptions and dependencies are also captured. Stories are numbered `US-001`, `US-002`, … Any missing WHO/WHAT/WHY, or no acceptance criteria at all, generates a Requirement Debt.

## How to invoke

```bash
bash <SKILL_DIR>/user-story-builder/scripts/build-stories.sh
```

```powershell
pwsh <SKILL_DIR>/user-story-builder/scripts/build-stories.ps1
```

## Output

`ba-output/04-user-stories.md` — fully formatted user stories plus a quick-reference table, with any debts appended to `ba-output/06-requirement-debts.md`.
