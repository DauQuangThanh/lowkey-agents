---
name: ta-environment
description: Phase 5 of the Test Architect workflow — plans test environments and infrastructure. Specifies environment tiers (dev/QA/staging/production), data requirements and refresh frequencies per environment, infrastructure needs (compute, databases, third-party mocks), test data masking/anonymization, and access control policies. Writes output to `ta-output/05-environment-plan.md`.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "5"
---

# Test Environment Planning

## When to use

Fifth phase of the Test Architect workflow. Run it after quality gates are defined (Phase 4). Plans the infrastructure and data needed to execute the test strategy reliably.

## What it captures

| Field | Purpose |
| --- | --- |
| Environments Needed | Which tiers (dev/QA/staging/production) and their purposes |
| Data Requirements per Environment | Volume, freshness, masking, seeding strategy |
| Infrastructure Needs | VMs, databases, third-party service mocks, Selenium Grid, device farms |
| Test Data Masking/Anonymization | How to handle PII, compliance (GDPR, HIPAA, PCI-DSS) |
| Environment Refresh Frequency | How often to reset (on-demand, nightly, weekly, per-sprint) |
| Access Control | Credentials storage, API tokens, database access, network whitelist |

## How to invoke

```bash
bash <SKILL_DIR>/ta-environment/scripts/environment.sh
```

```powershell
pwsh <SKILL_DIR>/ta-environment/scripts/environment.ps1
```

The script asks 6 interactive questions and generates the output file.

## Output

- Main document: `ta-output/05-environment-plan.md` (environment infrastructure and data plan)
