---
name: csr-data-protection
description: Phase 3 of the Code Security Reviewer workflow — sensitive data type assessment, encryption at rest evaluation, encryption in transit validation, data masking practices, retention policy review, and compliance framework alignment (GDPR, HIPAA, PCI-DSS, SOC2). Generates data protection & privacy assessment.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "3"
---

# Data Protection & Privacy Review

## When to use

This is the third phase of the Code Security Reviewer workflow. Run it when:

- You are assessing data protection practices for an application handling sensitive data.
- The user says "review my data protection" / "check encryption and privacy compliance".
- The data protection review report (`csr-output/03-data-protection.md`) needs to be created or updated.

## What it captures

6 main assessment areas:

1. Sensitive data types (PII, PHI, PCI-DSS, credentials, proprietary, none)
2. Encryption at rest (algorithm, key management)
3. Encryption in transit (TLS version, certificate pinning)
4. Data masking & tokenization practices
5. Data retention policies
6. Compliance requirements (GDPR, HIPAA, PCI-DSS, SOC2, other)

## How to invoke

```bash
bash <SKILL_DIR>/csr-data-protection/scripts/data-protection.sh
```

```powershell
pwsh <SKILL_DIR>/csr-data-protection/scripts/data-protection.ps1
```

## Output

`csr-output/03-data-protection.md` — data protection & privacy assessment with sensitive data inventory, encryption validation, masking evaluation, retention policy review, and compliance alignment checklist.
