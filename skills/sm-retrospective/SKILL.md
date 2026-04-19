---
name: sm-retrospective
description: Phase 3 of the Scrum Master workflow — facilitates sprint retrospectives using the Start/Stop/Continue format. Captures what went well, what didn't, and improvement action items with owners and due dates. Generates a retrospective report with velocity data, team sentiment, and committed action items for next sprint. Perfect for continuous improvement and team reflection.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Sprint Retrospective

## When to use

This is Phase 3 of the Scrum Master workflow. Run it when:

- Sprint is ending and team is ready for retrospective ceremony
- You want to capture lessons learned and process improvements
- Team morale and velocity trends should be documented
- You need to log action items for continuous improvement

## What it captures

Using the Start/Stop/Continue format:

1. What went well this sprint? (continue doing)
2. What didn't go well? (stop doing)
3. What should we try? (start doing)
4. Sprint velocity and actual vs planned completion
5. Team sentiment and collaboration metrics
6. Action items with owners and due dates

Output file with retrospective insights and improvement tracking.

## How to invoke

```bash
bash <SKILL_DIR>/sm-retrospective/scripts/retro.sh
```

```powershell
pwsh <SKILL_DIR>/sm-retrospective/scripts/retro.ps1
```

## Output

`sm-output/03-retrospective.md` — Start/Stop/Continue summary, velocity analysis, action items with owners, team health metrics.
