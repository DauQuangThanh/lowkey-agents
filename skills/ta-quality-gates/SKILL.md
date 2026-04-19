---
name: ta-quality-gates
description: Phase 4 of the Test Architect workflow — defines quality gates and pass/fail criteria. Specifies gate checkpoints (per commit, per sprint, per environment, pre-release), pass/fail criteria (test success, code coverage threshold, performance benchmarks, security scans, manual approvals). Writes output to `ta-output/04-quality-gates.md`.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# Quality Gate Definitions

## When to use

Fourth phase of the Test Architect workflow. Run it after test coverage is analyzed (Phase 3). Defines the checkpoints where testing determines readiness to proceed.

## What it captures

| Field | Purpose |
| --- | --- |
| Gate Checkpoints | Where in the pipeline gates apply (per commit, per sprint, per environment, pre-release) |
| Pass/Fail Criteria per Gate | What must be true to proceed (unit tests pass, coverage threshold, zero critical defects, UAT sign-off) |
| Code Coverage Threshold | Minimum % acceptable per gate (unit 90%, integration 60%, overall 80%) |
| Performance Benchmarks | Acceptable API response time, page load time, throughput, memory/CPU usage |
| Security Scan Requirements | SAST, DAST, dependency scanning, OWASP Top 10 checks |
| Manual Approval Gates | Which gates require human sign-off (security, UAT, release) |

## How to invoke

```bash
bash <SKILL_DIR>/ta-quality-gates/scripts/quality-gates.sh
```

```powershell
pwsh <SKILL_DIR>/ta-quality-gates/scripts/quality-gates.ps1
```

The script asks 6 interactive questions and generates the output file.

## Output

- Main document: `ta-output/04-quality-gates.md` (quality gate definitions and pass/fail criteria)
