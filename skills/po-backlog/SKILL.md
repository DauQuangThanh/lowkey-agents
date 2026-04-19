---
name: po-backlog
description: Phase 1 of the Product Owner workflow — builds and prioritizes the product backlog. Captures product vision statement, backlog items (title, description, type, priority, business value, estimation), dependencies, and MVP definition. Use when starting a new product, refining an existing backlog, or defining what's in MVP. Reads user stories from ba-output/ if available. All answers logged to po-output/01-product-backlog.md.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "1"
---

# Product Backlog Management

## When to use

This is the first phase of the Product Owner workflow. Run it when:

- A new software product is being scoped and needs a backlog.
- The user says "I want to build a backlog" / "let's define what we're building".
- The existing backlog file (`po-output/01-product-backlog.md`) is missing or stale.

## What it captures

Eight structured questions:

1. Product vision statement (one or two sentences)
2. Backlog items (loop: title, description, type, priority, business value, estimation)
3. Dependencies between items (if any)
4. MVP definition (which items are in the MVP)
5. Total estimated effort
6. Release priorities
7. Backlog refinement frequency
8. Acceptance criteria for MVP

Any blank or unclear answer is logged to `po-output/06-po-debts.md` with an explanation of its impact.

## How to invoke

```bash
bash <SKILL_DIR>/po-backlog/scripts/backlog.sh
```

```powershell
pwsh <SKILL_DIR>/po-backlog/scripts/backlog.ps1
```

## Output

`po-output/01-product-backlog.md` — a structured backlog with priority matrix, plus any debts appended to `po-output/06-po-debts.md`.
