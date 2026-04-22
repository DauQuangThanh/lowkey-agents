---
name: csr-dependency-audit
description: Phase 4 of the Code Security Reviewer workflow — the primary assessment for OWASP A03:2025 Software Supply Chain Failures. Covers package manager inventory, SCA/dependency scanning tools, vulnerable (direct and transitive) dependency identification, SBOM generation, license compliance, supply chain security practices (signed packages, lock files, integrity checks, provenance/SLSA, staged rollouts), build-pipeline and developer-tooling hardening, and patch management cadence. Generates dependency / supply chain audit report.
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

Assessment areas (aligned with OWASP A03:2025 Software Supply Chain Failures):

1. Package managers in use (npm, pip, maven, gradle, rubygems, nuget, go, cargo, composer)
2. SCA / dependency scanning tool (Snyk, Dependabot, Trivy, OWASP Dependency-Check, OWASP Dependency-Track, none)
3. Known vulnerable dependencies (direct **and** transitive)
4. SBOM — generation (SPDX, CycloneDX), coverage, update cadence
5. License compliance monitoring
6. Supply chain security measures — signed packages, lock files, hash/integrity checks, provenance (SLSA, in-toto), trusted registries, staged rollouts / canary deployments
7. Build-pipeline & developer-tooling hardening — MFA on code repos, protected branches, environment-scoped secrets, signed builds, IaC under version control, IDE/CI/CD patching
8. Dependency update & patch cadence

## How to invoke

```bash
bash <SKILL_DIR>/csr-dependency-audit/scripts/dependency-audit.sh
```

```powershell
pwsh <SKILL_DIR>/csr-dependency-audit/scripts/dependency-audit.ps1
```

## Output

`csr-output/04-dependency-audit.md` — dependency & supply chain audit with package manager inventory, SCA tool status, vulnerable-dependency list (direct and transitive), SBOM coverage, license compliance status, signing/provenance/build-pipeline integrity evaluation, and patch management recommendations. Primary evidence for A03:2025 Software Supply Chain Failures findings.
