---
name: test-case-design
description: Phase 2 of the Tester workflow — writes detailed test cases with positive, negative, and boundary scenarios for user stories. Generates test cases in Given/When/Then (Gherkin) format with traceability to requirements. Use after test planning to design comprehensive test cases before execution. Reads from ba-output/ to map user stories and acceptance criteria.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Test Case Design

## When to use

This is the second phase of the Tester workflow. Run it when:

- You are ready to write test cases for user stories.
- The user says "I want to write test cases" / "design tests for this feature".
- The existing test case file (`test-output/02-test-cases.md`) is missing or needs expansion.

## What it captures

6–8 questions:

1. Which user story or feature to test
2. Positive scenarios (happy paths)
3. Negative scenarios (error conditions)
4. Boundary scenarios (edge cases)
5. Test data requirements
6. Expected results format
7. Traceability mapping (FR-xxx, NFR-yyy)
8. Any untested requirements

## How to invoke

```bash
bash <SKILL_DIR>/test-case-design/scripts/design-cases.sh
```

```powershell
pwsh <SKILL_DIR>/test-case-design/scripts/design-cases.ps1
```

## Output

`test-output/02-test-cases.md` — detailed test cases with Given/When/Then format, traceability matrix, and data requirements.
