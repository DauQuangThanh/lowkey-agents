---
name: ta-workflow
description: Orchestrator for the entire Test Architect workflow — runs Phases 1–5 in sequence (ta-strategy, ta-framework, ta-coverage, ta-quality-gates, ta-environment). Checks for upstream inputs (`ba-output/`, `arch-output/`), executes all phases, and compiles outputs into a single deliverable `ta-output/TA-FINAL.md` with executive summary, key decisions, test debt register, and sign-off block.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required (phases may use web access).
allowed-tools: Bash, Read, Write
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "orchestrator"
---

# Test Architect Workflow Orchestrator

## When to use

Run this when you want to execute all 5 phases of the Test Architect workflow in one session. It checks for upstream outputs (requirements, architecture), guides you through each phase, and produces a final compiled document.

## What it does

1. **Checks for upstream outputs** — looks for `ba-output/REQUIREMENTS-FINAL.md` and `arch-output/ARCHITECTURE-FINAL.md`
2. **Runs Phases 1–5 in sequence:**
   - Phase 1: Test Strategy Design (ta-strategy)
   - Phase 2: Test Automation Framework Design (ta-framework)
   - Phase 3: Test Coverage Analysis (ta-coverage)
   - Phase 4: Quality Gate Definitions (ta-quality-gates)
   - Phase 5: Test Environment Planning (ta-environment)
3. **Compiles outputs** into a final deliverable: `ta-output/TA-FINAL.md`
4. **Generates summary sections:**
   - Executive summary (test strategy overview)
   - Key decisions (framework choices, gate definitions)
   - Test debt register (TADEBT entries)
   - Sign-off block (approvals and dates)

## How to invoke

```bash
bash <SKILL_DIR>/ta-workflow/scripts/run-all.sh
```

```powershell
pwsh <SKILL_DIR>/ta-workflow/scripts/run-all.ps1
```

The orchestrator guides you through all phases interactively and consolidates the output.

## Output

- Phase outputs:
  - `ta-output/01-test-strategy.md`
  - `ta-output/02-automation-framework.md`
  - `ta-output/03-coverage-matrix.md`
  - `ta-output/04-quality-gates.md`
  - `ta-output/05-environment-plan.md`
- Final compiled document: `ta-output/TA-FINAL.md`
- Debt register: `ta-output/06-ta-debts.md`

## Notes

- If a phase script is unavailable or fails, the orchestrator falls back to guided Q&A mode.
- All outputs are markdown files suitable for git version control.
- The debt register is continuously updated across all phases.
