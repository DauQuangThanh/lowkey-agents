---
name: pm-change-management
description: Phase 5 of the Project Manager workflow — establishes change request tracking and approval. Captures change description, impact assessment (scope/schedule/budget/quality), priority, and approval status. Allows adding change requests one at a time. Writes output to `pm-output/05-change-log.md`.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "5"
---

# Change Request Tracking

## When to use

Fifth phase of the Project Manager workflow. Run it to establish change request logging and impact assessment. Use it to:

- Create a change request log
- Track scope changes
- Assess impact on schedule, budget, and quality
- Document approvals and rejections
- Maintain audit trail of decisions

## What it captures

For each change request:
- **Description** — what is changing and why?
- **Impact assessment** — scope (H/M/L), schedule (H/M/L), budget (H/M/L), quality (H/M/L)
- **Priority** — 🔴 Critical / 🟡 High / 🟢 Medium / 🔵 Low
- **Approval status** — Pending / Approved / Rejected / On Hold
- **Reason** — why was it approved/rejected?
- **Owner** — who requested and who will implement?

Change requests are added one at a time in a loop. User can add as many as needed.

## How to invoke

```bash
bash <SKILL_DIR>/pm-change-management/scripts/change.sh
```

```powershell
pwsh <SKILL_DIR>/pm-change-management/scripts/change.ps1
```

## Output

`pm-output/05-change-log.md` — a change log with all change requests, impact assessments, and approval decisions.
