---
name: architecture-intake
description: Phase 1 of the Architect workflow — locks down the inputs that shape every architecture decision. Captures quality-attribute priorities (performance / security / scalability / availability / maintainability / cost / time-to-market), hard constraints (cloud/on-prem, approved vendors, licences, data residency, compliance regimes), team context (size, skills, hiring plans), operational envelope (users, QPS, data volume, SLA, RTO/RPO), integration surface, and deployment preferences. Reads `ba-output/REQUIREMENTS-FINAL.md` when present to avoid duplicating BA work. Unknowns are auto-logged as Technical Debts (TDEBT-NN). All answers are y/n, numbered choices, or a short sentence.
license: MIT
compatibility: Requires Bash 3.2+ (macOS/Linux) or PowerShell 5.1+/7+ (Windows/any). No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# Architecture Intake

## When to use

The first phase of the Architect workflow. Run it when:

- The business-analyst has finished (or the requirements are otherwise known) and design must begin.
- The user asks "what stack should we use?" / "how should we architect this?" — before answering, capture the drivers.
- The intake file (`arch-output/01-architecture-intake.md`) is missing or stale.

## What it captures

1. Ranked quality-attribute priorities (NFR drivers)
2. Hard constraints (cloud, vendors, licences, residency, compliance)
3. Team size and skill-set signals
4. Operational envelope (users, QPS, data, SLA, RTO, RPO)
5. Integration surface (external systems)
6. Deployment preference (cloud / PaaS / on-prem / multi-cloud / undecided)

Any blank, "unknown", or conflicting answer is logged to `arch-output/05-technical-debts.md`
as a **Technical Debt (TDEBT-NN)**.

## How to invoke

```bash
bash <SKILL_DIR>/architecture-intake/scripts/intake.sh
```

```powershell
pwsh <SKILL_DIR>/architecture-intake/scripts/intake.ps1
```

## Output

`arch-output/01-architecture-intake.md` — a markdown summary of the architecture drivers, plus
any TDEBTs appended to `arch-output/05-technical-debts.md`.
