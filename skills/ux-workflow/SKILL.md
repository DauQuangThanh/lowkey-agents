---
name: ux-workflow
description: Orchestrator that runs all UX Designer workflow phases in sequence (1→2→3→4). Executes User Research, Wireframes, Mockups, and Validation phases. Ideal for running a complete UX design pass from start to finish without manual invocation of individual skills. Produces all phase outputs plus final deliverable `UX-DESIGNER-FINAL.md`.
license: MIT
compatibility: Requires Bash 3.2+ (macOS/Linux) or PowerShell 5.1+/7+ (Windows/any). No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "0"
---

# UX Designer Workflow Orchestrator

## When to use

When you want to run the entire UX design workflow from start to finish without manually invoking each skill individually.

## What it does

Executes all four UX phases in sequence:

1. **Phase 1 — User Research & Personas** (`ux-research`)
2. **Phase 2 — Wireframes & Information Architecture** (`ux-wireframe`)
3. **Phase 3 — Mockup & Prototype Specification** (`ux-prototype`)
4. **Phase 4 — UX Review & Validation** (`ux-validation`)

If any phase fails, the workflow stops and reports the error.

## How to invoke

```bash
bash <SKILL_DIR>/ux-workflow/scripts/run-all.sh
```

```powershell
pwsh <SKILL_DIR>/ux-workflow/scripts/run-all.ps1
```

## Output

- `ux-output/01-user-research.md`
- `ux-output/02-wireframes.md`
- `ux-output/03-prototype-spec.md`
- `ux-output/04-ux-validation.md`
- `ux-output/05-ux-debts.md` (cumulative)
- `ux-output/UX-DESIGNER-FINAL.md` (compiled deliverable)

## Time estimate

Approximately 30–45 minutes depending on design complexity and how quickly you can answer design questions.
