---
name: test-planning
description: Phase 1 of the Tester workflow — defines test scope, test levels, test approach, environments, entry/exit criteria, risk-based priorities, and testing schedule. Use at the start of a testing engagement or when the user wants to document a test strategy. Reads from ba-output/ and arch-output/ (if available) to understand requirements and architecture. All answers are y/n, numbered choices, or one-line text. Missing/unclear answers are auto-logged as Test Quality Debts.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# Test Planning

## When to use

This is the first phase of the Tester workflow. Run it when:

- A new software project is starting testing activities.
- The user says "I want to create a test strategy" / "let's plan testing".
- The existing test plan file (`test-output/01-test-plan.md`) is missing or stale.

## What it captures

Eight questions, all answered via numbered choices, y/n, or a short sentence:

1. Test scope (which user stories/features are in scope)
2. Test levels needed (Unit, Integration, System, UAT)
3. Test approach (Manual, Automated, Hybrid)
4. Test environments available (Dev, Staging, UAT, Production)
5. Entry criteria (what must be true before testing starts)
6. Exit criteria (what must be true for testing to be complete)
7. Risk-based priorities (which features need most testing)
8. Testing schedule (estimated effort, timeline)

Any blank or "not decided" answer is logged to `test-output/05-test-debts.md` with an explanation of its impact.

## How to invoke

```bash
bash <SKILL_DIR>/test-planning/scripts/plan.sh
```

```powershell
pwsh <SKILL_DIR>/test-planning/scripts/plan.ps1
```

## Output

`test-output/01-test-plan.md` — a markdown summary of the test strategy, plus any debts appended to `test-output/05-test-debts.md`.
