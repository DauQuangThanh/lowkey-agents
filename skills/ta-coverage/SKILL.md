---
name: ta-coverage
description: Phase 3 of the Test Architect workflow — analyzes test coverage needs. Creates requirement-to-test-case traceability, sets coverage targets (statement/branch/requirement), performs risk-based prioritization (which areas get the most test effort), and identifies coverage gaps. Writes output to `ta-output/03-coverage-matrix.md`.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash, Read
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Test Coverage Analysis

## When to use

Third phase of the Test Architect workflow. Run it after test strategy (Phase 1) and test framework design (Phase 2) are locked. Reads requirements from `ba-output/` to create traceability.

## What it captures

| Field | Purpose |
| --- | --- |
| Requirements to Cover | Functional, non-functional, user stories, acceptance criteria, edge cases (from BA output) |
| Coverage Target % | Minimum code coverage (statement/branch/path) and requirements coverage |
| Traceability Approach | How to map requirements → test cases (matrix, tool, git-versioned) |
| Risk-Based Prioritization | Which areas get the most test effort (critical flows, complex logic, high-failure history) |
| Coverage Metrics | What to measure (statement %, branch %, requirement %, feature %, user journey %) |
| Gap Analysis | Identify under-tested zones and recommend high-impact tests to add |

## How to invoke

```bash
bash <SKILL_DIR>/ta-coverage/scripts/coverage.sh
```

```powershell
pwsh <SKILL_DIR>/ta-coverage/scripts/coverage.ps1
```

The script asks 6 interactive questions and generates the output file.

## Output

- Main document: `ta-output/03-coverage-matrix.md` (coverage analysis and traceability matrix)
