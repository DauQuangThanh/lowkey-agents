---
name: re-dependency-analysis
description: Phase 5 - Dependency & Integration Map. Catalogs internal modules, external libraries, third-party service integrations, detects circular dependencies, and identifies outdated packages.
license: MIT
compatibility: Bash 3.2+, PowerShell 5.1+
allowed-tools:
  - Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 5
  phase-name: "Dependency & Integration Map"
---

# RE Dependency Analysis

## Overview

Phase 5 of the reverse engineering workflow. This skill catalogs:

- Package manifest files (package.json, requirements.txt, pom.xml, Cargo.toml, go.mod, etc.)
- Internal module dependencies and structure
- External library inventory with versions
- Third-party service integrations
- Circular dependency detection
- Outdated or deprecated package identification
- Security vulnerability flags

## Usage

### Bash
```bash
bash scripts/dependency-analysis.sh
```

### PowerShell
```powershell
.\scripts\dependency-analysis.ps1
```

## Output

Creates `re-output/05-dependency-map.md` containing:
- Dependency inventory table
- Direct dependencies with versions
- Development dependencies
- Internal module dependency graph
- Circular dependencies (if any)
- Outdated packages list
- Critical dependencies highlight
- Dependency tree visualization

## Interactive Questions

1. What package manifest files exist?
2. What internal module dependencies are critical?
3. What external services are integrated?
4. Generate dependency tree or graph?
5. Are there circular dependencies?
6. Are any packages outdated or deprecated?

## Prerequisites

- Phase 1-4 outputs
- Read access to source code
- Package management knowledge

## Next Phase

After completion, proceed to Phase 6: Documentation Generation with `re-documentation-gen` skill.
