---
name: cqr-workflow
description: Orchestrator for the Code Quality Reviewer workflow — runs all 4 phases sequentially (Standards → Complexity → Patterns → Report) in one invocation. Executes phases 1-3 with user input, then automatically aggregates findings into final report and recommendations. Produces complete quality review output (`cqr-output/CQR-FINAL.md`) in a single session.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "0"
---

# Code Quality Reviewer Workflow Orchestrator

## When to use

Run the complete code quality review in a single session:

- When you want to perform a comprehensive quality audit from start to finish
- When you want standards, complexity, patterns, and final report in one pass
- When onboarding a new codebase and need a baseline quality score
- When preparing for a code quality initiative or refactoring sprint

## What it does

The orchestrator runs all 4 phases in sequence:

1. **Phase 1: Coding Standards Review** — Establish standards baseline (8 questions)
2. **Phase 2: Complexity & Maintainability** — Measure complexity and hotspots (6 questions)
3. **Phase 3: Design Pattern & Architecture** — Validate design patterns and SOLID (6 questions)
4. **Phase 4: Quality Report** — Aggregate findings and generate recommendations (automated)

Total time: 20–30 minutes including user input.

## How to invoke

```bash
bash <SKILL_DIR>/cqr-workflow/scripts/run-all.sh
```

```powershell
pwsh <SKILL_DIR>/cqr-workflow/scripts/run-all.ps1
```

## Output

All outputs are written to `cqr-output/`:

| File | Purpose |
|---|---|
| `01-standards-review.md` | Phase 1: Standards baseline and findings |
| `02-complexity-report.md` | Phase 2: Complexity metrics and hotspots |
| `03-patterns-review.md` | Phase 3: SOLID audit and pattern compliance |
| `04-quality-report.md` | Phase 4: Detailed findings by severity |
| `05-cq-debts.md` | Technical debt registry (CQDEBT-NN) |
| `CQR-FINAL.md` | Executive summary and actionable roadmap |

## Skip a Phase

To run individual phases:

```bash
# Phase 1 only
bash <SKILL_DIR>/cqr-standards/scripts/standards.sh

# Phase 2 only
bash <SKILL_DIR>/cqr-complexity/scripts/complexity.sh

# Phase 3 only
bash <SKILL_DIR>/cqr-patterns/scripts/patterns.sh

# Phase 4 only (requires phases 1–3 output)
bash <SKILL_DIR>/cqr-report/scripts/report.sh
```

PowerShell equivalents use `.ps1` instead of `.sh`.

## Requirements

Before running:

1. ✅ Codebase is accessible and readable
2. ✅ Know the primary language(s) used (Python, JavaScript, Go, Java, etc.)
3. ✅ (Optional) Have a copy of `dev-output/` from the Developer workflow for standards context
4. ✅ (Optional) Have a copy of `arch-output/` from the Architect workflow for pattern validation
