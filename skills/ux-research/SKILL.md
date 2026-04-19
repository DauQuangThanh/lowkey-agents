---
name: ux-research
description: Phase 1 of the UX Designer workflow — captures user research, personas, user scenarios, journeys, accessibility needs, and device usage patterns from stakeholder and user-story data. Questions target primary user personas (name, role, goals, pain points, tech comfort, device), user scenarios, user journey maps, accessibility requirements (color-blindness, motor, screen-reader, dyslexia, hearing, cognitive), and device usage patterns (desktop/mobile/tablet mix). Reads from `ba-output/REQUIREMENTS-FINAL.md` when present to extract user stories and stakeholder context. Unknowns are logged as UX Debts (UXDEBT-NN). All answers are y/n, numbered choices, or short narratives.
license: MIT
compatibility: Requires Bash 3.2+ (macOS/Linux) or PowerShell 5.1+/7+ (Windows/any). No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# User Research & Personas

## When to use

The first phase of the UX Designer workflow. Run it when:

- The business-analyst has finished capturing user stories and you need to translate them into persona-driven design.
- The user asks "who is this for?" / "what do they need?" — before sketching screens, understand the user.
- The research file (`ux-output/01-user-research.md`) is missing or stale.

## What it captures

1. Primary user personas (2–4): name, role, goals, pain points, tech comfort, device preference
2. User scenarios (2–3): "A customer wants to...", "An admin needs to..."
3. User journey maps: steps, emotions, pain points, touchpoints for each scenario
4. Accessibility needs: color-blindness, motor impairment, screen-reader use, dyslexia, hearing loss, cognitive load
5. Device usage patterns: percentage desktop / mobile / tablet

Any blank, unknown, or unclear answer is logged to `ux-output/05-ux-debts.md` as a **UX Debt (UXDEBT-NN)**.

## How to invoke

```bash
bash <SKILL_DIR>/ux-research/scripts/research.sh
```

```powershell
pwsh <SKILL_DIR>/ux-research/scripts/research.ps1
```

## Output

`ux-output/01-user-research.md` — a markdown summary of personas, scenarios, journeys, accessibility, and device patterns, plus any UXDEBTs appended to `ux-output/05-ux-debts.md`.
