---
name: ta-framework
description: Phase 2 of the Test Architect workflow — selects and designs the test automation framework(s). Captures tech stack, automation tool selection (Selenium/Cypress/Playwright/Appium/Postman/k6/etc.), framework pattern (Page Object/Screenplay/Keyword-driven/BDD), test runner, reporting tool, CI/CD integration approach, parallel execution strategy, and test environment requirements. Writes output to `ta-output/02-automation-framework.md`.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. May require web access for tool research.
allowed-tools: Bash, WebSearch, WebFetch
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Test Automation Framework Design

## When to use

Second phase of the Test Architect workflow. Run it after the test strategy is locked (Phase 1) and the tech stack is known from the architect subagent.

## What it captures

| Field | Purpose |
| --- | --- |
| Tech Stack | Languages, frameworks, UI technology, APIs (from architect output) |
| Automation Tool Selection | Which tool(s) for UI/API/mobile/performance/security testing |
| Framework Pattern | Page Object Model, Screenplay, Keyword-driven, BDD, or Hybrid |
| Test Runner & Framework | JUnit, TestNG, Pytest, Mocha, Jest, Jasmine, etc. |
| Reporting & Observability | HTML reports, Allure, ReportPortal, metrics export |
| CI/CD Integration | How tests are triggered (on commit, scheduled, gated promotion) |
| Parallel Execution Strategy | Number of workers, test isolation, browser/device pool management |
| Test Environment Requirements | Browsers, devices, test data, infrastructure, network conditions |

## How to invoke

```bash
bash <SKILL_DIR>/ta-framework/scripts/framework.sh
```

```powershell
pwsh <SKILL_DIR>/ta-framework/scripts/framework.ps1
```

The script asks 8 interactive questions and generates the output file.

## Output

- Main document: `ta-output/02-automation-framework.md` (framework design spec)
