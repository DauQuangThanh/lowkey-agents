---
name: csr-auth-review
description: Phase 2 of the Code Security Reviewer workflow — authentication mechanism review, password policy assessment, MFA implementation status, RBAC design validation, session management practices, and token handling security. Generates authentication & authorization assessment.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "2"
---

# Authentication & Authorization Review

## When to use

This is the second phase of the Code Security Reviewer workflow. Run it when:

- You are reviewing authentication and authorization mechanisms in an application.
- The user says "review my auth system" / "assess authentication security".
- The authentication review report (`csr-output/02-auth-review.md`) needs to be created or updated.

## What it captures

6 main assessment areas:

1. Authentication mechanism (session, JWT, OAuth2, SAML, API keys, multi-factor)
2. Password policy (length, complexity, expiration, history)
3. MFA implementation status (enforced, optional, admin-only, none)
4. RBAC design (role/permission model documentation)
5. Session management (timeout, logout, fixation protection)
6. Token handling (storage, expiry, rotation, signing algorithm)

## How to invoke

```bash
bash <SKILL_DIR>/csr-auth-review/scripts/auth-review.sh
```

```powershell
pwsh <SKILL_DIR>/csr-auth-review/scripts/auth-review.ps1
```

## Output

`csr-output/02-auth-review.md` — authentication & authorization assessment with mechanism details, password policy validation, MFA status, RBAC design analysis, session security checklist, and token handling evaluation.
