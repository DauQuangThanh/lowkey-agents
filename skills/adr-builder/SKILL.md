---
name: adr-builder
description: Phase 3 of the Architect workflow — captures each architecturally significant decision as an immutable **Architecture Decision Record (ADR)** following the Michael Nygard template (Status / Context / Decision / Alternatives / Consequences / References). Numbers ADRs sequentially (ADR-0001, ADR-0002, ...) and writes one markdown file per decision under `arch-output/adr/`. The skill loops so the user can add multiple ADRs in one session, and re-generates an index (`03-adr-index.md`) listing every ADR with its status. ADRs are append-only: to change a decision, a new ADR supersedes the old one.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# ADR Builder

## When to use

Third phase of the Architect workflow. Run it whenever a decision is:

- **Hard to reverse** (database engine, auth model, deployment topology)
- Affects **more than one team or module**
- Shapes a **quality attribute** (performance, security, cost, scalability)

Also use it to:

- Supersede an earlier decision — creates a new ADR linked to the previous one
- Back-fill missing ADRs for already-made decisions
- Back-fill ADRs that the `c4-architecture` validator flagged as missing

## What it captures per ADR

| Field | Purpose |
| --- | --- |
| Title | Short noun phrase describing the decision |
| Status | Proposed / Accepted / Deprecated / Superseded |
| Date | YYYY-MM-DD |
| Deciders | Who made the call |
| Context | Forces at play (requirements, constraints, NFRs) |
| Decision | What we decided — one clear paragraph |
| Alternatives | 2–3 rejected options, each with "rejected because..." |
| Consequences | Positive, negative / trade-off, follow-up actions |
| References | Requirement IDs, benchmarks, vendor docs, prior ADRs |

## How to invoke

```bash
bash <SKILL_DIR>/adr-builder/scripts/new-adr.sh
```

```powershell
pwsh <SKILL_DIR>/adr-builder/scripts/new-adr.ps1
```

The script loops: after each ADR is saved, it asks "Add another ADR? (y/n)".

## Output

- One file per ADR: `arch-output/adr/ADR-NNNN-<slug>.md`
- Regenerated index: `arch-output/03-adr-index.md` (table of all ADRs with status)
- If the user marked the ADR as *Proposed* with no target decision date, a TDEBT is logged to
  `arch-output/05-technical-debts.md`.
