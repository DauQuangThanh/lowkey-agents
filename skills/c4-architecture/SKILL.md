---
name: c4-architecture
description: Phase 4 of the Architect workflow — produces the architecture document using the **C4 model** (Context → Container → Component → Code), the de-facto industry standard for communicating software architecture. Captures Level 1 (System Context — system, users, external systems), Level 2 (Containers — deployable/runnable units with technology choice and ADR link per container), and Level 3 (Components — one diagram per non-trivial container). Generates Mermaid-format `.mmd` files plus a consolidated `04-architecture.md` with narrative, key/legend, data-flow description, and an optional Structurizr DSL export. Level 4 (Code) is optional and usually skipped.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required. Mermaid renders natively in GitHub/GitLab/VS Code; no install needed.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# C4 Architecture

## When to use

Fourth phase of the Architect workflow. Run it when:

- ADRs are in place (or at least the key technology choices are decided) and you need a visual
  architecture document to share with engineers, ops, security, and stakeholders.
- Existing `arch-output/04-architecture.md` is missing or out of date.

## What it produces

For each level, the script captures structured data and writes:

### Level 1 — System Context *(mandatory)*
- System name and one-line description
- People / user personas that interact with the system
- External systems the system depends on
→ Writes `arch-output/diagrams/context.mmd`

### Level 2 — Containers *(mandatory)*
- For each container (app, service, DB, worker, broker): name, responsibility, technology, ADR ref
→ Writes `arch-output/diagrams/containers.mmd`

### Level 3 — Components *(mandatory for each container with non-trivial internals)*
- Per container: components (controllers, services, repositories, adapters) + responsibilities
→ Writes `arch-output/diagrams/components-<container-slug>.mmd` per container

### Deployment view *(optional but recommended)*
- How containers map to infrastructure (regions, VPCs, clusters)
→ Writes `arch-output/diagrams/deployment.mmd`

### Structurizr DSL export *(optional)*
→ Writes `arch-output/diagrams/workspace.dsl`

## How to invoke

```bash
bash <SKILL_DIR>/c4-architecture/scripts/build-c4.sh
```

```powershell
pwsh <SKILL_DIR>/c4-architecture/scripts/build-c4.ps1
```

## Output

- `arch-output/04-architecture.md` — consolidated document with narrative + Mermaid diagrams +
  container table with ADR references
- `arch-output/diagrams/*.mmd` — one file per diagram
- `arch-output/diagrams/workspace.dsl` — optional Structurizr DSL
- Any container without an ADR reference is logged as a TDEBT in
  `arch-output/05-technical-debts.md`.
