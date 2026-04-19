#!/bin/bash
# =============================================================================
# new-adr.sh — Phase 3: ADR Builder
# Creates one or more Architecture Decision Records using the Michael Nygard
# template. Writes each ADR to $ARCH_ADR_DIR/ADR-NNNN-<slug>.md and regenerates
# $ARCH_OUTPUT_DIR/03-adr-index.md.
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
arch_parse_flags "$@"


INDEX_FILE="$ARCH_OUTPUT_DIR/03-adr-index.md"
AREA="ADR Builder"

start_tdebts=$(arch_current_tdebt_count)

mkdir -p "$ARCH_ADR_DIR"

arch_banner "📜  Step 3 of 6 — ADR Builder"
arch_dim "  An Architecture Decision Record (ADR) captures ONE significant decision"
arch_dim "  using the Michael Nygard template. ADRs are append-only — to change a"
arch_dim "  decision, write a new ADR that supersedes the old one."
echo ""

existing=$(arch_current_adr_count)
if [ "$existing" -gt 0 ]; then
  printf '%b  Found %d existing ADR(s) in %s%b\n\n' "$ARCH_CYAN" "$existing" "$ARCH_ADR_DIR" "$ARCH_NC"
fi

# ── ADR capture function ─────────────────────────────────────────────────────
capture_adr() {
  local adr_id title slug status date_val deciders
  local context decision alt1 alt2 alt3 cons_pos cons_neg cons_follow refs
  local target_date supersedes

  adr_id=$(arch_next_adr_id)
  printf '%b%b── New ADR: %s ──%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$adr_id" "$ARCH_NC"
  echo ""

  title=$(arch_ask "  Short title (noun phrase, e.g. 'Use PostgreSQL as primary database'):")
  if [ -z "$title" ]; then
    printf '%b  Title is required — skipping this ADR.%b\n' "$ARCH_RED" "$ARCH_NC"
    return 1
  fi
  slug=$(arch_slugify "$title")

  status=$(arch_ask_choice "  Status?" \
    "Proposed — decision is open for discussion" \
    "Accepted — decision is in effect" \
    "Deprecated — no longer recommended" \
    "Superseded — replaced by a newer ADR")

  date_val=$(arch_ask "  Decision date (YYYY-MM-DD)? Enter for today:")
  [ -z "$date_val" ] && date_val=$(date '+%Y-%m-%d')

  deciders=$(arch_ask "  Deciders (names or roles, comma-separated):")
  [ -z "$deciders" ] && deciders="TBD"

  target_date="N/A"
  if printf '%s' "$status" | grep -q '^Proposed'; then
    target_date=$(arch_ask "  Target decision date (YYYY-MM-DD)? Enter for TBD:")
    if [ -z "$target_date" ]; then
      target_date="TBD"
      arch_add_tdebt "$AREA" "$adr_id Proposed without target date" \
        "ADR '$title' is Proposed with no target decision date" \
        "Open decision may block downstream work indefinitely"
    fi
  fi

  supersedes="None"
  if printf '%s' "$status" | grep -q '^Superseded'; then
    supersedes=$(arch_ask "  Which ADR does this supersede? (e.g. ADR-0003)")
    [ -z "$supersedes" ] && supersedes="TBD"
  fi

  echo ""
  arch_dim "  CONTEXT — the forces at play: requirements, constraints, NFRs."
  context=$(arch_ask "  Context (2–4 sentences — or a short summary; refine in editor later):")
  [ -z "$context" ] && context="TBD — context not captured"

  echo ""
  arch_dim "  DECISION — one clear paragraph, active voice."
  decision=$(arch_ask "  Decision:")
  [ -z "$decision" ] && decision="TBD — decision not captured"

  echo ""
  arch_dim "  ALTERNATIVES — 2 or 3 rejected options, each with 'rejected because...'"
  alt1=$(arch_ask "  Alternative 1 (or Enter to skip):")
  alt2=$(arch_ask "  Alternative 2 (or Enter to skip):")
  alt3=$(arch_ask "  Alternative 3 (or Enter to skip):")

  echo ""
  cons_pos=$(arch_ask "  Positive consequences (what improves):")
  [ -z "$cons_pos" ] && cons_pos="TBD"
  cons_neg=$(arch_ask "  Negative consequences / trade-offs (what we accept):")
  [ -z "$cons_neg" ] && cons_neg="TBD"
  cons_follow=$(arch_ask "  Follow-up actions (other ADRs, migrations, training):")
  [ -z "$cons_follow" ] && cons_follow="None"

  echo ""
  refs=$(arch_ask "  References (requirement IDs, docs, URLs — comma-separated):")
  [ -z "$refs" ] && refs="None"

  # Write ADR file
  local adr_file="$ARCH_ADR_DIR/${adr_id}-${slug}.md"
  {
    echo "# ${adr_id}: ${title}"
    echo ""
    echo "- **Status:** ${status%% —*}"
    if [ "$target_date" != "N/A" ]; then
      echo "- **Target decision date:** ${target_date}"
    fi
    if [ "$supersedes" != "None" ]; then
      echo "- **Supersedes:** ${supersedes}"
    fi
    echo "- **Date:** ${date_val}"
    echo "- **Deciders:** ${deciders}"
    echo ""
    echo "## Context"
    echo ""
    echo "${context}"
    echo ""
    echo "## Decision"
    echo ""
    echo "${decision}"
    echo ""
    echo "## Alternatives Considered"
    echo ""
    [ -n "$alt1" ] && echo "- ${alt1}"
    [ -n "$alt2" ] && echo "- ${alt2}"
    [ -n "$alt3" ] && echo "- ${alt3}"
    if [ -z "$alt1" ] && [ -z "$alt2" ] && [ -z "$alt3" ]; then
      echo "- _None captured — a TDEBT has been logged for this ADR._"
      arch_add_tdebt "$AREA" "$adr_id has no alternatives" \
        "No alternative options captured" \
        "Decision appears unconsidered / non-justifiable"
    fi
    echo ""
    echo "## Consequences"
    echo ""
    echo "- ✅ **Positive:** ${cons_pos}"
    echo "- ⚠️ **Negative / trade-offs:** ${cons_neg}"
    echo "- 🔁 **Follow-up actions:** ${cons_follow}"
    echo ""
    echo "## References"
    echo ""
    echo "${refs}"
    echo ""
  } > "$adr_file"

  printf '\n%b  ✅ Saved: %s%b\n\n' "$ARCH_GREEN" "$adr_file" "$ARCH_NC"
  return 0
}

# ── Loop: capture one or more ADRs ───────────────────────────────────────────
capture_adr || true
while true; do
  more=$(arch_ask_yn "Add another ADR?")
  if [ "$more" = "no" ]; then break; fi
  capture_adr || true
done

# ── Regenerate index ──────────────────────────────────────────────────────────
total_adrs=$(arch_current_adr_count)
{
  echo "# ADR Index"
  echo ""
  echo "> Regenerated: $(date '+%Y-%m-%d %H:%M')"
  echo ""
  echo "All Architecture Decision Records for this project. ADRs are append-only — to"
  echo "change a decision, write a new ADR with status *Accepted* that supersedes the old."
  echo ""
  echo "| ID | Title | Status | Date |"
  echo "|---|---|---|---|"

  # List ADR files in order
  ls -1 "$ARCH_ADR_DIR" 2>/dev/null | grep -E '^ADR-[0-9]{4}-.*\.md$' | sort | while read -r f; do
    local_file="$ARCH_ADR_DIR/$f"
    local_id=$(printf '%s' "$f" | sed -E 's/^(ADR-[0-9]{4}).*/\1/')
    local_title=$(grep -m1 '^# ADR-' "$local_file" 2>/dev/null | sed -E "s/^# $local_id: //")
    local_status=$(grep -m1 '^- \*\*Status:\*\*' "$local_file" 2>/dev/null | sed -E 's/^- \*\*Status:\*\* //')
    local_date=$(grep -m1 '^- \*\*Date:\*\*' "$local_file" 2>/dev/null | sed -E 's/^- \*\*Date:\*\* //')
    [ -z "$local_title" ] && local_title="(no title)"
    [ -z "$local_status" ] && local_status="(no status)"
    [ -z "$local_date" ] && local_date="(no date)"
    printf '| [%s](adr/%s) | %s | %s | %s |\n' \
      "$local_id" "$f" "$local_title" "$local_status" "$local_date"
  done
  echo ""
  echo "Total: ${total_adrs} ADR(s)"
} > "$INDEX_FILE"

end_tdebts=$(arch_current_tdebt_count)
new_tdebts=$((end_tdebts - start_tdebts))

arch_success_rule "✅ ADR Index Updated"
printf '%b  Index:    %s%b\n' "$ARCH_GREEN" "$INDEX_FILE" "$ARCH_NC"
printf '%b  ADR dir:  %s%b\n' "$ARCH_GREEN" "$ARCH_ADR_DIR" "$ARCH_NC"
printf '%b  Total:    %s ADR(s)%b\n' "$ARCH_GREEN" "$total_adrs" "$ARCH_NC"
if [ "$new_tdebts" -gt 0 ]; then
  printf '%b  ⚠  %d technical debt(s) logged to: %s%b\n' "$ARCH_YELLOW" "$new_tdebts" "$ARCH_TDEBT_FILE" "$ARCH_NC"
fi
echo ""
