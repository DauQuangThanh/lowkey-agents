---
name: dev-coding
description: Phase 2 of the Developer workflow — establishes coding standards, file structure, dependency management, branching strategy, code review criteria, implementation order, and tech debt management. Asks 7–8 structured questions to lock down the conventions that keep the codebase consistent. Writes output to `dev-output/02-coding-plan.md`. Confirms each answer with the user before locking it in.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Coding Standards & Implementation Plan

## When to use

Second phase of the Developer workflow. Run it after the detailed design is locked. Use it to:

- Establish naming conventions (PascalCase, camelCase, prefixes, suffixes)
- Decide file and folder structure (by layer, by feature, hybrid)
- Lock down dependency management (versions, pinning strategy)
- Define branching and release strategy
- Create a code review checklist
- Prioritize the implementation sequence
- Plan tech debt management

## What it captures

| Field | Purpose |
|---|---|
| Naming conventions | Types, functions, files, abbreviations, prefixes, suffixes |
| File & folder structure | Layers vs. features, nesting depth, import rules |
| Dependency management | Package manager, version pinning, vendoring |
| Branching strategy | Trunk-based, GitFlow, feature branches, release cadence |
| Code review checklist | Criteria, approvers, turnaround time, tooling |
| Implementation order | Build sequence, dependencies, critical path |
| Tech debt management | Tracking, priority, in-sprint vs. dedicated sprints |
| Testing integration | Unit tests, CI/CD gates, coverage requirements |

## How to invoke

```bash
bash <SKILL_DIR>/dev-coding/scripts/coding.sh
```

```powershell
pwsh <SKILL_DIR>/dev-coding/scripts/coding.ps1
```

The script guides the user through 7–8 questions interactively, asking for confirmation of each answer.

## Output

- Main file: `dev-output/02-coding-plan.md` (all coding standards and implementation plan)
- Any open questions or uncertain choices are logged as DDEBTs
