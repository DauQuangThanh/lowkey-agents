---
name: re-api-documentation
description: Phase 3 - API & Interface Documentation. Discovers API endpoints, routes, GraphQL schemas, gRPC services, authentication mechanisms, and request/response formats.
license: MIT
compatibility: Bash 3.2+, PowerShell 5.1+
allowed-tools:
  - Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: 3
  phase-name: "API & Interface Documentation"
---

# RE API Documentation

## Overview

Phase 3 of the reverse engineering workflow. This skill discovers and documents:

- REST endpoints with HTTP methods, paths, and parameters
- GraphQL schemas and queries
- gRPC services and methods
- Authentication mechanisms (JWT, OAuth, API keys, etc.)
- Request/response formats and schemas
- Error handling patterns
- API versioning strategies
- OpenAPI/Swagger specifications

## Usage

### Bash
```bash
bash scripts/api-docs.sh
```

### PowerShell
```powershell
.\scripts\api-docs.ps1
```

## Output

Creates `re-output/03-api-documentation.md` containing:
- API style classification
- Endpoint reference table (method, path, auth, purpose)
- Request/response schemas
- Authentication details
- Error response format
- API versioning info
- Example curl commands

## Interactive Questions

1. What API style is detected? (REST / GraphQL / gRPC / SOAP)
2. How should endpoints be discovered?
3. What authentication mechanism is in place?
4. What request/response formats are used?
5. What error handling patterns exist?
6. What versioning strategy is employed?

## Prerequisites

- Phase 1 & 2 outputs
- Read access to source code
- Understanding of API frameworks (Express, Spring, FastAPI, etc.)

## Next Phase

After completion, proceed to Phase 4: Data Model with `re-data-model` skill.
