---
name: nfr-checklist
description: Phase 5 of the Business Analyst workflow — captures Non-Functional Requirements (quality attributes and constraints). Walks the user through 9 NFR areas: Performance, Security, Scalability, Availability/Uptime, Usability/Accessibility, Data Retention, Regulatory Compliance (GDPR/HIPAA/PCI-DSS/ISO 27001), Backup & Recovery (RTO/RPO), and Other. Each area is y/n with numbered follow-ups. Areas the user skips or flags as unknown become Requirement Debts for expert review.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "5"
---

# Non-Functional Requirements (NFR) Checklist

## When to use

Phase 5 of the Business Analyst workflow. Run after functional requirements and user stories are captured. Also useful standalone if the user wants to refresh quality/constraint targets.

## What it captures

For each of 9 areas, asks "Is [area] a concern?" (y/n). On yes, drills in with numbered choices:

1. Performance — concurrent users, page-load targets
2. Security — sensitivity of data, encryption, audit logging (flags a debt for security review)
3. Scalability — expected growth over 1–3 years (2× / 5× / 10× / 100×+)
4. Availability — 99% through 99.99% and zero-downtime requirements
5. Usability & Accessibility — WCAG 2.1 AA, user technical level
6. Data Retention — 1/3/5/7 years or indefinite, legal-driven debt if unconfirmed
7. Regulatory Compliance — GDPR, HIPAA, PCI-DSS, ISO 27001, others (flags a debt for legal review)
8. Backup & Disaster Recovery — RTO (recovery time) and RPO (data-loss tolerance)
9. Other — user-specified

## How to invoke

```bash
bash <SKILL_DIR>/nfr-checklist/scripts/nfr-checklist.sh
```

```powershell
pwsh <SKILL_DIR>/nfr-checklist/scripts/nfr-checklist.ps1
```

## Output

`ba-output/05-nfr.md` — NFR table with areas, requirements, and priorities, plus any debts appended to `ba-output/06-requirement-debts.md`.
