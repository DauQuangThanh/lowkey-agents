---
name: test-report
description: Phase 4 of the Tester workflow — analyzes test coverage, metrics, open defects, and generates a final test summary report with release recommendation. Produces both detailed report (test-report.md) and executive summary (TESTER-FINAL.md). Use after test execution to validate coverage and determine release readiness.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash, Read
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# Test Summary Report & Validation

## When to use

This is the fourth and final phase of the Tester workflow. Run it when:

- You have completed test execution and want to analyse coverage and metrics.
- The user says "I want a test summary report" / "are we ready to release?"
- You need to validate that exit criteria have been met.

## What it captures

Automated checks from previous phases plus 2 key questions:

1. **Coverage validation:** Compare tested requirements vs. total requirements (target 95%+)
2. **Defect summary:** Count bugs by severity, status, density
3. **Test metrics:** Pass/fail/blocked counts, pass rate (target 90%+)
4. **Open issues:** List all P0/P1 bugs, blocked tests, untested requirements
5. **Release recommendation:** Go/no-go based on coverage, pass rate, open blockers

## How to invoke

```bash
bash <SKILL_DIR>/test-report/scripts/report.sh
```

```powershell
pwsh <SKILL_DIR>/test-report/scripts/report.ps1
```

## Output

- `test-output/04-test-report.md` — detailed report with metrics, open issues, debts, recommendations
- `test-output/TESTER-FINAL.md` — executive summary (1–2 pages) for stakeholders
