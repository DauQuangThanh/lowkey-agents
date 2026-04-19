---
name: dev-workflow
description: Orchestrator skill that runs all four Developer workflow phases in sequence (Detailed Design → Coding Standards → Unit Test Strategy → Validation). Runs the workflow through all phases with confirmation between each phase, or skips to a specific phase on request. Produces all output files and final DEVELOPER-FINAL.md sign-off document.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "workflow"
---

# Developer Workflow Orchestrator

## When to use

Run this skill when you want to execute all four Developer workflow phases in one session (or skip individual phases as needed):

1. **Phase 1:** Detailed Design — module/class structures, APIs, database schema
2. **Phase 2:** Coding Standards — naming, file structure, dependencies, branching, code review
3. **Phase 3:** Unit Test Strategy — framework, coverage, mocking, CI/CD integration
4. **Phase 4:** Validation — sign-off and compilation into DEVELOPER-FINAL.md

Alternatively, run individual skills (`dev-design`, `dev-coding`, `dev-unit-test`, `dev-validation`) to focus on a single phase.

## How to invoke

```bash
bash <SKILL_DIR>/dev-workflow/scripts/run-all.sh
```

```powershell
pwsh <SKILL_DIR>/dev-workflow/scripts/run-all.ps1
```

## Workflow

1. Checks if `arch-output/` exists and confirms architecture baseline
2. Runs Phase 1 (Detailed Design)
3. Asks: "Continue to Phase 2? (y/n/s for skip/q to quit)"
4. Runs Phase 2 (Coding Standards) if continuing
5. Repeats for Phases 3 and 4
6. Produces final sign-off document

## Output

All intermediate files in `dev-output/`:
- `01-detailed-design.md`
- `02-coding-plan.md`
- `03-unit-test-plan.md`
- `04-validation-report.md`
- `05-design-debts.md`
- `DEVELOPER-FINAL.md` (complete, signed-off specification)

## Env variables

- `DEV_OUTPUT_DIR` — output folder (default: `./dev-output`)
- `DEV_ARCH_INPUT_DIR` — architecture input (default: `./arch-output`)
