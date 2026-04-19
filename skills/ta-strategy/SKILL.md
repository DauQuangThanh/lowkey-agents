---
name: ta-strategy
description: Phase 1 of the Test Architect workflow — captures the overall test approach (risk-based, requirement-based, exploratory, hybrid), test levels (unit/integration/system/E2E/UAT), test types (functional/performance/security/accessibility/compatibility), automation vs manual ratio target, test data management approach, defect management process, test metrics to track, and test exit criteria. Writes output to `ta-output/01-test-strategy.md`. Initiates the shared test-debt register at `ta-output/06-ta-debts.md`.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# Test Strategy Design

## When to use

First phase of the Test Architect workflow. Run it when starting to design the test approach for a project or major feature.

## What it captures

| Field | Purpose |
| --- | --- |
| Test Approach | Risk-based, requirement-based, exploratory, or hybrid |
| Test Levels | Which levels (unit/integration/system/E2E/UAT) are in scope |
| Test Types | Which types (functional/performance/security/accessibility/compatibility) are required |
| Automation vs Manual Ratio | Target % of tests to automate |
| Test Data Management | How test data will be created, refreshed, and managed |
| Defect Management | Tool and process for reporting, tracking, and prioritizing bugs |
| Test Metrics & KPIs | What metrics matter (code coverage %, defect escape rate, etc.) |
| Test Exit Criteria | When testing is considered "done" (all critical tests pass, coverage threshold met, UAT sign-off, etc.) |

## How to invoke

```bash
bash <SKILL_DIR>/ta-strategy/scripts/strategy.sh
```

```powershell
pwsh <SKILL_DIR>/ta-strategy/scripts/strategy.ps1
```

The script asks 8 interactive questions and generates the output file.

## Output

- Main document: `ta-output/01-test-strategy.md` (test strategy overview)
- Debt register initialized: `ta-output/06-ta-debts.md` (if not already present)
