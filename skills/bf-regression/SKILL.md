---
name: bf-regression
description: Phase 3 of the Bug-Fixer workflow — for every FIXED id from Phase 2, writes a regression test stub pulled from the matching Steps to Reproduce / Expected fields in bugs.md. The tester subagent consumes 03-regression-tests.md on its next run to merge the new cases into test-output/02-test-cases.md.
license: MIT
compatibility: Bash 3.2+ / PowerShell 5.1+
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Regression tests

Creates one test stub per applied fix. Does not execute tests — just generates the skeleton. The `REGRESSION_TEST_FRAMEWORK` and `REGRESSION_TEST_PATH` hints guide the tester when merging.

## Canonical answer keys

- `REGRESSION_TEST_FRAMEWORK` — Jest / Pytest / JUnit / xUnit / Go test / Other
- `REGRESSION_TEST_PATH` — e.g. `tests/regression/`

## Invocation

```bash
bash <SKILL_DIR>/bf-regression/scripts/regression.sh [--auto] [--answers FILE]
pwsh <SKILL_DIR>/bf-regression/scripts/regression.ps1 [-Auto] [-Answers FILE]
```
