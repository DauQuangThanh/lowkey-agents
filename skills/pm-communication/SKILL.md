---
name: pm-communication
description: Phase 4 of the Project Manager workflow — establishes communication and stakeholder management with channels, cadence, escalation paths, RACI matrix, and change request process. Captures 6 key elements to keep all stakeholders aligned. Writes output to `pm-output/04-communication-plan.md`.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# Communication & Stakeholder Management

## When to use

Fourth phase of the Project Manager workflow. Run it to establish how stakeholders are informed and engaged. Use it to:

- Define stakeholder groups and their information needs
- Establish communication channels (email, meetings, wiki, etc.)
- Set cadence for updates (daily standup, weekly, monthly, etc.)
- Define escalation paths for issues
- Create RACI matrix for key deliverables
- Document the change request approval process

## What it captures

Six fields:
1. **Stakeholder groups** (can reference ba-output/02-stakeholders.md)
2. **Communication channels** (Email, Slack, Weekly meetings, SharePoint, etc.)
3. **Meeting cadence** (Daily, Weekly, Bi-weekly, Monthly, Ad-hoc)
4. **Escalation path** (Tier 1, Tier 2, Tier 3 rules)
5. **RACI matrix** for key deliverables (Responsible, Accountable, Consulted, Informed)
6. **Change request process** (who approves, what triggers a CR?)

## How to invoke

```bash
bash <SKILL_DIR>/pm-communication/scripts/communication.sh
```

```powershell
pwsh <SKILL_DIR>/pm-communication/scripts/communication.ps1
```

## Output

`pm-output/04-communication-plan.md` — a communication plan with stakeholder map, channels, cadence, escalation rules, RACI matrix, and change control process.
