---
name: requirements-elicitation
description: Phase 3 of the Business Analyst workflow — captures what the system must DO (functional requirements). Walks the user through 14 common feature categories (User Accounts, Data Management, Search, Reporting, Notifications, Integrations, Payments, File Handling, Workflows/Approvals, Communication, Mobile, Admin, Multi-language, Offline). For each, asks y/n and drills in with follow-ups when yes. Records requirements with MoSCoW priority and unique IDs (FR-001…). Vague or TBD answers are logged as Requirement Debts.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Requirements Elicitation

## When to use

Phase 3 of the Business Analyst workflow. Run after stakeholders are mapped. Use whenever the user wants to enumerate what features the system must support.

## What it captures

For each of 14 categories, asks "Does your system need [category]?" (y/n):

1. User Accounts — login, registration, profiles, roles/permissions
2. Data Management — CRUD on core records, import/export, search, audit history
3. Reporting & Analytics — tables, charts, dashboards, scheduled reports, exports
4. Notifications — email/in-app/SMS, triggers
5. Integrations — third-party systems (Salesforce, Stripe, etc.)
6. Payments — one-time, recurring, invoicing
7. File Handling — upload/download, document types
8. Workflows & Approvals — multi-step review processes
9. Communication — comments, DMs, team channels
10. Mobile Access — responsive web, iOS, Android
11. Admin Panel — configuration and user management
12. Multi-language / Multi-region — localisation
13. Offline Mode — offline use and sync
14. Anything Else — user-specified extras

Each confirmed requirement is captured as `FR-NNN` with MoSCoW priority. Missing details become Requirement Debts.

## How to invoke

```bash
bash <SKILL_DIR>/requirements-elicitation/scripts/elicit-requirements.sh
```

```powershell
pwsh <SKILL_DIR>/requirements-elicitation/scripts/elicit-requirements.ps1
```

## Output

`ba-output/03-requirements.md` — a table of functional requirements, plus any debts appended to `ba-output/06-requirement-debts.md`.
