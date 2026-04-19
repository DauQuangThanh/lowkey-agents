---
name: csr-dependency-audit
description: Phase 4 of the Code Security Reviewer workflow — package manager inventory, dependency scanning tool assessment, vulnerable dependency identification, license compliance review, supply chain security practices (lock files, integrity checks, provenance), and patch management cadence. Generates dependency audit report.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# Dependency & Supply Chain Audit

## When to use

This is the fourth phase of the Code Security Reviewer workflow. Run it when:

- You are auditing third-party dependencies and supply chain security practices.
- The user says "audit my dependencies" / "check for vulnerable packages".
- The dependency audit report (`csr-output/04-dependency-audit.md`) needs to be created or updated.

## What it captures

6 main assessment areas:

1. Package managers in use (npm, pip, maven, gradle, rubygems, nuget, go, cargo, composer)
2. Dependency scanning tool (Snyk, Dependabot, Trivy, OWASP Dependency-Check, none)
3. Known vulnerable dependencies
4. License compliance monitoring
5. Supply chain security measures (lock files, integrity checks, provenance verification)
6. Dependency update & patch cadence

## How to invoke

```bash
bash <SKILL_DIR>/csr-dependency-audit/scripts/dependency-audit.sh
```

```powershell
pwsh <SKILL_DIR>/csr-dependency-audit/scripts/dependency-audit.ps1
```

## Output

`csr-output/04-dependency-audit.md` — dependency & supply chain audit with package manager inventory, scanning tool status, vulnerable dependency list, license compliance status, supply chain integrity evaluation, and patch management recommendations.
