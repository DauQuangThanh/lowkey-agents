#!/bin/bash
# =============================================================================
# validate.sh — Phase 6: Architecture Validation & Sign-Off
# Automated completeness checks + manual sign-off questions, then compiles
# ARCHITECTURE-FINAL.md.
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
arch_parse_flags "$@"


REPORT_FILE="$ARCH_OUTPUT_DIR/06-architecture-validation.md"
FINAL_FILE="$ARCH_OUTPUT_DIR/ARCHITECTURE-FINAL.md"

arch_banner "✅  Step 6 of 6 — Architecture Validation & Sign-Off"
arch_dim "  Run automated checks + manual sign-off questions, then compile the final doc."
echo ""

# ── Automated checks ──────────────────────────────────────────────────────────
passed=0
failed=0
warnings=0
report_lines=()

check_file_exists() {
  local label="$1" path="$2"
  if [ -f "$path" ] && [ -s "$path" ]; then
    report_lines+=("- ✅ $label exists (\`$(basename "$path")\`)")
    passed=$((passed + 1))
  else
    report_lines+=("- ❌ $label missing or empty (\`$(basename "$path")\`)")
    failed=$((failed + 1))
  fi
}

intake_f="$ARCH_OUTPUT_DIR/01-architecture-intake.md"
research_f="$ARCH_OUTPUT_DIR/02-technology-research.md"
adr_index_f="$ARCH_OUTPUT_DIR/03-adr-index.md"
arch_doc_f="$ARCH_OUTPUT_DIR/04-architecture.md"
tdebt_f="$ARCH_TDEBT_FILE"
context_mmd="$ARCH_DIAGRAMS_DIR/context.mmd"
containers_mmd="$ARCH_DIAGRAMS_DIR/containers.mmd"

printf '%b%b── Automated Checks ──%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"

check_file_exists "Architecture intake"      "$intake_f"
check_file_exists "Technology research"      "$research_f"
check_file_exists "ADR index"                "$adr_index_f"
check_file_exists "C4 architecture document" "$arch_doc_f"
check_file_exists "Context diagram"          "$context_mmd"
check_file_exists "Container diagram"        "$containers_mmd"

# ADR content checks
adr_total=$(arch_current_adr_count)
if [ "$adr_total" -eq 0 ]; then
  report_lines+=("- ❌ No ADRs were captured")
  failed=$((failed + 1))
else
  report_lines+=("- ✅ $adr_total ADR(s) captured")
  passed=$((passed + 1))

  missing_sections=0
  stale_proposed=0
  today=$(date '+%Y-%m-%d')

  for f in "$ARCH_ADR_DIR"/ADR-????-*.md; do
    [ -f "$f" ] || continue
    has_ctx=$(grep -c '^## Context'               "$f" 2>/dev/null | head -1 | tr -dc '0-9'); [ -z "$has_ctx" ] && has_ctx=0
    has_dec=$(grep -c '^## Decision'              "$f" 2>/dev/null | head -1 | tr -dc '0-9'); [ -z "$has_dec" ] && has_dec=0
    has_alt=$(grep -c '^## Alternatives Considered' "$f" 2>/dev/null | head -1 | tr -dc '0-9'); [ -z "$has_alt" ] && has_alt=0
    has_con=$(grep -c '^## Consequences'          "$f" 2>/dev/null | head -1 | tr -dc '0-9'); [ -z "$has_con" ] && has_con=0
    if [ "$has_ctx" -eq 0 ] || [ "$has_dec" -eq 0 ] || [ "$has_alt" -eq 0 ] || [ "$has_con" -eq 0 ]; then
      missing_sections=$((missing_sections + 1))
    fi

    status_line=$(grep -m1 '^- \*\*Status:\*\*' "$f" 2>/dev/null | sed -E 's/^- \*\*Status:\*\* //')
    if printf '%s' "$status_line" | grep -qi '^Proposed'; then
      tdate=$(grep -m1 '^- \*\*Target decision date:\*\*' "$f" 2>/dev/null | sed -E 's/^- \*\*Target decision date:\*\* //')
      if [ -n "$tdate" ] && [ "$tdate" != "TBD" ]; then
        if [ "$tdate" \< "$today" ]; then
          stale_proposed=$((stale_proposed + 1))
        fi
      fi
    fi
  done

  if [ "$missing_sections" -eq 0 ]; then
    report_lines+=("- ✅ All ADRs have Context / Decision / Alternatives / Consequences sections")
    passed=$((passed + 1))
  else
    report_lines+=("- ❌ $missing_sections ADR(s) missing one or more required sections")
    failed=$((failed + 1))
  fi

  if [ "$stale_proposed" -eq 0 ]; then
    report_lines+=("- ✅ No ADRs stuck in *Proposed* past their target date")
    passed=$((passed + 1))
  else
    report_lines+=("- ⚠️ $stale_proposed ADR(s) *Proposed* with target date in the past")
    warnings=$((warnings + 1))
  fi
fi

# Container → ADR check (look at C4 container table)
if [ -f "$arch_doc_f" ]; then
  containers_with_tbd=$(grep -E '^\| .+ \| .+ \| .+ \| TBD \|' "$arch_doc_f" 2>/dev/null | wc -l | tr -dc '0-9')
  [ -z "$containers_with_tbd" ] && containers_with_tbd=0
  if [ "$containers_with_tbd" -eq 0 ]; then
    report_lines+=("- ✅ All containers in the C4 doc reference an ADR")
    passed=$((passed + 1))
  else
    report_lines+=("- ❌ $containers_with_tbd container(s) in the C4 doc have TBD ADR references")
    failed=$((failed + 1))
  fi
fi

# Blocking TDEBT check
if [ -f "$tdebt_f" ]; then
  # Count open blocking debts: line has 'Blocking' and corresponding entry has Status: Open
  # Simpler heuristic: count 'Blocking' lines
  blocking_count=$(grep -c 'Blocking' "$tdebt_f" 2>/dev/null | head -1 | tr -dc '0-9'); [ -z "$blocking_count" ] && blocking_count=0
  if [ "$blocking_count" -eq 0 ]; then
    report_lines+=("- ✅ No 🔴 Blocking technical debts")
    passed=$((passed + 1))
  else
    report_lines+=("- ❌ $blocking_count 🔴 Blocking technical debt(s) present")
    failed=$((failed + 1))
  fi

  # Un-mitigated high/high risks
  unmitigated=0
  while IFS= read -r block_start; do
    [ -z "$block_start" ] && continue
    # (skipping precise multi-line parse; heuristic below)
  done < <(grep -n '^## RISK-' "$tdebt_f" 2>/dev/null || true)

  # Heuristic: count risks that have both "Likelihood:** High" and "Impact:** High" and "Mitigation (proactive):** TBD"
  # Do it in a single awk pass.
  unmitigated=$(awk '
    /^## RISK-/ { in_risk=1; l=""; i=""; m=""; next }
    in_risk && /^\*\*Likelihood:\*\*/ { l=$0 }
    in_risk && /^\*\*Impact:\*\*/     { i=$0 }
    in_risk && /^\*\*Mitigation/      { m=$0 }
    /^$/ && in_risk {
      if (l ~ /High/ && i ~ /High/ && m ~ /TBD/) count++
      in_risk=0
    }
    END { print count+0 }
  ' "$tdebt_f" 2>/dev/null)
  [ -z "$unmitigated" ] && unmitigated=0
  if [ "$unmitigated" -eq 0 ]; then
    report_lines+=("- ✅ No High-likelihood/High-impact risk without mitigation")
    passed=$((passed + 1))
  else
    report_lines+=("- ❌ $unmitigated High/High risk(s) with TBD mitigation")
    failed=$((failed + 1))
  fi
fi

# Print each check
for line in "${report_lines[@]}"; do
  printf '  %s\n' "$line"
done
echo ""
printf '  %bPassed:%b   %d\n' "$ARCH_GREEN" "$ARCH_NC" "$passed"
printf '  %bWarnings:%b %d\n' "$ARCH_YELLOW" "$ARCH_NC" "$warnings"
printf '  %bFailed:%b   %d\n' "$ARCH_RED" "$ARCH_NC" "$failed"
echo ""

# ── Manual sign-off questions ────────────────────────────────────────────────
printf '%b%b── Manual Sign-Off Questions ──%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"
echo ""
m1=$(arch_ask_yn "Does the architecture trace cleanly to the problem statement?")
m2=$(arch_ask_yn "Are all stakeholders aware of decisions that affect them?")
m3=$(arch_ask_yn "Is the cost envelope acceptable?")
m4=$(arch_ask_yn "Is there a walkaway plan if a key vendor fails?")
echo ""
arch_dim "  Sign-off status per reviewer:"
sign_eng=$(arch_ask_choice "  Engineering lead"      "Signed off" "Pending" "Not required")
sign_sec=$(arch_ask_choice "  Security"              "Signed off" "Pending" "Not required")
sign_ops=$(arch_ask_choice "  Ops / Platform"        "Signed off" "Pending" "Not required")
sign_prd=$(arch_ask_choice "  Product / Business"    "Signed off" "Pending" "Not required")

manual_no_count=0
[ "$m1" = "no" ] && manual_no_count=$((manual_no_count + 1))
[ "$m2" = "no" ] && manual_no_count=$((manual_no_count + 1))
[ "$m3" = "no" ] && manual_no_count=$((manual_no_count + 1))
[ "$m4" = "no" ] && manual_no_count=$((manual_no_count + 1))

# ── Final verdict ─────────────────────────────────────────────────────────────
verdict="❌ NOT READY"
verdict_reason="Automated or manual checks failed"

if [ "$failed" -eq 0 ] && [ "$manual_no_count" -eq 0 ] && [ "$warnings" -eq 0 ]; then
  verdict="✅ APPROVED"
  verdict_reason="All automated and manual checks passed"
elif [ "$failed" -eq 0 ] && [ "$manual_no_count" -le 1 ] && [ "$warnings" -le 2 ]; then
  verdict="⚠️ CONDITIONALLY APPROVED"
  verdict_reason="Minor gaps — track each as a TDEBT"
fi

arch_success_rule "$verdict"
printf '  %s\n' "$verdict_reason"
echo ""

# ── Write validation report ───────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Architecture Validation Report"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "## Verdict: $verdict"
  echo ""
  echo "_${verdict_reason}_"
  echo ""
  echo "## Automated Checks"
  echo ""
  for line in "${report_lines[@]}"; do
    printf '%s\n' "$line"
  done
  echo ""
  echo "Passed: $passed  |  Warnings: $warnings  |  Failed: $failed"
  echo ""
  echo "## Manual Sign-Off Questions"
  echo ""
  echo "| Question | Answer |"
  echo "|---|---|"
  echo "| Architecture traces to problem statement | $m1 |"
  echo "| Stakeholders aware of affecting decisions | $m2 |"
  echo "| Cost envelope acceptable | $m3 |"
  echo "| Walkaway plan for key-vendor failure | $m4 |"
  echo ""
  echo "## Sign-Off"
  echo ""
  echo "| Reviewer | Status |"
  echo "|---|---|"
  echo "| Engineering lead | $sign_eng |"
  echo "| Security | $sign_sec |"
  echo "| Ops / Platform | $sign_ops |"
  echo "| Product / Business | $sign_prd |"
  echo ""
} > "$REPORT_FILE"

printf '%b  Report saved to: %s%b\n' "$ARCH_GREEN" "$REPORT_FILE" "$ARCH_NC"

# ── Compile final document ────────────────────────────────────────────────────
{
  echo "# Architecture — Final Deliverable"
  echo ""
  echo "> Auto-compiled $(date '+%Y-%m-%d %H:%M')"
  echo "> Verdict: $verdict"
  echo ""
  echo "---"
  echo ""
  for f in \
    "$intake_f" \
    "$research_f" \
    "$adr_index_f" \
    "$arch_doc_f" \
    "$tdebt_f" \
    "$REPORT_FILE"; do
    if [ -f "$f" ]; then
      echo ""
      cat "$f"
      echo ""
      echo "---"
      echo ""
    fi
  done

  # Append individual ADRs
  if [ "$adr_total" -gt 0 ]; then
    echo ""
    echo "## Appendix — Full ADR Contents"
    echo ""
    for adr in "$ARCH_ADR_DIR"/ADR-????-*.md; do
      [ -f "$adr" ] || continue
      cat "$adr"
      echo ""
      echo "---"
      echo ""
    done
  fi
} > "$FINAL_FILE"

printf '%b  Final document: %s%b\n' "$ARCH_GREEN" "$FINAL_FILE" "$ARCH_NC"
echo ""
