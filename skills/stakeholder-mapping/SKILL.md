---
name: stakeholder-mapping
description: Phase 2 of the Business Analyst workflow — identifies everyone who uses or is affected by the system. Walks the user through four stakeholder groups (Primary users, Secondary users, Decision makers, External parties) and for each captures role/title, technical level (1–3 scale), and primary need from the system. Use after project intake or whenever stakeholder coverage must be refreshed. Missing roles or unnamed stakeholders are logged as Requirement Debts.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Stakeholder Mapping

## When to use

Phase 2 of the Business Analyst workflow. Run after `project-intake` or whenever the user wants to define who uses, approves, or is affected by the system.

## What it captures

For each of these groups, the user confirms y/n whether they exist and (if yes) adds one or more entries:

- Primary users — daily users of the system
- Secondary users — occasional users or downstream consumers of outputs/reports
- Decision makers / sponsors — the people who approve requirements and budget
- External parties — vendors, regulators, partner systems, customers

For each stakeholder: role/title, technical level (Not at all / Some / Very technical), and the one thing they most need from the system.

Missing decision makers or missing primary users are flagged as blocking-level Requirement Debts.

## How to invoke

```bash
bash <SKILL_DIR>/stakeholder-mapping/scripts/map-stakeholders.sh
```

```powershell
pwsh <SKILL_DIR>/stakeholder-mapping/scripts/map-stakeholders.ps1
```

## Output

`ba-output/02-stakeholders.md` — a single markdown table of every stakeholder, plus any debts appended to `ba-output/06-requirement-debts.md`.
