---
name: technology-research
description: Phase 2 of the Architect workflow — for each architecturally significant decision area, identifies 2–4 credible technology candidates, captures maturity / licence / hosting model / typical cost signal / pros / cons / fit-to-constraints, and writes a comparison table. Walks the user through 12 decision areas (Frontend, Backend runtime, API style, Databases, Messaging, Caching, Identity, Hosting/compute, Observability, CI/CD, Security tooling, AI/ML). The agent should pair this with `WebSearch` / `WebFetch` to verify any fact it is unsure about — versions, prices, licences, quotas — and log unverifiable items as Technical Debts.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. Agent-side `WebSearch` / `WebFetch` recommended for fact-checking.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Technology Research

## When to use

Second phase of the Architect workflow. Run it after `architecture-intake` is complete, when:

- You need to evaluate technology candidates across multiple architectural concerns.
- The user has asked "what should we use for X?" and the decision deserves written comparison.
- Existing `arch-output/02-technology-research.md` is missing or stale.

## What it captures

For each decision area the user says "yes" to, the skill captures 2–4 candidate technologies
with this comparison structure:

| Candidate | Maturity | Licence | Hosting | Typical cost | Pros | Cons | Fit |
| --- | --- | --- | --- | --- | --- | --- | --- |

Decision areas walked through (y/n each):

1. Frontend framework & rendering
2. Backend runtime & language
3. API style (REST / GraphQL / gRPC / events)
4. Database(s)
5. Messaging / eventing
6. Caching
7. Identity & access
8. Hosting & compute
9. Observability
10. CI/CD
11. Security tooling
12. AI/ML services

## Rules

- **Never cite a version, price, SLA, or quota you have not verified this session.** If unsure,
  the script writes `TBD — verify` into the table cell and logs a TDEBT.
- The script captures the user's inputs verbatim. The *agent's* job during interactive use is to
  propose candidates and fact-check them with `WebSearch`/`WebFetch`; the *script's* job is to
  structure and persist the comparison.

## How to invoke

```bash
bash <SKILL_DIR>/technology-research/scripts/research.sh
```

```powershell
pwsh <SKILL_DIR>/technology-research/scripts/research.ps1
```

## Output

`arch-output/02-technology-research.md` — comparison tables per decision area, plus any TDEBTs
appended to `arch-output/05-technical-debts.md`.
