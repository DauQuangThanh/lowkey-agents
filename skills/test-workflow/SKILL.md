---
name: test-workflow
description: Orchestrator for the complete Tester workflow — runs all 4 phases in sequence (test-planning, test-case-design, test-execution, test-report). Use to execute the entire testing lifecycle in one command. Produces all output files (01-test-plan.md through TESTER-FINAL.md) and a consolidated test-debts file.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "orchestrator"
---

# Test Workflow Orchestrator

## When to use

Run this orchestrator when:

- You want to execute the complete testing lifecycle (all 4 phases) in one session.
- The user says "I want to run the entire test workflow" / "let's test this project end-to-end".
- You want to create all test artifacts (plan, cases, execution, report) in a single pass.

## What it does

Executes phases in sequence:

1. **Phase 1:** Test Planning — defines scope, approach, environments, criteria
2. **Phase 2:** Test Case Design — writes detailed test cases
3. **Phase 3:** Test Execution — runs tests, logs bugs, tracks blockers
4. **Phase 4:** Test Summary Report — analyzes coverage, metrics, release recommendation

All outputs go to `test-output/` and all debts accumulate in `test-output/05-test-debts.md`.

## How to invoke

```bash
bash <SKILL_DIR>/test-workflow/scripts/run-all.sh
```

```powershell
pwsh <SKILL_DIR>/test-workflow/scripts/run-all.ps1
```

## Output

- `test-output/01-test-plan.md` — test strategy
- `test-output/02-test-cases.md` — test cases
- `test-output/03-test-execution.md` — execution results
- `test-output/04-test-report.md` — detailed report
- `test-output/TESTER-FINAL.md` — executive summary
- `test-output/05-test-debts.md` — consolidated test quality debts
