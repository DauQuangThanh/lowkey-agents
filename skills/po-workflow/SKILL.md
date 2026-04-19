---
name: po-workflow
description: Orchestrator skill — runs all 5 Product Owner phases in sequence and compiles the final PO document. Use to execute the complete Product Owner workflow from start to finish. Invokes po-backlog, po-acceptance, po-roadmap, po-stakeholder-comms, and po-sprint-review phases, then compiles po-output/PO-FINAL.md.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "0"
---

# Product Owner Full Workflow

## When to use

Use this orchestrator skill when:

- Starting a new product and need to run the complete PO workflow from scratch.
- The user says "let's do the complete product owner process" / "run the full workflow".
- You want to run all 5 phases sequentially with a unified interface.

## What it does

Runs all phases in order:

1. **Phase 1:** Product Backlog Management
2. **Phase 2:** Acceptance Criteria & Definition of Done
3. **Phase 3:** Product Roadmap
4. **Phase 4:** Stakeholder Communication Plan
5. **Phase 5:** Sprint Review Preparation

Then compiles all outputs into a single `po-output/PO-FINAL.md` document.

## Features

- Skip any phase and resume later with `--skip-to N`
- Archive existing output when starting fresh
- Automatic debt tracking across all phases
- Progress indicator and step guidance
- Interactive confirmation before each phase

## How to invoke

```bash
bash <SKILL_DIR>/po-workflow/scripts/run-all.sh
```

```bash
bash <SKILL_DIR>/po-workflow/scripts/run-all.sh --skip-to 3
```

```powershell
pwsh <SKILL_DIR>/po-workflow/scripts/run-all.ps1
```

```powershell
pwsh <SKILL_DIR>/po-workflow/scripts/run-all.ps1 -SkipTo 3
```

## Output

- `po-output/01-product-backlog.md`
- `po-output/02-acceptance-criteria.md`
- `po-output/03-product-roadmap.md`
- `po-output/04-stakeholder-comms.md`
- `po-output/05-sprint-review.md`
- `po-output/06-po-debts.md` (debt tracker)
- `po-output/PO-FINAL.md` (compiled final document)
