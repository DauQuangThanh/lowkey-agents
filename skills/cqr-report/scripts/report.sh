#!/bin/bash
# =============================================================================
# report.sh — Phase 4: Quality Report & Recommendations
#
# Aggregates findings from phases 1–3. Entirely driven by upstream outputs —
# no user prompts. Accepts --auto for consistency with other phases.
#
# Usage:
#   bash <SKILL_DIR>/cqr-report/scripts/report.sh [--auto] [--answers FILE]
#
# Outputs:
#   - $CQR_OUTPUT_DIR/04-quality-report.md
#   - $CQR_OUTPUT_DIR/CQR-FINAL.md
#   - $CQR_OUTPUT_DIR/05-cq-debts.md (consolidated, already written by phases)
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

cqr_parse_flags "$@"

REPORT_FILE="$CQR_OUTPUT_DIR/04-quality-report.md"
FINAL_FILE="$CQR_OUTPUT_DIR/CQR-FINAL.md"

STANDARDS_MD="$CQR_OUTPUT_DIR/01-standards-review.md"
COMPLEXITY_MD="$CQR_OUTPUT_DIR/02-complexity-report.md"
PATTERNS_MD="$CQR_OUTPUT_DIR/03-patterns-review.md"
STANDARDS_EX="$CQR_OUTPUT_DIR/01-standards-review.extract"
COMPLEXITY_EX="$CQR_OUTPUT_DIR/02-complexity-report.extract"
PATTERNS_EX="$CQR_OUTPUT_DIR/03-patterns-review.extract"

cqr_banner "Phase 4: Quality Report & Recommendations"

# ── Validate upstream outputs ────────────────────────────────────────────────
MISSING=0
for f in "$STANDARDS_MD" "$COMPLEXITY_MD" "$PATTERNS_MD"; do
  if [ ! -f "$f" ]; then
    printf '%b  missing: %s%b\n' "$CQR_YELLOW" "$f" "$CQR_NC"
    MISSING=1
  fi
done
if [ "$MISSING" = 1 ]; then
  if cqr_is_auto; then
    cqr_add_debt_auto "Report" "Missing upstream phase output" \
      "One or more CQR phase outputs are missing" \
      "Final report will have TBD fields; run missing phases first"
  else
    printf '\n%bOne or more phase outputs are missing. Run phases 1–3 first.%b\n' "$CQR_YELLOW" "$CQR_NC"
    exit 1
  fi
fi
printf '%b✓ Upstream outputs located%b\n\n' "$CQR_GREEN" "$CQR_NC"

# ── Debt counts by severity (parsed from the CQR debt file) ──────────────────
count_debt_by_severity() {
  local sev="$1" n=0
  if [ -f "$CQR_DEBT_FILE" ]; then
    n=$(grep -c "\*\*Severity\*\* | ${sev}" "$CQR_DEBT_FILE" 2>/dev/null)
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
  fi
  printf '%s' "$n"
}
CRIT_DEBTS=$(count_debt_by_severity "Critical")
MAJOR_DEBTS=$(count_debt_by_severity "Major")
MINOR_DEBTS=$(count_debt_by_severity "Minor")
INFO_DEBTS=$(count_debt_by_severity "Info")
TOTAL_DEBTS=$(cqr_current_debt_count)

# ── Simple composite score (0–100) ───────────────────────────────────────────
# Heuristic: start at 100, subtract for debts weighted by severity. Capped ≥0.
SCORE=100
SCORE=$(( 100 - (CRIT_DEBTS * 20) - (MAJOR_DEBTS * 5) - (MINOR_DEBTS * 2) - INFO_DEBTS ))
[ "$SCORE" -lt 0 ] && SCORE=0

STATUS="Fair"
if   [ "$SCORE" -ge 80 ]; then STATUS="Excellent ✅"
elif [ "$SCORE" -ge 70 ]; then STATUS="Good ✓"
elif [ "$SCORE" -ge 60 ]; then STATUS="Fair (improvement needed)"
elif [ "$SCORE" -ge 50 ]; then STATUS="Poor (significant work needed)"
else                           STATUS="Critical (immediate action)"
fi

# ── Pull representative values from extracts for the summary ─────────────────
LANG_VAL=$(cqr_read_extract "$STANDARDS_EX"  LANGUAGE 2>/dev/null)
STYLE_VAL=$(cqr_read_extract "$STANDARDS_EX" STYLE 2>/dev/null)
CC_VAL=$(cqr_read_extract "$COMPLEXITY_EX"   CC_THRESHOLD 2>/dev/null)
PATTERN_VAL=$(cqr_read_extract "$PATTERNS_EX" PATTERN 2>/dev/null)
[ -z "$LANG_VAL" ]    && LANG_VAL="(unknown — Phase 1 missing)"
[ -z "$STYLE_VAL" ]   && STYLE_VAL="(unknown)"
[ -z "$CC_VAL" ]      && CC_VAL="(unknown — Phase 2 missing)"
[ -z "$PATTERN_VAL" ] && PATTERN_VAL="(unknown — Phase 3 missing)"

# ── Write detailed quality report ────────────────────────────────────────────
printf '%b✓ Generating Quality Report...%b\n' "$CQR_GREEN" "$CQR_NC"

cat > "$REPORT_FILE" <<EOF
# Phase 4: Quality Report & Recommendations

**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')
**Status:** Complete
**Mode:** $(cqr_is_auto && echo Auto || echo Interactive)

## Composite Quality Score

**${SCORE}/100 — ${STATUS}**

Score heuristic: 100 − (20 × critical debts) − (5 × major) − (2 × minor) − (1 × info).

| Dimension | Debt count | Impact on score |
|---|---|---|
| 🔴 Critical | ${CRIT_DEBTS} | −$(( CRIT_DEBTS * 20 )) |
| 🟠 Major | ${MAJOR_DEBTS} | −$(( MAJOR_DEBTS * 5 )) |
| 🟡 Minor | ${MINOR_DEBTS} | −$(( MINOR_DEBTS * 2 )) |
| ℹ️ Info | ${INFO_DEBTS} | −${INFO_DEBTS} |

### Interpretation

- **80–100:** Excellent; production-ready code
- **70–79:** Good; minor improvements recommended
- **60–69:** Fair; refactoring recommended this quarter
- **50–59:** Poor; significant work needed
- **<50:** Critical; immediate action required

## Snapshot from Upstream Phases

| Dimension | Value | Source |
|---|---|---|
| Primary language | ${LANG_VAL} | Phase 1 |
| Style guide | ${STYLE_VAL} | Phase 1 |
| CC threshold | ${CC_VAL} | Phase 2 |
| Expected pattern | ${PATTERN_VAL} | Phase 3 |

## Technical Debt Register

Total **CQDEBT entries:** ${TOTAL_DEBTS}

- Critical: ${CRIT_DEBTS} (fix immediately)
- Major: ${MAJOR_DEBTS} (fix this sprint)
- Minor: ${MINOR_DEBTS} (fix this quarter)
- Info: ${INFO_DEBTS} (consider for backlog)

Full register: \`05-cq-debts.md\`.

## Next Steps

1. Review CQR-FINAL.md (executive summary).
2. Share findings with team; agree on priorities.
3. Plan refactoring sprints (4 weeks recommended).
4. Re-run this phase in 4 weeks to measure improvement.

---
EOF

# ── Write executive summary (CQR-FINAL.md) ───────────────────────────────────
cat > "$FINAL_FILE" <<EOF
# Code Quality Review — Final Report

**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')
**Status:** Complete
**Reviewer:** Code Quality Agent
**Mode:** $(cqr_is_auto && echo Auto || echo Interactive)

---

## Headline

**Composite Quality Score: ${SCORE}/100 — ${STATUS}**

${TOTAL_DEBTS} debt entries tracked (🔴 ${CRIT_DEBTS} critical · 🟠 ${MAJOR_DEBTS} major · 🟡 ${MINOR_DEBTS} minor · ℹ️ ${INFO_DEBTS} info).

## What Was Reviewed

- **Standards compliance** (Phase 1) — coding conventions, naming, file structure, docs, linting
- **Complexity & maintainability** (Phase 2) — cyclomatic complexity, function/file length, coupling
- **Design pattern & architecture** (Phase 3) — SOLID, DRY, separation of concerns, error handling, logging

## Key Context

| Dimension | Value |
|---|---|
| Primary language | ${LANG_VAL} |
| Style guide | ${STYLE_VAL} |
| CC threshold | ${CC_VAL} |
| Expected architectural pattern | ${PATTERN_VAL} |

## Recommended Reading Order

1. **This document** — overview and headline.
2. \`04-quality-report.md\` — detailed breakdown + score math.
3. \`05-cq-debts.md\` — prioritized debt register.
4. \`01-standards-review.md\` / \`02-complexity-report.md\` / \`03-patterns-review.md\` — per-phase baselines.

## Success Criteria

| Metric | Current | Target |
|---|---|---|
| Composite score | ${SCORE} | 80+ |
| Critical debts | ${CRIT_DEBTS} | 0 |
| Major debts | ${MAJOR_DEBTS} | ≤2 |

---

**Next review recommended:** 4 weeks after improvements.
EOF

cqr_banner "Phase 4 Complete"
cat <<EOF

Files produced:
  ✓ 04-quality-report.md   — detailed findings + score math
  ✓ CQR-FINAL.md           — executive summary
  ✓ 05-cq-debts.md         — technical debt registry (${TOTAL_DEBTS} entries)

All files under: $CQR_OUTPUT_DIR

EOF

cqr_success_rule
printf '%b✅ Code Quality Review Complete — Score: %s/100 (%s)%b\n\n' \
  "$CQR_GREEN" "$SCORE" "$STATUS" "$CQR_NC"
