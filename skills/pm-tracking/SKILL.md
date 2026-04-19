---
name: pm-tracking
description: Phase 2 of the Project Manager workflow — establishes status tracking and reporting with RAG (Red/Amber/Green) status, accomplishments, planned activities, blockers, and budget variance. Asks 6 structured questions to set up the reporting cadence. Writes output to `pm-output/02-status-report.md`.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Status Tracking & Reporting

## When to use

Second phase of the Project Manager workflow. Run it after the project plan is locked. Use it to:

- Set up a status reporting template for regular updates
- Document current project health (RAG status)
- Record key accomplishments in the current period
- Forecast planned activities for the next period
- Surface blockers and issues
- Track budget and schedule variance

## What it captures

Six fields, all answered via numbered choices, y/n, or short text:

1. Reporting period (Weekly, Bi-weekly, Monthly, Per-milestone)
2. Overall project RAG status (Red/Amber/Green)
3. Key accomplishments this period (up to 5 bullet points)
4. Planned activities next period (up to 5 bullet points)
5. Blockers and issues (with owner and target resolution)
6. Budget status (on track / over / under + percentage variance)

## How to invoke

```bash
bash <SKILL_DIR>/pm-tracking/scripts/tracking.sh
```

```powershell
pwsh <SKILL_DIR>/pm-tracking/scripts/tracking.ps1
```

## Output

`pm-output/02-status-report.md` — a status report template with current period data, filled in by the user. Ready to be copied and reused each reporting period.
