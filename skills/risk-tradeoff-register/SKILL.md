---
name: risk-tradeoff-register
description: Phase 5 of the Architect workflow — captures architectural **Risks** (RISK-NN) and **Technical Debts** (TDEBT-NN) in a single register. For each risk, records description / likelihood (Low-Med-High) / impact (Low-Med-High) / proactive mitigation / reactive contingency / owner / linked ADR or requirement / status. For each TDEBT, records area / description / impact / owner / priority (🔴 Blocking / 🟡 Important / 🟢 Can Wait) / target date / linked ADR. Reviews debts already logged by earlier phases, lets the user assign owners, and loops to add new items. Shares format with the BA's requirement-debt register so both can be reviewed together.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "5"
---

# Risk & Trade-off Register

## When to use

Fifth phase of the Architect workflow. Run it when:

- The architecture is substantially defined (ADRs + C4) and you need to make the things that
  could bite the project visible and owned.
- The BA or architect has logged TDEBTs/risks throughout earlier phases that now need priority,
  owner, and target dates.
- `arch-output/05-technical-debts.md` exists but lacks risk entries.

## What it captures

**Risks** (RISK-NN):
- Description
- Likelihood: Low / Medium / High
- Impact: Low / Medium / High
- Proactive mitigation (what we do to prevent it)
- Reactive contingency (what we do if it happens)
- Owner
- Linked ADR / Requirement ID
- Status: Open / Mitigated / Accepted / Closed

**Technical Debts** (TDEBT-NN) — see Phase 5 header in
[architect.md](../../agents/architect.md) for rules.

## How to invoke

```bash
bash <SKILL_DIR>/risk-tradeoff-register/scripts/register.sh
```

```powershell
pwsh <SKILL_DIR>/risk-tradeoff-register/scripts/register.ps1
```

The script loops for both RISK and TDEBT entries; you can add as many as you like per session.

## Output

`arch-output/05-technical-debts.md` — combined Risk + Technical Debt register with a header,
summary counters (🔴/🟡/🟢), and all entries in a consistent format. Warns on any
High-likelihood / High-impact risk without a mitigation.
