---
name: re-documentation-gen
description: Phase 6 - Documentation Generation & Compilation. Compiles all findings into comprehensive project documentation with executive summary, tech stack, diagrams, and recommendations.
license: MIT
compatibility: Bash 3.2+, PowerShell 5.1+
allowed-tools:
  - Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 6
  phase-name: "Documentation Generation & Compilation"
---

# RE Documentation Generation

## Overview

Phase 6 of the reverse engineering workflow. This final skill compiles all findings into:

- Comprehensive project documentation
- Executive summary and navigation hub (RE-FINAL.md)
- Technology stack overview
- Architecture diagrams
- API reference
- Data model and ERD
- Dependency tree
- Known gaps and RE Debts (REDEBT-NN)
- Modernization recommendations

## Usage

### Bash
```bash
bash scripts/doc-gen.sh
```

### PowerShell
```powershell
.\scripts\doc-gen.ps1
```

## Output

Creates:
- `re-output/06-documentation.md` — Full compiled documentation
- `re-output/RE-FINAL.md` — Executive summary and navigation
- `re-output/07-re-debts.md` — All undocumented areas
- `re-output/RE-DIAGRAMS.md` — All diagrams extracted
- Optional format conversions (HTML, PDF)

## Interactive Questions

1. What documentation format is preferred? (Markdown / AsciiDoc / HTML / PDF)
2. Who is the audience? (New developers / Management / Auditors)
3. What additional sections are needed?
4. Ready to generate final documentation?

## Prerequisites

- Phase 1-5 outputs
- All intermediate documentation files

## Outputs Generated

### RE-FINAL.md
Executive summary with:
- Project overview
- Quick reference links
- Key statistics
- Architecture at a glance
- Navigation to detailed sections

### 06-documentation.md
Comprehensive guide including:
- Project overview
- Technology stack
- Architecture documentation
- API reference
- Data models
- Deployment information
- Recommended next steps

### 07-re-debts.md
All tracked undocumented areas:
- REDEBT-NN entries from all phases
- Categorized by type and impact
- Actionable recommendations for each

## This Completes the Reverse Engineering Workflow

All 6 phases complete. The `re-output/` directory now contains a complete, automatically-generated technical documentation of your codebase.
