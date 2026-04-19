---
name: dev-validation
description: Phase 4 of the Developer workflow — validates design completeness and consistency through automated checks and manual questions, then compiles everything into a final sign-off document. Automated checks confirm all designs trace to requirements, all modules have test plans, and no blocking DDEBTs remain. Produces `dev-output/04-validation-report.md` and `dev-output/DEVELOPER-FINAL.md` for sign-off.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# Design & Code Quality Validation

## When to use

Fourth and final phase of the Developer workflow. Run it after all three design phases are complete:

- Phase 1: Detailed Design (01-detailed-design.md)
- Phase 2: Coding Standards (02-coding-plan.md)
- Phase 3: Unit Test Strategy (03-unit-test-plan.md)

Use it to:

- Validate design completeness and consistency
- Check for circular module dependencies
- Confirm all APIs have schemas and error codes
- Verify test strategy covers all modules
- Sign off on readiness for implementation

## Automated Checks

- Does detailed design trace back to each ADR from architecture?
- Does every module have an assigned owner and build sequence?
- Are there any circular module dependencies?
- Does every major API endpoint have request/response schema?
- Do all async flows have explicit error handling?
- Are there any blocking (🔴) DDEBTs?

## Manual Questions (asked to user)

- Can a mid-level developer pick up any module and understand in 30 minutes?
- Are error codes and validation rules consistent across modules?
- Is the primary business flow clearly documented?
- Is the testing strategy aligned with team skill and CI/CD capacity?
- Are all stakeholders aware of their dependencies?

## Sign-Off Marks

- ✅ **READY FOR CODE** — design locked, all checks passed
- ⚠️ **READY WITH CAVEATS** — minor gaps tracked as DDEBTs
- ❌ **NOT READY** — resolve issues before coding starts

## How to invoke

```bash
bash <SKILL_DIR>/dev-validation/scripts/validate.sh
```

```powershell
pwsh <SKILL_DIR>/dev-validation/scripts/validate.ps1
```

## Output

- Validation report: `dev-output/04-validation-report.md` (all checks and findings)
- Final deliverable: `dev-output/DEVELOPER-FINAL.md` (sign-off document)
