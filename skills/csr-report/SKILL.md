---
name: csr-report
description: Phase 5 of the Code Security Reviewer workflow — aggregates findings from all previous phases (1–4), categorizes findings by severity (Critical/High/Medium/Low/Info), generates remediation priority matrix, provides compliance alignment checklist (GDPR/HIPAA/PCI-DSS/SOC2), and produces comprehensive security report with action items. Generates 05-security-report.md and CSR-FINAL.md.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "5"
---

# Security Report & Remediation Plan

## When to use

This is the fifth and final phase of the Code Security Reviewer workflow. Run it when:

- All Phases 1–4 have been completed (vulnerability assessment, auth review, data protection, dependency audit).
- You are ready to generate the comprehensive security findings report and remediation roadmap.
- The user says "generate security report" / "compile security findings".

## What it produces

Comprehensive aggregation and analysis:

1. **Severity Categorization** — Critical, High, Medium, Low, Informational
2. **Remediation Priority Matrix** — based on CVSS-like scoring
3. **Compliance Alignment** — GDPR, HIPAA, PCI-DSS, SOC2 checklists
4. **Continuous Security Recommendations** — short-term (1–3 months), medium-term (3–6 months), long-term (6–12 months)
5. **Testing & Validation Plan** — unit, integration, system, compliance testing
6. **Final Comprehensive Report** — all phases + analysis + action items

## How to invoke

```bash
bash <SKILL_DIR>/csr-report/scripts/report.sh
```

```powershell
pwsh <SKILL_DIR>/csr-report/scripts/report.ps1
```

## Output

- `csr-output/05-security-report.md` — main security report with severity ratings, priority matrix, compliance checklist, recommendations
- `csr-output/CSR-FINAL.md` — comprehensive final report combining all phases + analysis
- `csr-output/06-cs-debts.md` — ongoing security debt register (CSDEBT-NN items)

## Next Steps After Report Generation

1. **Review & Prioritize** — stakeholders review findings and approve priority
2. **Create Remediation Tickets** — convert high/critical findings into engineering backlog items
3. **Assign Owners** — each item assigned to responsible team/engineer
4. **Track Progress** — monitor remediation status weekly
5. **Verification & Follow-up** — conduct security review post-remediation
6. **Continuous Monitoring** — establish quarterly or semi-annual security assessment cadence
