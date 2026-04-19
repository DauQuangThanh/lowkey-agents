---
name: dev-design
description: Phase 1 of the Developer workflow — translates the architecture diagrams and ADRs into detailed module/class structures, API contracts, and database schemas. Asks 7–8 structured questions about module breakdown, class design, API endpoints, database schema, async flows, cross-cutting concerns, sequence diagrams, and dependency graphs. Writes output to `dev-output/01-detailed-design.md`. Confirms each answer with the user before locking it in.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# Detailed Design

## When to use

First phase of the Developer workflow. Run it whenever:

- Architecture is locked (C4 diagrams, ADRs, containers defined)
- You need to translate containers into modules/classes/APIs
- You need to design the database schema or async flows
- You want to sketch sequence diagrams for critical business flows

Use it to back-fill design details for already-decided containers, or to design a single module in isolation.

## What it captures per module

| Field | Purpose |
|---|---|
| Module name | What is it? (e.g. "Orders", "Auth") |
| Purpose | One-sentence description |
| Responsibility | Key domain logic and operations |
| Key classes/types | Classes, interfaces, enums in this module |
| Dependencies | Which other modules it depends on |
| API endpoints | HTTP/gRPC/message topics (request/response schema) |
| Database schema | Logical data model (entities, relationships) |
| Async flows | Queues, topics, event handlers |
| Sequence diagrams | Call flow for critical operations |

## How to invoke

```bash
bash <SKILL_DIR>/dev-design/scripts/design.sh
```

```powershell
pwsh <SKILL_DIR>/dev-design/scripts/design.ps1
```

The script guides the user through 7–8 questions interactively, asking for confirmation of each answer before recording it.

## Output

- Main file: `dev-output/01-detailed-design.md` (all design decisions)
- Design is recorded in a markdown table for easy updating
- Any design detail left as "TBD" is logged as a DDEBT to `dev-output/05-design-debts.md`
- User is shown a summary of DDEBTs at the end
