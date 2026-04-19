---
name: sm-team-health
description: Phase 5 of the Scrum Master workflow — measures and tracks team health, velocity trends, and morale. Captures sprint velocity, planned vs actual, team morale (1-5), collaboration rating, technical practices rating, and improvement trends. Generates a team health dashboard with velocity history, morale tracking, and recommendations for coaching.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "5"
---

# Team Health & Velocity

## When to use

This is Phase 5 of the Scrum Master workflow. Run it when:

- Sprint is complete and you want to measure team health metrics
- You need to track velocity trends over multiple sprints
- You want to identify team morale issues or coaching opportunities
- You're building a team health dashboard for stakeholder reporting

## What it captures

1. Sprint velocity (story points completed)
2. Planned vs actual completion rates
3. Team morale (1-5 scale)
4. Collaboration rating (1-5)
5. Technical practices rating (1-5)
6. Improvement trends and coaching observations

Output file with velocity history, health metrics, and coaching recommendations.

## How to invoke

```bash
bash <SKILL_DIR>/sm-team-health/scripts/team-health.sh
```

```powershell
pwsh <SKILL_DIR>/sm-team-health/scripts/team-health.ps1
```

## Output

`sm-output/05-team-health.md` — Velocity tracker, health metrics table, morale/collaboration/technical practices ratings, trend analysis, and coaching recommendations.
