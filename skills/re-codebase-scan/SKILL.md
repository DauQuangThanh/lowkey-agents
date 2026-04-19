---
name: re-codebase-scan
description: Phase 1 - Codebase Discovery & Inventory. Scans directory structure, file types, configuration files, and framework detection to build a comprehensive inventory of the codebase.
license: MIT
compatibility: Bash 3.2+, PowerShell 5.1+
allowed-tools:
  - Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 1
  phase-name: "Codebase Discovery & Inventory"
---

# RE Codebase Scan

## Overview

Phase 1 of the reverse engineering workflow. This skill analyzes a codebase to produce a comprehensive inventory including:

- File statistics and language distribution
- Directory structure mapping
- Configuration file detection
- Framework and library identification
- Known entry points
- Existing documentation catalog

## Usage

### Bash
```bash
bash scripts/codebase-scan.sh
```

### PowerShell
```powershell
.\scripts\codebase-scan.ps1
```

## Output

Creates `re-output/01-codebase-inventory.md` containing:
- File counts by programming language
- Total lines of code estimate
- Directory tree structure
- Detected configuration files (package.json, pom.xml, requirements.txt, etc.)
- Identified frameworks and libraries
- Entry point candidates
- Summary statistics

## Interactive Questions

1. What is the root path of the source code?
2. What are the primary programming languages used?
3. What is the project type? (web app / API / mobile / desktop / library / microservices)
4. What build system is used? (Maven / Gradle / npm / pip / cargo / dotnet / make)
5. Describe the repository structure (monorepo / multi-repo / nested / standard)
6. What are the known entry points?
7. Does existing documentation exist? (Yes → where? / No)
8. Are there areas to focus on or skip?

## Environment Variables

- `RE_OUTPUT_DIR` — Output directory for artifacts (default: `./re-output`)
- `RE_DEBT_FILE` — Debt tracking file (default: `./re-output/07-re-debts.md`)

## Prerequisites

- Read access to source code directory
- Unix tools: `find`, `wc`, `ls`, `grep`
- Or PowerShell 5.1+ with file system access

## Next Phase

After completion, proceed to Phase 2: Architecture Extraction with `re-architecture-extraction` skill.
