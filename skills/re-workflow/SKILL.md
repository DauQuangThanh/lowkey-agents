---
name: re-workflow
description: Phase 0 - Orchestrator. Runs all 6 reverse engineering phases sequentially to generate complete project documentation from source code.
license: MIT
compatibility: Bash 3.2+, PowerShell 5.1+
allowed-tools:
  - Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 0
  phase-name: "Orchestrator"
---

# RE Workflow Orchestrator

## Overview

Phase 0 - The orchestrator that runs all 6 reverse engineering phases sequentially:

1. **Phase 1**: Codebase Discovery & Inventory
2. **Phase 2**: Architecture Reverse Engineering
3. **Phase 3**: API & Interface Documentation
4. **Phase 4**: Data Model Extraction
5. **Phase 5**: Dependency & Integration Map
6. **Phase 6**: Documentation Generation & Compilation

This skill automates the complete reverse engineering workflow for a codebase.

## Usage

### Bash
```bash
bash scripts/run-all.sh
```

### PowerShell
```powershell
.\scripts\run-all.ps1
```

## Workflow

The orchestrator:
1. Initializes the `re-output/` directory
2. Sets up environment variables
3. Runs each phase in sequence
4. Handles errors and provides recovery options
5. Compiles final documentation
6. Generates RE-FINAL.md as navigation hub
7. Reports summary with file locations

## Output Structure

```
re-output/
├── 01-codebase-inventory.md      (Phase 1)
├── 02-architecture.md             (Phase 2)
├── 03-api-documentation.md        (Phase 3)
├── 04-data-model.md               (Phase 4)
├── 05-dependency-map.md           (Phase 5)
├── 06-documentation.md            (Phase 6)
├── 07-re-debts.md                 (RE Debts from all phases)
├── RE-FINAL.md                    (Executive summary & nav)
├── RE-DIAGRAMS.md                 (All Mermaid diagrams)
└── ERRORS.log                     (Error log, if any)
```

## Prerequisites

- Source code directory path
- Read access to all source files
- Bash 3.2+ or PowerShell 5.1+

## Time Estimate

- Small project (< 10k LOC): 5-10 minutes
- Medium project (10-100k LOC): 10-20 minutes
- Large project (> 100k LOC): 20-30 minutes

## After Completion

1. Review `re-output/RE-FINAL.md` for executive summary
2. Check `re-output/07-re-debts.md` for documented gaps
3. Share `re-output/06-documentation.md` with team
4. Use diagrams in `re-output/02-architecture.md` for presentations
5. Reference API docs in `re-output/03-api-documentation.md`

## Environment Variables

- `RE_OUTPUT_DIR` — Output directory (default: `./re-output`)
- `RE_DEBT_FILE` — Debt tracking file (default: `./re-output/07-re-debts.md`)

## Error Handling

If a phase fails:
1. Error is logged to `re-output/ERRORS.log`
2. Orchestrator pauses and asks for guidance
3. User can skip failed phase or retry
4. Partial output is preserved
5. Later phases can still run if dependencies are met

## Customization

Individual phases can be run separately:
- `re-codebase-scan` for Phase 1
- `re-architecture-extraction` for Phase 2
- `re-api-documentation` for Phase 3
- `re-data-model` for Phase 4
- `re-dependency-analysis` for Phase 5
- `re-documentation-gen` for Phase 6
