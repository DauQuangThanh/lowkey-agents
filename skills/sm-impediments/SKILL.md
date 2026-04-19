---
name: sm-impediments
description: Phase 4 of the Scrum Master workflow — tracks and escalates impediments / blockers. Captures blocker description, severity (blocking/degrading/minor), affected stories, escalation status, owner, and target resolution date. Generates impediment log for SM follow-up and escalation tracking. Perfect for unblocking teams and removing obstacles to progress.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# Impediment Tracker

## When to use

This is Phase 4 of the Scrum Master workflow. Run it when:

- You need to formally log and track blockers and impediments
- Standups or retrospectives have surfaced issues that need escalation
- You want to create a prioritized list of SM actions
- You need to ensure blockers don't get lost between ceremonies

## What it captures

For each impediment:

1. Description of the blocker
2. Severity level (Blocking, Degrading, Minor)
3. Which stories/work are affected
4. Escalation needed (y/n)
5. Owner / who should resolve
6. Target resolution date

Output file with impediment log and SM follow-up actions.

## How to invoke

```bash
bash <SKILL_DIR>/sm-impediments/scripts/impediments.sh
```

```powershell
pwsh <SKILL_DIR>/sm-impediments/scripts/impediments.ps1
```

## Output

`sm-output/04-impediment-log.md` — Impediment tracker with severity levels, affected work, escalation flags, and SM action items.
