---
name: bf-triage
description: Phase 1 of the Bug-Fixer workflow — parses `test-output/bugs.md`, `cqr-output/05-cq-debts.md`, and `csr-output/*.md` into a unified work-list, filters by severity, sorts by priority, and caps the batch at TRIAGE_MAX_ITEMS. Emits 01-triage.md for humans and 01-triage.extract (plus .triage-head.tmp) consumed by bf-fix.
license: MIT
compatibility: Bash 3.2+ / PowerShell 5.1+
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# Triage

Reads the three upstream sources and produces a prioritised batch.

## Canonical answer keys

- `TRIAGE_MAX_ITEMS` (default `10`)
- `TRIAGE_MIN_SEVERITY` — `Critical` / `Major` / `Minor` / `Trivial`
- `TRIAGE_INCLUDE_SOURCES` — `bugs` | `bugs,cqdebt` | `bugs,cqdebt,csdebt` | `bugs,cqdebt,csdebt-all`

## Invocation

```bash
bash <SKILL_DIR>/bf-triage/scripts/triage.sh [--auto] [--answers FILE]
pwsh <SKILL_DIR>/bf-triage/scripts/triage.ps1 [-Auto] [-Answers FILE]
```
