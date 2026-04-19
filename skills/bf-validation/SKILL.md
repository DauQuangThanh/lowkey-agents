---
name: bf-validation
description: Phase 5 of the Bug-Fixer workflow — cross-checks that every applied fix has a regression test, runs an optional VALIDATION_COMMAND, and compiles BF-FINAL.md with the verdict (READY / CONDITIONAL / NOT READY / NO CHANGES). Produces the hand-off checklist for PR and downstream re-runs.
license: MIT
compatibility: Bash 3.2+ / PowerShell 5.1+
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "5"
---

# Validation

Automated checks:

- Every `FIXED_IDS` entry has at least one regression test
- Optional `VALIDATION_COMMAND` (e.g. `npm test`, `pytest -q`) runs clean
- Missing checks auto-log BFDEBT entries

## Canonical answer keys

- `VALIDATION_COMMAND` (default empty — manual)
- `RUN_UPSTREAM_REREVIEW` (default no)

## Invocation

```bash
bash <SKILL_DIR>/bf-validation/scripts/validate.sh
pwsh <SKILL_DIR>/bf-validation/scripts/validate.ps1
```
