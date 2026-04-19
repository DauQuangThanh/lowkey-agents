---
name: re-data-model
description: Phase 4 - Data Model Extraction. Reverse-engineers database schemas, ORM definitions, entity relationships, validation rules, and generates ERD diagrams.
license: MIT
compatibility: Bash 3.2+, PowerShell 5.1+
allowed-tools:
  - Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 4
  phase-name: "Data Model Extraction"
---

# RE Data Model

## Overview

Phase 4 of the reverse engineering workflow. This skill reconstructs:

- Database type(s) detected (SQL, NoSQL, GraphQL, etc.)
- ORM framework identification (JPA, SQLAlchemy, Prisma, Sequelize, etc.)
- Entity/model class definitions and fields
- Relationship patterns (one-to-many, many-to-many, etc.)
- Data validation rules and constraints
- Database migration history
- Entity-Relationship Diagram (ERD) in Mermaid format

## Usage

### Bash
```bash
bash scripts/data-model.sh
```

### PowerShell
```powershell
.\scripts\data-model.ps1
```

## Output

Creates `re-output/04-data-model.md` containing:
- Detected database type and configuration
- List of entities/tables with descriptions
- Field definitions (name, type, constraints)
- Relationships between entities
- Validation rules
- Migration history summary
- Mermaid ERD diagram

## Interactive Questions

1. What database type(s) are used?
2. Where are ORM/migration files located?
3. Where are entity/model class definitions?
4. What relationship patterns exist?
5. What data validation rules are enforced?
6. Is there a migration history?

## Prerequisites

- Phase 1-3 outputs
- Read access to source code
- Understanding of data modeling

## Next Phase

After completion, proceed to Phase 5: Dependency Analysis with `re-dependency-analysis` skill.
