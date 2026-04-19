---
name: cqr-standards
description: Phase 1 of the Code Quality Reviewer workflow — audits coding standards including naming conventions, file structure, import ordering, comment/documentation standards, linting tools, and known deviations. Asks 8 structured questions about languages, style guides, naming rules, file structure, import ordering, documentation, linting, and deviations. Writes output to `cqr-output/01-standards-review.md`. Confirms each answer with the user before locking it in.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# Coding Standards Review

## When to use

First phase of the Code Quality Reviewer workflow. Run it whenever:

- You need to audit code for adherence to naming conventions, file structure, import ordering
- You want to check documentation and comment standards across the codebase
- You need to verify linting tool configuration and enforcement
- You want to document baseline standards before deeper quality analysis

## What it captures

| Field | Purpose |
|---|---|
| Programming language(s) | What is the codebase written in? |
| Coding style guide | Which style guide is in use (Airbnb/Google/PEP8/custom)? |
| Naming conventions | Rules for variables, functions, classes, modules, constants |
| File/folder structure | Directory layout and organizational patterns |
| Import/dependency ordering | How imports are sorted and organized |
| Comment/documentation standards | Docstring format, comment style, README requirements |
| Linting & formatting tools | ESLint, Pylint, Prettier, Black, etc. and their configs |
| Known deviations | Any documented or legacy exceptions to standards |

## How to invoke

```bash
bash <SKILL_DIR>/cqr-standards/scripts/standards.sh
```

```powershell
pwsh <SKILL_DIR>/cqr-standards/scripts/standards.ps1
```

The script guides the user through 8 questions interactively, asking for confirmation of each answer before recording it.

## Output

- Main file: `cqr-output/01-standards-review.md` (all standards decisions)
- Standards are recorded in a table and checklist format for easy reference
- Any standards not yet documented or unclear are logged as CQDEBTs to `cqr-output/05-cq-debts.md`
- User is shown a summary of findings and debt entries at the end
