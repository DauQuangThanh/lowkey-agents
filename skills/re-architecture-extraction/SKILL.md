---
name: re-architecture-extraction
description: Phase 2 - Architecture Reverse Engineering. Analyzes code structure to extract architectural patterns, layers, external integrations, communication patterns, and generates C4 diagrams.
license: MIT
compatibility: Bash 3.2+, PowerShell 5.1+
allowed-tools:
  - Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 2
  phase-name: "Architecture Reverse Engineering"
---

# RE Architecture Extraction

## Overview

Phase 2 of the reverse engineering workflow. This skill analyzes code structure to produce:

- Confirmed technology stack with evidence
- Identified layers and tiers (presentation, business logic, data access, infrastructure)
- External integrations and service dependencies
- Communication patterns (REST, gRPC, messaging, websockets, etc.)
- Deployment artifacts analysis (Docker, Kubernetes, Terraform)
- C4 Context and Container diagrams in Mermaid format

## Usage

### Bash
```bash
bash scripts/architecture.sh
```

### PowerShell
```powershell
.\scripts\architecture.ps1
```

## Output

Creates `re-output/02-architecture.md` containing:
- Technology stack confirmation
- Layer identification and description
- Service integrations
- Communication patterns
- Deployment topology
- Mermaid C4 diagrams

## Interactive Questions

1. Confirm detected tech stack accuracy
2. Identify observed layers/tiers in code structure
3. What external integrations exist?
4. What communication patterns are used?
5. What deployment artifacts were found?
6. Any additional architectural insights?

## Prerequisites

- Phase 1 output (`01-codebase-inventory.md`)
- Read access to source code
- Knowledge of codebase structure

## Next Phase

After completion, proceed to Phase 3: API Documentation with `re-api-documentation` skill.
