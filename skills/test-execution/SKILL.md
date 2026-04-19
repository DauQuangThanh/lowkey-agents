---
name: test-execution
description: Phase 3 of the Tester workflow — runs test cases, records pass/fail/blocked status, logs and classifies bugs, and tracks retests. Generates detailed execution reports with bug records by severity/priority, blocker tracking, and retest status. Use during testing to document test results and defect status.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Test Execution & Bug Tracking

## When to use

This is the third phase of the Tester workflow. Run it when:

- You are executing test cases against the system.
- The user says "I want to track test results" / "log bugs I found".
- The existing execution report (`test-output/03-test-execution.md`) needs to be created or updated.

## What it captures

6–8 questions:

1. Execution round ID (e.g., "Round 1", "Sprint 3 UAT")
2. Which test cases are being executed
3. Pass/fail/blocked status per case
4. For each failure: bug ID, title, description, severity, priority, reproducibility
5. For each blocker: what is blocking, who can unblock, ETA
6. Retested bugs and their status

## How to invoke

```bash
bash <SKILL_DIR>/test-execution/scripts/execute.sh
```

```powershell
pwsh <SKILL_DIR>/test-execution/scripts/execute.ps1
```

## Output

`test-output/03-test-execution.md` — execution summary with test results by case/story, detailed bug records (severity/priority), blocker tracking, and retest status.
