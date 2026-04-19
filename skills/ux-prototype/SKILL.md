---
name: ux-prototype
description: Phase 3 of the UX Designer workflow — specifies visual design direction and produces mockup + prototype specifications. Questions target visual style preference (minimal, corporate, playful, modern, custom), color scheme (primary/secondary/accent colors), typography (fonts, sizes), component library choice (Material/Bootstrap/Custom), key interactions to spec (button states, form validation, loading), and feedback collection method (Figma? InVision? HTML?). Produces visual design guide with color palette and typography scale, mockup specs for key screens, and interaction specifications. Reads `ux-output/02-wireframes.md` to reference layout decisions. Unknowns logged as UX Debts (UXDEBT-NN).
license: MIT
compatibility: Requires Bash 3.2+ (macOS/Linux) or PowerShell 5.1+/7+ (Windows/any). No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Mockup & Prototype Specification

## When to use

The third phase of the UX Designer workflow. Run it when:

- Wireframes are approved and you need to define visual design direction.
- The user asks "what should it look like?" or "what colors/fonts?" — specify before engineering starts.
- The prototype spec file (`ux-output/03-prototype-spec.md`) is missing or stale.

## What it captures

1. Visual style preference: minimal, corporate, playful, modern, custom
2. Color scheme: primary color, secondary, accent, dark/light mode
3. Typography: font families, size scale, weight hierarchy
4. Component library: Material Design, Bootstrap, custom design system
5. Key interactions: button states, form validation, loading, error handling
6. Feedback collection: Figma, InVision, clickable HTML prototype, user testing approach

Output includes visual design guide, mockup specifications with dimensions/spacing/typography, and interaction specifications that developers can reference.

## How to invoke

```bash
bash <SKILL_DIR>/ux-prototype/scripts/prototype.sh
```

```powershell
pwsh <SKILL_DIR>/ux-prototype/scripts/prototype.ps1
```

## Output

`ux-output/03-prototype-spec.md` — visual design guide, mockup specs, interaction specs, plus any UXDEBTs appended to `ux-output/05-ux-debts.md`.
