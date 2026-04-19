---
name: ux-validation
description: Phase 4 of the UX Designer workflow — validates the complete UX design against Nielsen's 10 usability heuristics, requirement traceability, and accessibility compliance. Performs automated checks (user story coverage, accessibility needs met, responsive design defined, interaction patterns specified) and manual questions (stakeholder sign-off? design decisions finalized? open UX Debts?). Produces UX validation report with heuristics checklist, coverage matrix, and sign-off block. Compiles all phases into final deliverable `ux-output/UX-DESIGNER-FINAL.md`. Marks session as APPROVED / CONDITIONALLY APPROVED / NOT READY.
license: MIT
compatibility: Requires Bash 3.2+ (macOS/Linux) or PowerShell 5.1+/7+ (Windows/any). No network access required.
allowed-tools: Bash, Glob, Grep, Read
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# UX Review & Validation

## When to use

The fourth phase of the UX Designer workflow. Run it when:

- All previous phases (research, wireframes, mockups) are complete and ready for sign-off.
- The user is ready to hand the UX design off to engineering for implementation.
- A final validation and approval record is needed.

## What it does

1. **Automated checks:**
   - Do all user stories from `ba-output/` map to wireframe screens?
   - Are all user scenarios covered in user journeys?
   - Are accessibility needs from Phase 1 explicitly addressed?
   - Are responsive design breakpoints defined?
   - Are all interaction patterns (forms, tables, modals) specified?
   - Any open 🔴 Blocking UX Debts?

2. **Nielsen's 10 Heuristics checklist:** Scores design against usability best practices

3. **Manual sign-off questions:** Stakeholder approval, design finality, handoff readiness

4. **Compilation:** Merges all phases into `ux-output/UX-DESIGNER-FINAL.md`

## How to invoke

```bash
bash <SKILL_DIR>/ux-validation/scripts/validate.sh
```

```powershell
pwsh <SKILL_DIR>/ux-validation/scripts/validate.ps1
```

## Output

`ux-output/04-ux-validation.md` — heuristics checklist, coverage matrix, open debts
`ux-output/UX-DESIGNER-FINAL.md` — complete UX design package (research → wireframes → mockups → validation → sign-off)
