---
name: sm-standup
description: Phase 2 of the Scrum Master workflow — facilitates daily standup notes collection. Captures "what did you do yesterday", "what will you do today", and "any blockers?" for each team member in a structured log. Generates a standup summary with impediment flags, blockers highlighted, and team morale snapshot. Perfect for distributed teams or async standups.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Daily Standup

## When to use

This is Phase 2 of the Scrum Master workflow. Run it when:

- Daily standup meetings are happening (Scrum teams)
- You want to capture async standup updates from team members
- You need to track blockers and escalate issues
- You want a structured standup log for retrospectives

## What it captures

For each team member:

1. Name / role
2. What did they accomplish yesterday?
3. What will they work on today?
4. Any blockers or impediments?

Also captures:
- Summary of impediments identified
- Team capacity / morale indicator
- Any escalations needed

Output file with standup notes and blockers highlighted for SM follow-up.

## How to invoke

```bash
bash <SKILL_DIR>/sm-standup/scripts/standup.sh
```

```powershell
pwsh <SKILL_DIR>/sm-standup/scripts/standup.ps1
```

## Output

`sm-output/02-standup-log.md` — Standup notes organized by team member, blockers extracted, SM actions highlighted.
