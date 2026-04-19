---
name: cqr-report
description: Phase 4 of the Code Quality Reviewer workflow — aggregates findings from phases 1-3, categorizes by severity (Critical/Major/Minor/Info), calculates composite quality score (0-100), generates improvement recommendations ranked by effort/impact, and compiles final report. Reads all phase outputs and produces `cqr-output/04-quality-report.md` + `cqr-output/CQR-FINAL.md`. No interactive questions; fully automated aggregation and synthesis.
license: MIT
compatibility: Requires Bash 3.2+ or PowerShell 5.1+/7+. No network access required.
allowed-tools: Bash
metadata:
  author: Dau Quang Thanh
  version: "1.0.0"
  phase: "4"
---

# Quality Report & Recommendations

## When to use

Final phase of the Code Quality Reviewer workflow. Run it after completing phases 1–3:

- After collecting standards baseline, complexity metrics, and pattern audit
- To synthesize all findings into a comprehensive report
- To generate quality score and improvement roadmap
- To prioritize technical debt by severity and effort

## What it produces

| Output | Purpose |
|---|---|
| `04-quality-report.md` | Detailed findings by category, quality scorecard, improvement roadmap |
| `CQR-FINAL.md` | Executive summary, priority actions, success criteria |
| `05-cq-debts.md` | Technical debt registry (CQDEBT-NN) with all tracked issues |

## How to invoke

```bash
bash <SKILL_DIR>/cqr-report/scripts/report.sh
```

```powershell
pwsh <SKILL_DIR>/cqr-report/scripts/report.ps1
```

The script:
1. Reads `cqr-output/01-standards-review.md` (Phase 1 output)
2. Reads `cqr-output/02-complexity-report.md` (Phase 2 output)
3. Reads `cqr-output/03-patterns-review.md` (Phase 3 output)
4. Aggregates findings by severity: Critical / Major / Minor / Info
5. Calculates composite quality score (0–100)
6. Ranks improvements by impact/effort
7. Writes final report and recommendations

## Scoring Methodology

**Quality Score = (StdCompliance × 0.25) + (ComplexityHealth × 0.25) + (PatternAdherence × 0.25) + (DebtBacklog × 0.25)**

- **Standards Compliance (25%):** Percent of coding standards being followed
- **Complexity Health (25%):** Inverse of complexity hotspots; higher score = simpler code
- **Pattern Adherence (25%):** Percent of SOLID / DRY / architecture patterns met
- **Technical Debt (25%):** Inverse of outstanding debt; fewer critical/major issues = higher score

**Score Interpretation:**
- 80–100: Excellent; production-ready
- 70–79: Good; minor improvements recommended
- 60–69: Fair; refactoring recommended
- 50–59: Poor; significant work needed
- <50: Critical; immediate action required

## Output Details

### 04-quality-report.md

Contains:
- Executive summary
- Findings aggregated by severity (Critical → Major → Minor → Info)
- Quality scorecard with dimension scores and trends
- Improvement roadmap (weeks 1–4, backlog)
- Technical debt register snapshot
- Dependencies and risks

### CQR-FINAL.md

Contains:
- High-level summary (findings in bullets)
- Quality scorecard (one-page format)
- Top 10 priority actions with effort/impact
- Technical debt entries (full list)
- Success criteria and targets
- Appendices (methodology, tools, limitations)

### 05-cq-debts.md

Running registry of CQDEBT-NN entries from all phases.
