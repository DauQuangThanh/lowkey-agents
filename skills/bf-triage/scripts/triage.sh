#!/bin/bash
# =============================================================================
# triage.sh — Phase 1: read bug / CQDEBT / CSDEBT sources, prioritise, pick batch.
#
# Reads:
#   - $TEST_OUTPUT_DIR/bugs.md        (primary)
#   - $CQR_OUTPUT_DIR/05-cq-debts.md  (optional)
#   - $CSR_OUTPUT_DIR/CSR-FINAL.md    (optional — scans for CSDEBT-NN)
#
# Writes:
#   - $BF_OUTPUT_DIR/01-triage.md
#   - $BF_OUTPUT_DIR/01-triage.extract
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

bf_parse_flags "$@"

OUTPUT_FILE="$BF_OUTPUT_DIR/01-triage.md"
EXTRACT_FILE="$BF_OUTPUT_DIR/01-triage.extract"

BUGS_FILE="${TEST_OUTPUT_DIR:-$(pwd)/test-output}/bugs.md"
CQR_DEBT_FILE="${CQR_OUTPUT_DIR:-$(pwd)/cqr-output}/05-cq-debts.md"
CSR_FINDINGS="${CSR_OUTPUT_DIR:-$(pwd)/csr-output}"

bf_banner "Phase 1 — Triage"

if bf_is_auto; then
  bf_dim "  [Auto mode] Reading the 3 sources; no prompts."
  echo ""
else
  bf_dim "  Reading test-output/bugs.md, cqr-output/05-cq-debts.md,"
  bf_dim "  and csr-output/*.md — scoring by priority × severity × effort."
  echo ""
fi

# ── Config / answers ─────────────────────────────────────────────────────────
TRIAGE_MAX_ITEMS=$(bf_get TRIAGE_MAX_ITEMS "Max items in this batch (default 10):" "10")
TRIAGE_MIN_SEVERITY=$(bf_get_choice TRIAGE_MIN_SEVERITY "Minimum severity to include:" \
  "Critical" "Major" "Minor" "Trivial")
TRIAGE_INCLUDE_SOURCES=$(bf_get_choice TRIAGE_INCLUDE_SOURCES "Include which sources?" \
  "bugs" \
  "bugs,cqdebt" \
  "bugs,cqdebt,csdebt" \
  "bugs,cqdebt,csdebt-all")

# ── Parse bugs.md ────────────────────────────────────────────────────────────
parse_bugs() {
  [ -f "$BUGS_FILE" ] || return 0
  awk '
    /^## BUG-/ {
      if (id != "") {
        gsub(/"/, "\\\"", title)
        printf "%s|bug|%s|%s|%s|%s\n", id, severity, priority, component, title
      }
      id = $2; sub(/:$/, "", id)
      title = $0
      sub(/^## [A-Z0-9-]+: */, "", title)
      severity = ""; priority = ""; component = ""
      next
    }
    /^\*\*Severity:\*\*/ { severity = $0; sub(/^\*\*Severity:\*\* */, "", severity); sub(/ *$/, "", severity) }
    /^\*\*Priority:\*\*/ { priority = $0; sub(/^\*\*Priority:\*\* */, "", priority); sub(/ *$/, "", priority) }
    /^\*\*Component:\*\*/ { component = $0; sub(/^\*\*Component:\*\* */, "", component); sub(/ *$/, "", component) }
    /^\*\*Status:\*\*/ {
      st = $0; sub(/^\*\*Status:\*\* */, "", st); sub(/ *$/, "", st)
      if (st != "Open" && st != "In Progress") {
        # skip already-resolved items
        id = ""
      }
    }
    END {
      if (id != "") {
        gsub(/"/, "\\\"", title)
        printf "%s|bug|%s|%s|%s|%s\n", id, severity, priority, component, title
      }
    }
  ' "$BUGS_FILE"
}

# ── Parse cq-debts.md ────────────────────────────────────────────────────────
parse_cqdebts() {
  [ -f "$CQR_DEBT_FILE" ] || return 0
  awk '
    /^## CQDEBT-/ {
      if (id != "") {
        gsub(/"/, "\\\"", title)
        printf "%s|cqdebt|%s|%s|%s|%s\n", id, severity, "P2", "", title
      }
      id = $2; sub(/:$/, "", id)
      title = $0
      sub(/^## [A-Z0-9-]+: */, "", title)
      severity = ""
    }
    /\*\*Severity\*\* \| / {
      severity = $0
      sub(/.*\*\*Severity\*\* \| */, "", severity)
      sub(/ *\|.*/, "", severity)
    }
    END {
      if (id != "") {
        gsub(/"/, "\\\"", title)
        printf "%s|cqdebt|%s|%s|%s|%s\n", id, severity, "P2", "", title
      }
    }
  ' "$CQR_DEBT_FILE"
}

# ── Parse CSR findings (CSDEBT-NN in csr-output/*.md) ────────────────────────
parse_csdebts() {
  [ -d "$CSR_FINDINGS" ] || return 0
  for f in "$CSR_FINDINGS"/*.md; do
    [ -f "$f" ] || continue
    awk '
      /^## CSDEBT-/ {
        id = $2; sub(/:$/, "", id)
        title = $0
        sub(/^## [A-Z0-9-]+: */, "", title)
        gsub(/"/, "\\\"", title)
        printf "%s|csdebt|%s|%s|%s|%s\n", id, "Major", "P1", "", title
      }
    ' "$f"
  done
}

# ── Severity rank (lower = higher priority) ──────────────────────────────────
sev_rank() {
  case "$1" in
    Critical) printf 1 ;;
    Major)    printf 2 ;;
    Minor)    printf 3 ;;
    Trivial)  printf 4 ;;
    *)        printf 5 ;;
  esac
}

min_sev_rank=$(sev_rank "$TRIAGE_MIN_SEVERITY")

# ── Build unified work-list ──────────────────────────────────────────────────
TMP_LIST="$BF_OUTPUT_DIR/.triage-items.tmp"
: > "$TMP_LIST"

case "$TRIAGE_INCLUDE_SOURCES" in
  bugs)                    parse_bugs >> "$TMP_LIST" ;;
  bugs,cqdebt)             parse_bugs >> "$TMP_LIST"; parse_cqdebts >> "$TMP_LIST" ;;
  bugs,cqdebt,csdebt*)     parse_bugs >> "$TMP_LIST"; parse_cqdebts >> "$TMP_LIST"; parse_csdebts >> "$TMP_LIST" ;;
esac

# Filter by severity, sort by (sev_rank, priority), cap at MAX_ITEMS
BATCH_FILE="$BF_OUTPUT_DIR/.triage-batch.tmp"
: > "$BATCH_FILE"

while IFS='|' read -r id source severity priority component title; do
  [ -z "$id" ] && continue
  rank=$(sev_rank "$severity")
  if [ "$rank" -le "$min_sev_rank" ]; then
    printf '%d|%s|%s|%s|%s|%s|%s\n' "$rank" "$id" "$source" "$severity" "$priority" "$component" "$title" >> "$BATCH_FILE"
  fi
done < "$TMP_LIST"

# Sort by rank then priority
SORTED="$BF_OUTPUT_DIR/.triage-sorted.tmp"
sort -t'|' -k1,1n -k5,5 "$BATCH_FILE" > "$SORTED"

# Cap
HEAD_FILE="$BF_OUTPUT_DIR/.triage-head.tmp"
head -n "$TRIAGE_MAX_ITEMS" "$SORTED" > "$HEAD_FILE"
TOTAL_ITEMS=$(wc -l < "$SORTED" | tr -d ' ')
BATCH_SIZE=$(wc -l < "$HEAD_FILE" | tr -d ' ')
DEFERRED=$((TOTAL_ITEMS - BATCH_SIZE))

BATCH_IDS=""
while IFS='|' read -r rank id source severity priority component title; do
  [ -z "$id" ] && continue
  BATCH_IDS="${BATCH_IDS}${id},"
done < "$HEAD_FILE"
BATCH_IDS="${BATCH_IDS%,}"
[ -z "$BATCH_IDS" ] && BATCH_IDS="(empty)"

# ── Write markdown report ────────────────────────────────────────────────────
{
  echo "# Phase 1 — Triage"
  echo ""
  echo "**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Mode:** $(bf_is_auto && echo Auto || echo Interactive)"
  echo "**Min severity:** $TRIAGE_MIN_SEVERITY"
  echo "**Sources:** $TRIAGE_INCLUDE_SOURCES"
  echo "**Cap:** $TRIAGE_MAX_ITEMS"
  echo ""
  echo "## Selected Batch ($BATCH_SIZE of $TOTAL_ITEMS matching items)"
  echo ""
  if [ "$BATCH_SIZE" -eq 0 ]; then
    echo "_No items matched the current filters. Relax TRIAGE_MIN_SEVERITY or widen TRIAGE_INCLUDE_SOURCES._"
  else
    echo "| # | ID | Source | Severity | Priority | Component | Title |"
    echo "|---|---|---|---|---|---|---|"
    idx=1
    while IFS='|' read -r rank id source severity priority component title; do
      [ -z "$id" ] && continue
      printf '| %d | %s | %s | %s | %s | %s | %s |\n' \
        "$idx" "$id" "$source" "$severity" "$priority" "${component:-unknown}" "$title"
      idx=$((idx + 1))
    done < "$HEAD_FILE"
  fi
  echo ""
  echo "## Deferred ($DEFERRED items)"
  echo ""
  if [ "$DEFERRED" -le 0 ]; then
    echo "_None — all matching items included in this batch._"
  else
    echo "Items below the cap are not lost — they remain in the source files and re-appear in the next triage run. Bump \`TRIAGE_MAX_ITEMS\` to include more."
  fi
  echo ""
  echo "## Next Phase"
  echo ""
  echo "Run: \`bash <SKILL_DIR>/bf-fix/scripts/fix.sh\`"
  echo ""
  echo "---"
} > "$OUTPUT_FILE"

# ── Extract file ─────────────────────────────────────────────────────────────
bf_write_extract "$EXTRACT_FILE" \
  "BATCH_IDS=$BATCH_IDS" \
  "BATCH_SIZE=$BATCH_SIZE" \
  "DEFERRED_COUNT=$DEFERRED" \
  "TRIAGE_MAX_ITEMS=$TRIAGE_MAX_ITEMS" \
  "TRIAGE_MIN_SEVERITY=$TRIAGE_MIN_SEVERITY" \
  "TRIAGE_INCLUDE_SOURCES=$TRIAGE_INCLUDE_SOURCES" \
  "BUGS_FILE=$BUGS_FILE" \
  "CQR_DEBT_FILE=$CQR_DEBT_FILE" \
  "CSR_FINDINGS_DIR=$CSR_FINDINGS" \
  "BATCH_LIST_FILE=$HEAD_FILE"

# Clean up intermediate tmps except the HEAD_FILE (kept for bf-fix consumption).
rm -f "$TMP_LIST" "$BATCH_FILE" "$SORTED"

bf_success_rule "✅ Phase 1 Complete — Batch: $BATCH_SIZE item(s), Deferred: $DEFERRED"
printf '  Markdown: %s\n' "$OUTPUT_FILE"
printf '  Extract:  %s\n' "$EXTRACT_FILE"
printf '  Batch list (machine-readable): %s\n' "$HEAD_FILE"
printf '\nNext: Phase 2 — bash <SKILL_DIR>/bf-fix/scripts/fix.sh\n\n'
