---
name: requirements-validation
description: Phase 7 (final) of the Business Analyst workflow — runs a completeness checklist across all prior phases and compiles the final REQUIREMENTS-FINAL.md document. Performs 9 automated file/content checks (does each phase output exist, is the problem statement defined, do stories have acceptance criteria, are there any blocking debts, etc.) and 6 manual validation questions (stakeholder coverage, traceability, scope agreement, no contradictions, sign-off, must-have specificity). Produces a validation report with APPROVED / CONDITIONALLY APPROVED / NOT READY status.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "7"
---

# Requirements Validation & Sign-Off

## When to use

Phase 7 (the final phase) of the Business Analyst workflow. Run after phases 1–6 to verify completeness and compile the deliverable. Useful standalone to re-validate after changes.

## What it does

### Automated checks

Nine checks run against files in `ba-output/`:

1. Project intake file exists
2. Stakeholders file exists
3. Functional requirements file exists
4. User stories file exists
5. NFR file exists
6. Problem statement is defined (not TBD)
7. All user stories have acceptance criteria
8. No 🔴 Blocking debts open
9. Out-of-scope items defined

### Manual validation (y/n/unsure)

Six stakeholder-style questions:

1. Every stakeholder group represented in a user story?
2. Requirements trace back to problem statement?
3. Scope is clearly IN vs OUT?
4. No conflicting requirements?
5. Stakeholder sign-off obtained or planned?
6. Must-have stories specific enough to develop?

### Output

- `ba-output/07-validation-report.md` — pass/fail table and sign-off block
- `ba-output/REQUIREMENTS-FINAL.md` — the compiled final document (intake + stakeholders + requirements + user stories + NFRs + debts + validation report)

Status is one of ✅ APPROVED / ⚠️ CONDITIONALLY APPROVED / ❌ NOT READY.

## How to invoke

```bash
bash <SKILL_DIR>/requirements-validation/scripts/validate-requirements.sh
```

```powershell
pwsh <SKILL_DIR>/requirements-validation/scripts/validate-requirements.ps1
```
