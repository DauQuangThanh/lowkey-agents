---
name: po-roadmap
description: Phase 3 of the Product Owner workflow — creates a product roadmap. Captures roadmap horizon, release cadence, release themes/goals per period, key milestones, external dependencies, and success metrics. Use after backlog is prioritized to communicate product direction and release planning to stakeholders. Output to po-output/03-product-roadmap.md with timeline and release themes.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Product Roadmap

## When to use

This is the third phase of the Product Owner workflow. Run it when:

- The backlog is ready and team wants to plan releases and communicate timeline.
- The user says "I want to create a roadmap" / "when will things ship".
- The existing roadmap file (`po-output/03-product-roadmap.md`) is missing or stale.

## What it captures

Six structured questions:

1. Roadmap horizon (quarter, half-year, year)
2. Release cadence (how often do releases happen?)
3. Release themes/goals per period (loop: each release period gets goals, features, milestones)
4. Key milestones and dates
5. External dependencies (on other teams, vendors, etc.)
6. Success metrics per release

Any gaps or unclear milestones is logged to `po-output/06-po-debts.md`.

## How to invoke

```bash
bash <SKILL_DIR>/po-roadmap/scripts/roadmap.sh
```

```powershell
pwsh <SKILL_DIR>/po-roadmap/scripts/roadmap.ps1
```

## Output

`po-output/03-product-roadmap.md` — release-based roadmap with themes, milestones, and dependencies, plus debts appended to `po-output/06-po-debts.md`.
