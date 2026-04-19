---
name: pm-risk
description: Phase 3 of the Project Manager workflow — establishes risk management with identification, assessment, and mitigation planning. Captures risk description, likelihood (1-5), impact (1-5), mitigation strategy, contingency plan, owner, and category. Computes risk scores and generates a risk register. Writes output to `pm-output/03-risk-register.md`.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Risk Management

## When to use

Third phase of the Project Manager workflow. Run it after the project plan is locked. Use it to:

- Identify all potential project risks
- Assess likelihood and impact
- Prioritise risks using a risk matrix
- Plan mitigation strategies
- Define contingency plans
- Assign risk owners

## What it captures

For each risk:
- **Description** — what could go wrong?
- **Likelihood** — 1 (Rare) to 5 (Almost certain)
- **Impact** — 1 (Negligible) to 5 (Critical)
- **Risk Score** — Likelihood × Impact (15+ = Red, 8-14 = Amber, 5-7 = Green)
- **Category** — Technical / Schedule / Resource / Budget / Scope / External
- **Mitigation Strategy** — what will you do to reduce likelihood or impact?
- **Contingency Plan** — what's the backup if risk occurs?
- **Risk Owner** — who monitors this risk?

Risks are added one at a time in a loop. User can add as many as needed.

## How to invoke

```bash
bash <SKILL_DIR>/pm-risk/scripts/risk.sh
```

```powershell
pwsh <SKILL_DIR>/pm-risk/scripts/risk.ps1
```

## Output

`pm-output/03-risk-register.md` — a risk register with all identified risks, scored and prioritised, with mitigation and contingency plans for each.
