#!/bin/bash
# =============================================================================
# patterns.sh — Phase 3: Design Pattern & Architecture Compliance
#
# Audits SOLID adherence, DRY, separation of concerns, error handling, and
# logging patterns.
#
# Usage:
#   bash <SKILL_DIR>/cqr-patterns/scripts/patterns.sh [--auto] [--answers FILE]
#
# Outputs:
#   - $CQR_OUTPUT_DIR/03-patterns-review.md
#   - $CQR_OUTPUT_DIR/03-patterns-review.extract
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

cqr_parse_flags "$@"

OUTPUT_FILE="$CQR_OUTPUT_DIR/03-patterns-review.md"
EXTRACT_FILE="$CQR_OUTPUT_DIR/03-patterns-review.extract"

# ── Defaults ──────────────────────────────────────────────────────────────────
DEF_PATTERN="Layered (Presentation / Domain / Data)"
DEF_SOLID="All five — balanced priority"
DEF_DRY="None identified"
DEF_SOC="Separated: services for logic, repositories for persistence, controllers for HTTP"
DEF_ERRORS="Exceptions for exceptional flows + custom exception types"
DEF_LOGGING="Structured logs + level discipline (DEBUG/INFO/WARN/ERROR)"

cqr_banner "Phase 3: Design Pattern & Architecture Compliance"

if cqr_is_auto; then
  printf '\n%b[Auto mode]%b Reading from upstream + answers file; no prompts.\n\n' "$CQR_BOLD" "$CQR_NC"
else
  cat <<'EOF'

Six numbered-choice questions covering expected patterns, SOLID priority,
DRY concerns, separation of concerns, error handling, and logging.

EOF
fi

# Q1 — expected pattern
cqr_is_auto || { cqr_success_rule; printf '%b[Q1 of 6] Expected architectural pattern%b\n' "$CQR_BOLD" "$CQR_NC"; }
PATTERN=$(cqr_get_choice PATTERN "Expected pattern:" \
  "Layered (Presentation / Domain / Data)" \
  "Hexagonal / Ports & Adapters" \
  "Domain-Driven Design (DDD)" \
  "MVC" \
  "Microservices" \
  "Monolith with modules" \
  "Event-driven" \
  "CQRS" \
  "Other — specify" \
  "Not sure — use default ($DEF_PATTERN) and log debt")
case "$PATTERN" in
  "Other — specify") PATTERN=$(cqr_get PATTERN_SPECIFY "Specify pattern:" "$DEF_PATTERN") ;;
  "Not sure"*)
    cqr_add_debt_auto "Patterns" "Expected pattern not confirmed" \
      "User could not confirm expected architectural pattern" \
      "Defaulting to $DEF_PATTERN"
    PATTERN="$DEF_PATTERN" ;;
esac

# Q2 — SOLID focus
cqr_is_auto || { cqr_success_rule; printf '%b[Q2 of 6] SOLID priority%b\n' "$CQR_BOLD" "$CQR_NC"; }
SOLID=$(cqr_get_choice SOLID "Which SOLID principles matter most:" \
  "All five — balanced priority" \
  "S + D (SRP + DI) — most common critical pair" \
  "S only — keep classes focused" \
  "O only — extension over modification" \
  "D only — dependency inversion / testability" \
  "Other — specify" \
  "Not sure — use default ($DEF_SOLID) and log debt")
case "$SOLID" in
  "Other — specify") SOLID=$(cqr_get SOLID_SPECIFY "Specify priority:" "$DEF_SOLID") ;;
  "Not sure"*)
    cqr_add_debt_auto "Patterns" "SOLID priority not confirmed" \
      "User could not confirm SOLID priority" "Defaulting to $DEF_SOLID"
    SOLID="$DEF_SOLID" ;;
esac

# Q3 — DRY (free text, domain-specific)
cqr_is_auto || { cqr_success_rule; printf '%b[Q3 of 6] DRY concerns%b\n' "$CQR_BOLD" "$CQR_NC"; }
DRY=$(cqr_get DRY "Known duplication areas (or 'None')" "$DEF_DRY")
[ -z "$DRY" ] && DRY="$DEF_DRY"

# Q4 — separation of concerns
cqr_is_auto || { cqr_success_rule; printf '%b[Q4 of 6] Separation of concerns%b\n' "$CQR_BOLD" "$CQR_NC"; }
SOC=$(cqr_get_choice SOC "Current state of SoC:" \
  "Well separated (services / repos / controllers)" \
  "Some leakage (business logic touching SQL or HTTP)" \
  "Significant leakage (mixed responsibilities)" \
  "Not assessed" \
  "Other — specify" \
  "Not sure — use default ($DEF_SOC) and log debt")
case "$SOC" in
  "Other — specify") SOC=$(cqr_get SOC_SPECIFY "Specify:" "$DEF_SOC") ;;
  "Not sure"*)
    cqr_add_debt_auto "Patterns" "SoC state not confirmed" \
      "User could not confirm separation-of-concerns state" "Defaulting to $DEF_SOC"
    SOC="$DEF_SOC" ;;
esac

# Q5 — error handling
cqr_is_auto || { cqr_success_rule; printf '%b[Q5 of 6] Error handling style%b\n' "$CQR_BOLD" "$CQR_NC"; }
ERRORS=$(cqr_get_choice ERRORS "Error handling approach:" \
  "Exceptions + custom exception types" \
  "Result<T,E> / Either<L,R> (functional style)" \
  "Error codes / tuple returns (Go, Rust-style)" \
  "Panic/recover or unchecked (language default)" \
  "Inconsistent — mixed approaches" \
  "Other — specify" \
  "Not sure — use default ($DEF_ERRORS) and log debt")
case "$ERRORS" in
  "Other — specify") ERRORS=$(cqr_get ERRORS_SPECIFY "Specify:" "$DEF_ERRORS") ;;
  "Not sure"*)
    cqr_add_debt_auto "Patterns" "Error-handling style not confirmed" \
      "User could not confirm error handling approach" "Defaulting to $DEF_ERRORS"
    ERRORS="$DEF_ERRORS" ;;
esac

# Q6 — logging
cqr_is_auto || { cqr_success_rule; printf '%b[Q6 of 6] Logging strategy%b\n' "$CQR_BOLD" "$CQR_NC"; }
LOGGING=$(cqr_get_choice LOGGING "Logging pattern:" \
  "Structured + level discipline (DEBUG/INFO/WARN/ERROR)" \
  "Structured logs only (JSON)" \
  "Plain text with levels" \
  "Plain text ad-hoc (no levels)" \
  "No logging" \
  "Other — specify" \
  "Not sure — use default ($DEF_LOGGING) and log debt")
case "$LOGGING" in
  "Other — specify") LOGGING=$(cqr_get LOGGING_SPECIFY "Specify:" "$DEF_LOGGING") ;;
  "Not sure"*)
    cqr_add_debt_auto "Patterns" "Logging strategy not confirmed" \
      "User could not confirm logging strategy" "Defaulting to $DEF_LOGGING"
    LOGGING="$DEF_LOGGING" ;;
esac

# ── Write output ──────────────────────────────────────────────────────────────
printf '\n%b✓ Writing patterns review to %s...%b\n' "$CQR_GREEN" "$OUTPUT_FILE" "$CQR_NC"

cat > "$OUTPUT_FILE" <<EOF
# Phase 3: Design Pattern & Architecture Compliance

**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')
**Status:** Complete
**Mode:** $(cqr_is_auto && echo Auto || echo Interactive)

## Analysis Parameters

| Parameter | Value |
|---|---|
| **Expected pattern** | $PATTERN |
| **SOLID priority** | $SOLID |
| **DRY concerns** | $DRY |
| **Separation of concerns** | $SOC |
| **Error handling** | $ERRORS |
| **Logging** | $LOGGING |

## Next Phase

Phase 4 (Quality Report) aggregates phases 1–3 and produces a composite score
with a prioritized remediation roadmap.

Run: \`bash <SKILL_DIR>/cqr-report/scripts/report.sh\`

---
EOF

cqr_write_extract "$EXTRACT_FILE" \
  "PATTERN=$PATTERN" \
  "SOLID=$SOLID" \
  "DRY=$DRY" \
  "SOC=$SOC" \
  "ERRORS=$ERRORS" \
  "LOGGING=$LOGGING"

cqr_success_rule
printf '%b✅ Phase 3 Complete.%b\n' "$CQR_GREEN" "$CQR_NC"
printf '  Markdown: %s\n' "$OUTPUT_FILE"
printf '  Extract:  %s\n' "$EXTRACT_FILE"
printf '\nNext: Phase 4 — bash <SKILL_DIR>/cqr-report/scripts/report.sh\n\n'
