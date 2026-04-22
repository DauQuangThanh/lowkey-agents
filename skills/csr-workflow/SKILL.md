---
name: csr-workflow
description: Orchestrator for the complete Code Security Reviewer workflow — runs all 5 phases in sequence (vulnerability assessment, authentication review, data protection review, dependency audit, security report) in a single execution. Use when performing a comprehensive security code review of an entire application.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "0"
---

# Code Security Reviewer Workflow — Full Orchestrator

## When to use

Use this orchestrator when:

- You want to run a **complete, end-to-end security code review** without stopping between phases.
- The user says "run a full security review" / "comprehensive security assessment".
- You have time to execute all 5 phases in sequence (typically 1–2 hours).
- You want to generate the complete CSR-FINAL.md report in one run.

## What it runs

Executes all 5 phases of the Code Security Reviewer workflow in order:

1. **Phase 1: Vulnerability Assessment** — OWASP Top 10:2025 review (incl. A10 Mishandling of Exceptional Conditions, A03 Software Supply Chain Failures), threat modeling, incident history
2. **Phase 2: Authentication & Authorization Review** — auth mechanisms, MFA, RBAC, session/token handling
3. **Phase 3: Data Protection & Privacy Review** — sensitive data types, encryption at rest/in transit, compliance (GDPR/HIPAA/PCI-DSS/SOC2)
4. **Phase 4: Dependency & Supply Chain Audit** — package managers, scanning tools, vulnerable dependencies, license compliance
5. **Phase 5: Security Report & Remediation Plan** — aggregates findings, categorizes by severity, generates priority matrix, compliance checklist, action items

## How to invoke

To run the **complete workflow**:

```bash
bash <SKILL_DIR>/csr-workflow/scripts/run-all.sh
```

```powershell
pwsh <SKILL_DIR>/csr-workflow/scripts/run-all.ps1
```

## Output

After successful completion, you'll have:

- `csr-output/01-vulnerability-assessment.md` — Phase 1 results
- `csr-output/02-auth-review.md` — Phase 2 results
- `csr-output/03-data-protection.md` — Phase 3 results
- `csr-output/04-dependency-audit.md` — Phase 4 results
- `csr-output/05-security-report.md` — Phase 5 main report
- `csr-output/CSR-FINAL.md` — **comprehensive final report** (all phases combined)
- `csr-output/06-cs-debts.md` — security debt register (CSDEBT-NN items)

## Individual Phase Execution

If you prefer to run individual phases separately, use:

- `bash <SKILL_DIR>/csr-vulnerability/scripts/vulnerability.sh`
- `bash <SKILL_DIR>/csr-auth-review/scripts/auth-review.sh`
- `bash <SKILL_DIR>/csr-data-protection/scripts/data-protection.sh`
- `bash <SKILL_DIR>/csr-dependency-audit/scripts/dependency-audit.sh`
- `bash <SKILL_DIR>/csr-report/scripts/report.sh`

## Timeline

Typical execution time per phase:
- Phase 1: 15–20 minutes
- Phase 2: 10–15 minutes
- Phase 3: 15–20 minutes
- Phase 4: 10–15 minutes
- Phase 5: 5–10 minutes (report generation)

**Total: 60–90 minutes** for complete assessment.

## Next Steps After Completion

1. **Review CSR-FINAL.md** — comprehensive report with all findings
2. **Prioritize by Severity** — focus on Critical & High items first
3. **Create Remediation Tickets** — backlog items for engineering team
4. **Assign Owners** — pair security findings with responsible engineers
5. **Track & Monitor** — weekly status updates on remediation progress
6. **Verification** — re-assess post-remediation to confirm fixes
7. **Continuous Monitoring** — schedule quarterly security assessments
