---
name: architecture-validation
description: Phase 6 (final) of the Architect workflow — runs automated completeness checks and manual sign-off questions, then compiles the final `ARCHITECTURE-FINAL.md` deliverable. Automated checks verify each phase file exists (intake, research, ADR index, C4 doc, TDEBT register), that every Container in the C4 diagram traces to an ADR, every ADR has Context/Decision/Alternatives/Consequences, no ADRs are stuck in *Proposed* without a target date, and no High-likelihood / High-impact risk is un-mitigated. Produces a validation report with APPROVED / CONDITIONALLY APPROVED / NOT READY status, and compiles every phase file into a single deliverable.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "6"
---

# Architecture Validation & Sign-Off

## When to use

Final phase of the Architect workflow. Run it when:

- All prior phases (intake, research, ADRs, C4, risks) are done and you want to confirm the
  architecture is implementation-ready.
- You need a single compiled deliverable to share with engineering leadership for sign-off.

## Automated checks

| Check | Pass criterion |
| --- | --- |
| Intake exists | `01-architecture-intake.md` present and non-empty |
| Research exists | `02-technology-research.md` present and non-empty |
| ADR index exists | `03-adr-index.md` present and lists ≥ 1 ADR |
| ADR content | Every ADR has Context / Decision / Alternatives / Consequences sections |
| No stale Proposed ADRs | No ADR is *Proposed* with target date in the past |
| C4 document exists | `04-architecture.md` present |
| Context & Container diagrams exist | Mandatory Mermaid files present |
| Containers reference ADRs | Every container row in the container table has an ADR link |
| No blocking TDEBTs | No 🔴 Blocking Technical Debt is *Open* |
| No un-mitigated high-risk | No High/High risk has empty Mitigation |

## Manual sign-off questions

- Does the architecture trace cleanly to the problem statement?
- Are all stakeholders aware of decisions that affect them?
- Is the cost envelope acceptable?
- Is there a walkaway plan if a key vendor fails?
- Sign-off: engineering / security / ops / product?

## Status outcome

- ✅ **APPROVED** — all automated checks passed + all manual questions answered positively
- ⚠️ **CONDITIONALLY APPROVED** — ≤ 2 minor gaps, each converted to a TDEBT
- ❌ **NOT READY** — any blocking failure

## How to invoke

```bash
bash <SKILL_DIR>/architecture-validation/scripts/validate.sh
```

```powershell
pwsh <SKILL_DIR>/architecture-validation/scripts/validate.ps1
```

## Output

- `arch-output/06-architecture-validation.md` — validation report (checks + manual answers +
  status)
- `arch-output/ARCHITECTURE-FINAL.md` — compiled deliverable (intake → research → ADR index →
  ADRs → architecture doc → risks/debts → validation report)
