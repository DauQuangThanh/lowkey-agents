---
name: cqr-patterns
description: Phase 3 of the Code Quality Reviewer workflow — validates design pattern adherence, SOLID principles compliance, DRY (Don't Repeat Yourself) violations, separation of concerns, error handling patterns, and logging consistency. Asks 6 structured questions about expected patterns, SOLID priorities, DRY concerns, SoC boundaries, error handling strategy, and logging patterns. Writes output to `cqr-output/03-patterns-review.md`. Confirms each answer with the user before locking it in.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Design Pattern & Architecture Compliance

## When to use

Third phase of the Code Quality Reviewer workflow. Run it whenever:

- You need to validate adherence to SOLID principles
- You want to check code against expected design patterns from architecture
- You need to identify DRY (Don't Repeat Yourself) violations and duplication
- You want to audit separation of concerns boundaries
- You need to assess error handling and logging consistency

## What it captures

| Field | Purpose |
|---|---|
| Expected design patterns | What patterns should the code follow? (from architecture) |
| SOLID principles focus | Which SOLID rules are priorities? (S, O, L, I, D) |
| DRY violations | Where is code being repeated? |
| Separation of concerns | Are business logic, persistence, and API properly separated? |
| Error handling patterns | What approach is used for error handling? |
| Logging patterns | What logging strategy is in place? |

## How to invoke

```bash
bash <SKILL_DIR>/cqr-patterns/scripts/patterns.sh
```

```powershell
pwsh <SKILL_DIR>/cqr-patterns/scripts/patterns.ps1
```

The script guides the user through 6 questions interactively, asking for confirmation of each answer before recording it.

## Output

- Main file: `cqr-output/03-patterns-review.md` (SOLID audit, pattern compliance, code smells)
- SOLID principles assessed with evidence and examples
- DRY violations cataloged by frequency and impact
- Separation of concerns issues identified
- Error handling and logging gaps noted
- All findings logged as CQDEBTs to `cqr-output/05-cq-debts.md`
- Code smells catalog included for reference
