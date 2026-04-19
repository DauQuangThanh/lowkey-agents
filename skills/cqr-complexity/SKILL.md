---
name: cqr-complexity
description: Phase 2 of the Code Quality Reviewer workflow — analyzes cyclomatic complexity, function/file length, dependency coupling, and identifies maintainability hotspots. Asks 6 structured questions about modules to analyze, complexity thresholds, function/file size limits, coupling concerns, and known technical debt areas. Writes output to `cqr-output/02-complexity-report.md`. Confirms each answer with the user before locking it in.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Complexity & Maintainability Analysis

## When to use

Second phase of the Code Quality Reviewer workflow. Run it whenever:

- You need to measure cyclomatic complexity and identify complex functions
- You want to identify functions or files that are too large or too complex
- You need to analyze dependency coupling and circular dependencies
- You want to pinpoint refactoring hotspots ranked by impact

## What it captures

| Field | Purpose |
|---|---|
| Modules/files to analyze | Which code should be analyzed for complexity? |
| Cyclomatic complexity thresholds | Max acceptable CC per function (typical: 10) |
| Function length limits | Max acceptable function LOC (typical: 20-50) |
| File size limits | Max acceptable file LOC (typical: 300-500) |
| Dependency coupling analysis | Which modules are tightly coupled? |
| Known technical debt | What areas are intentionally complex or not yet refactored? |

## How to invoke

```bash
bash <SKILL_DIR>/cqr-complexity/scripts/complexity.sh
```

```powershell
pwsh <SKILL_DIR>/cqr-complexity/scripts/complexity.ps1
```

The script guides the user through 6 questions interactively, asking for confirmation of each answer before recording it.

## Output

- Main file: `cqr-output/02-complexity-report.md` (metrics, hotspots, coupling analysis)
- Complexity metrics are tabulated for easy review
- Refactoring candidates are ranked by impact
- Hotspots and problematic modules are logged as CQDEBTs to `cqr-output/05-cq-debts.md`
- User is shown a summary of findings and improvement recommendations at the end
