---
name: ux-wireframe
description: Phase 2 of the UX Designer workflow — creates wireframes, information architecture, and user-flow diagrams from persona and scenario data. Questions target key screens to wireframe (3–6 primary screens), navigation structure (linear, tabs, hierarchical, sidebar, bottom tabs), page layout preferences, content hierarchy, interaction patterns (forms with validation, tables with sorting/filtering, modals), and responsive requirements (mobile-first? breakpoints?). Produces text-based wireframe descriptions, Mermaid flowcharts for navigation and user flows, and IA diagrams. Reads `ux-output/01-user-research.md` to extract personas and scenarios. Unknowns are logged as UX Debts (UXDEBT-NN).
license: MIT
compatibility: Requires Bash 3.2+ (macOS/Linux) or PowerShell 5.1+/7+ (Windows/any). No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Wireframes & Information Architecture

## When to use

The second phase of the UX Designer workflow. Run it when:

- User research and personas are complete and you need to sketch screens.
- The user asks "what should the interface look like?" — visualize before finalizing design direction.
- The wireframe file (`ux-output/02-wireframes.md`) is missing or stale.

## What it captures

1. Key screens to wireframe (3–6 primary screens): login, dashboard, product listing, detail, checkout, etc.
2. Navigation structure: linear, tab-based, hierarchical, sidebar menu, bottom tabs
3. Page layout preferences: header + main + footer, sidebar + main, full-width, card-based
4. Content hierarchy: prominence of headings, CTAs, secondary actions
5. Interaction patterns: form validation, table sorting/filtering, modals, infinite scroll, pagination
6. Responsive requirements: separate mobile layout? Breakpoints? Mobile-first or desktop-first?

Output includes text-based wireframe descriptions, Mermaid flowcharts (navigation and user flows), and information-architecture diagrams.

## How to invoke

```bash
bash <SKILL_DIR>/ux-wireframe/scripts/wireframe.sh
```

```powershell
pwsh <SKILL_DIR>/ux-wireframe/scripts/wireframe.ps1
```

## Output

`ux-output/02-wireframes.md` — wireframe descriptions, navigation flowchart, IA diagram, responsive notes, plus any UXDEBTs appended to `ux-output/05-ux-debts.md`.
