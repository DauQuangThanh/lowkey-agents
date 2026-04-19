#!/bin/bash
# =============================================================================
# complexity.sh — Phase 2: Complexity & Maintainability Analysis
#
# Measures cyclomatic complexity (CC), function length, file size, dependency
# coupling, and circular dependencies.
#
# Usage:
#   bash <SKILL_DIR>/cqr-complexity/scripts/complexity.sh [--auto] [--answers FILE]
#
# Outputs:
#   - $CQR_OUTPUT_DIR/02-complexity-report.md
#   - $CQR_OUTPUT_DIR/02-complexity-report.extract
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

cqr_parse_flags "$@"

OUTPUT_FILE="$CQR_OUTPUT_DIR/02-complexity-report.md"
EXTRACT_FILE="$CQR_OUTPUT_DIR/02-complexity-report.extract"

# ── Defaults ──────────────────────────────────────────────────────────────────
DEF_MODULES="entire codebase"
DEF_CC="10 (standard)"
DEF_FUNC_LEN="30 lines"
DEF_FILE_LEN="300 lines"
DEF_COUPLING="None suspected"
DEF_DEBT_AREAS="None known"

cqr_banner "Phase 2: Complexity & Maintainability Analysis"

if cqr_is_auto; then
  printf '\n%b[Auto mode]%b Reading from upstream + answers file; no prompts.\n\n' "$CQR_BOLD" "$CQR_NC"
else
  cat <<'EOF'

Six numbered-choice questions covering scope, CC threshold, function length,
file length, coupling concerns, and known debt areas.

EOF
fi

# Q1 — modules in scope
cqr_is_auto || { cqr_success_rule; printf '%b[Q1 of 6] Scope of analysis%b\n' "$CQR_BOLD" "$CQR_NC"; }
MODULES=$(cqr_get MODULES "Files/modules to analyze (free text, e.g. 'src/core/**', 'auth.ts')" "$DEF_MODULES")

# Q2 — CC threshold
cqr_is_auto || { cqr_success_rule; printf '%b[Q2 of 6] Cyclomatic complexity threshold%b\n' "$CQR_BOLD" "$CQR_NC"; }
CC_THRESHOLD=$(cqr_get_choice CC_THRESHOLD "Max CC per function:" \
  "≤5 (strict)" \
  "≤10 (standard)" \
  "≤15 (lenient)" \
  "≤20 (legacy tolerance)" \
  "Other — specify" \
  "Not sure — use default ($DEF_CC) and log debt")
case "$CC_THRESHOLD" in
  "Other — specify") CC_THRESHOLD=$(cqr_get CC_THRESHOLD_SPECIFY "Specify CC max:" "$DEF_CC") ;;
  "Not sure"*)
    cqr_add_debt_auto "Complexity" "CC threshold not confirmed" \
      "User did not confirm CC threshold" "Defaulting to $DEF_CC"
    CC_THRESHOLD="$DEF_CC" ;;
esac

# Q3 — function length
cqr_is_auto || { cqr_success_rule; printf '%b[Q3 of 6] Max function length%b\n' "$CQR_BOLD" "$CQR_NC"; }
FUNC_LEN=$(cqr_get_choice FUNC_LEN "Max function length:" \
  "20 lines (Python-style)" \
  "30 lines (balanced)" \
  "50 lines (typical JS/Go/Java)" \
  "100 lines (lenient)" \
  "Other — specify" \
  "Not sure — use default ($DEF_FUNC_LEN) and log debt")
case "$FUNC_LEN" in
  "Other — specify") FUNC_LEN=$(cqr_get FUNC_LEN_SPECIFY "Specify max function LOC:" "$DEF_FUNC_LEN") ;;
  "Not sure"*)
    cqr_add_debt_auto "Complexity" "Function-length limit not confirmed" \
      "User did not confirm max function length" "Defaulting to $DEF_FUNC_LEN"
    FUNC_LEN="$DEF_FUNC_LEN" ;;
esac

# Q4 — file length
cqr_is_auto || { cqr_success_rule; printf '%b[Q4 of 6] Max file length%b\n' "$CQR_BOLD" "$CQR_NC"; }
FILE_LEN=$(cqr_get_choice FILE_LEN "Max file length:" \
  "200 lines (strict SRP)" \
  "300 lines (balanced)" \
  "500 lines (moderate)" \
  "1000 lines (lenient, OK for Go/Java)" \
  "Other — specify" \
  "Not sure — use default ($DEF_FILE_LEN) and log debt")
case "$FILE_LEN" in
  "Other — specify") FILE_LEN=$(cqr_get FILE_LEN_SPECIFY "Specify max file LOC:" "$DEF_FILE_LEN") ;;
  "Not sure"*)
    cqr_add_debt_auto "Complexity" "File-length limit not confirmed" \
      "User did not confirm max file length" "Defaulting to $DEF_FILE_LEN"
    FILE_LEN="$DEF_FILE_LEN" ;;
esac

# Q5 — coupling concerns (free text — domain-specific)
cqr_is_auto || { cqr_success_rule; printf '%b[Q5 of 6] Coupling / circular dependencies%b\n' "$CQR_BOLD" "$CQR_NC"; }
COUPLING=$(cqr_get COUPLING "Suspected high coupling or cycles (press Enter for 'None suspected')" "$DEF_COUPLING")
[ -z "$COUPLING" ] && COUPLING="$DEF_COUPLING"

# Q6 — known debt areas (free text — domain-specific)
cqr_is_auto || { cqr_success_rule; printf '%b[Q6 of 6] Known technical debt areas%b\n' "$CQR_BOLD" "$CQR_NC"; }
DEBT_AREAS=$(cqr_get DEBT_AREAS "Intentionally complex or un-refactored modules (press Enter for 'None')" "$DEF_DEBT_AREAS")
[ -z "$DEBT_AREAS" ] && DEBT_AREAS="$DEF_DEBT_AREAS"

# ── Write output ──────────────────────────────────────────────────────────────
printf '\n%b✓ Writing complexity report to %s...%b\n' "$CQR_GREEN" "$OUTPUT_FILE" "$CQR_NC"

cat > "$OUTPUT_FILE" <<EOF
# Phase 2: Complexity & Maintainability Analysis

**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')
**Status:** Complete
**Mode:** $(cqr_is_auto && echo Auto || echo Interactive)
**Thresholds:** CC $CC_THRESHOLD / function, $FILE_LEN / file

## Analysis Parameters

| Parameter | Value |
|---|---|
| **Scope** | $MODULES |
| **CC threshold** | $CC_THRESHOLD |
| **Function length limit** | $FUNC_LEN |
| **File size limit** | $FILE_LEN |
| **Coupling concerns** | $COUPLING |
| **Known debt areas** | $DEBT_AREAS |

## Next Phase

Phase 3 (Design Pattern & Architecture Review) validates SOLID, DRY, error
handling, and logging practices.

Run: \`bash <SKILL_DIR>/cqr-patterns/scripts/patterns.sh\`

---
EOF

cqr_write_extract "$EXTRACT_FILE" \
  "MODULES=$MODULES" \
  "CC_THRESHOLD=$CC_THRESHOLD" \
  "FUNC_LEN=$FUNC_LEN" \
  "FILE_LEN=$FILE_LEN" \
  "COUPLING=$COUPLING" \
  "DEBT_AREAS=$DEBT_AREAS"

cqr_success_rule
printf '%b✅ Phase 2 Complete.%b\n' "$CQR_GREEN" "$CQR_NC"
printf '  Markdown: %s\n' "$OUTPUT_FILE"
printf '  Extract:  %s\n' "$EXTRACT_FILE"
printf '\nNext: Phase 3 — bash <SKILL_DIR>/cqr-patterns/scripts/patterns.sh\n\n'
