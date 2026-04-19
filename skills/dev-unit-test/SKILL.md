---
name: dev-unit-test
description: Phase 3 of the Developer workflow — designs a testable architecture and specifies testing framework, coverage targets, test naming conventions, mocking strategy, test data, test categories, CI/CD integration, and mutation testing. Asks 7–8 structured questions to lock down the unit test strategy. Writes output to `dev-output/03-unit-test-plan.md`. Confirms each answer with the user before locking it in.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Unit Test Strategy & Generation

## When to use

Third phase of the Developer workflow. Run it after coding standards are established. Use it to:

- Choose testing frameworks (Jest, Pytest, JUnit, etc.)
- Set coverage targets (overall %, core domain %, by module)
- Define test naming and structure conventions
- Plan what to mock vs. test end-to-end
- Design test data strategy (fixtures, factories, realistic data)
- Categorize tests (unit, integration, smoke, E2E)
- Integrate tests into CI/CD (gates, parallel, fail-fast)
- Plan mutation testing and performance benchmarks

## What it captures

| Field | Purpose |
|---|---|
| Testing framework | Language-specific: Jest, Pytest, JUnit, etc. |
| Coverage target | Overall %, by module/layer, branch vs. line coverage |
| Test naming | Convention: `test<MethodName>_<Scenario>_<Expected>` |
| Structure | 1:1 with source, or grouped by feature |
| Mock strategy | What to mock (external APIs, DB), what to test real |
| Test data | Fixtures, factories, realistic or minimal |
| Test categories | Unit, integration, smoke, E2E |
| CI/CD integration | Gates, parallelization, fail-fast strategy |
| Mutation testing | Plan to use PIT, mutants, or similar tools |
| Benchmarks | Performance tests for critical paths |

## How to invoke

```bash
bash <SKILL_DIR>/dev-unit-test/scripts/unit-test.sh
```

```powershell
pwsh <SKILL_DIR>/dev-unit-test/scripts/unit-test.ps1
```

The script guides the user through 7–8 questions interactively, asking for confirmation of each answer.

## Output

- Main file: `dev-output/03-unit-test-plan.md` (all test strategy and coverage decisions)
- Any open questions are logged as DDEBTs
