#!/bin/bash
# =============================================================================
# validate-requirements.sh — Phase 7: Requirements Validation & Sign-Off
# Runs a completeness checklist and compiles the final requirements document.
# Output: $BA_OUTPUT_DIR/07-validation-report.md + REQUIREMENTS-FINAL.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ba_parse_flags "$@"


VALIDATION_FILE="$BA_OUTPUT_DIR/07-validation-report.md"
FINAL_FILE="$BA_OUTPUT_DIR/REQUIREMENTS-FINAL.md"

PASSED=0
FAILED=0
SKIPPED=0
CHECKLIST_RESULTS=()

check_item() {
  local description="$1" check_fn="$2"
  printf '%b  Checking: %s...%b\n' "$BA_DIM" "$description" "$BA_NC"

  local result
  result=$("$check_fn")
  case "$result" in
    pass)
      PASSED=$((PASSED + 1))
      CHECKLIST_RESULTS+=("| ✅ PASS | $description |")
      printf '%b    ✅ PASS%b\n' "$BA_GREEN" "$BA_NC"
      ;;
    warn)
      FAILED=$((FAILED + 1))
      CHECKLIST_RESULTS+=("| ⚠️ WARN | $description |")
      printf '%b    ⚠  WARNING — may need attention%b\n' "$BA_YELLOW" "$BA_NC"
      ;;
    *)
      FAILED=$((FAILED + 1))
      CHECKLIST_RESULTS+=("| ❌ FAIL | $description |")
      printf '%b    ❌ FAIL — add to requirement debts%b\n' "$BA_RED" "$BA_NC"
      ;;
  esac
}

# ── Automated checks ──────────────────────────────────────────────────────────
check_project_intake() { [ -f "$BA_OUTPUT_DIR/01-project-intake.md" ] && printf 'pass' || printf 'fail'; }
check_stakeholders()   { [ -f "$BA_OUTPUT_DIR/02-stakeholders.md"   ] && printf 'pass' || printf 'fail'; }
check_requirements()   { [ -f "$BA_OUTPUT_DIR/03-requirements.md"   ] && printf 'pass' || printf 'fail'; }
check_user_stories()   { [ -f "$BA_OUTPUT_DIR/04-user-stories.md"   ] && printf 'pass' || printf 'fail'; }
check_nfr()            { [ -f "$BA_OUTPUT_DIR/05-nfr.md"            ] && printf 'pass' || printf 'warn'; }

check_problem_statement() {
  local file="$BA_OUTPUT_DIR/01-project-intake.md"
  if [ ! -f "$file" ]; then printf 'fail'; return; fi
  if grep -A2 '^## Problem Statement' "$file" 2>/dev/null | grep -q '^TBD$'; then
    printf 'warn'
  else
    printf 'pass'
  fi
}

check_ac_exists() {
  local file="$BA_OUTPUT_DIR/04-user-stories.md"
  if [ ! -f "$file" ]; then printf 'fail'; return; fi
  if grep -q 'not yet defined' "$file" 2>/dev/null; then
    printf 'warn'
  else
    printf 'pass'
  fi
}

check_no_blocking_debts() {
  if [ ! -f "$BA_DEBT_FILE" ]; then printf 'pass'; return; fi
  local blocking
  blocking=$(grep -c 'Blocking' "$BA_DEBT_FILE" 2>/dev/null || printf '0')
  blocking=$(printf '%s' "$blocking" | head -1 | tr -dc '0-9')
  [ -z "$blocking" ] && blocking=0
  if [ "$blocking" -eq 0 ]; then printf 'pass'; else printf 'warn'; fi
}

check_out_of_scope() {
  local file="$BA_OUTPUT_DIR/01-project-intake.md"
  if [ ! -f "$file" ]; then printf 'fail'; return; fi
  if grep -A2 '^## Out of Scope' "$file" 2>/dev/null | grep -q '^To be defined$'; then
    printf 'warn'
  else
    printf 'pass'
  fi
}

# ── Header ────────────────────────────────────────────────────────────────────
ba_banner "✅  Step 7 of 7 — Validation & Sign-Off"
ba_dim "  We're nearly done! Let me check that all key areas are covered."
echo ""

# ── Automated completeness checks ────────────────────────────────────────────
printf '%b%b── Automated Completeness Checks ──%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
echo ""
check_item "Project intake completed"                 check_project_intake
check_item "Stakeholders identified"                  check_stakeholders
check_item "Functional requirements captured"         check_requirements
check_item "User stories created"                     check_user_stories
check_item "Non-functional requirements captured"     check_nfr
check_item "Problem statement is defined"             check_problem_statement
check_item "All user stories have acceptance criteria" check_ac_exists
check_item "No blocking requirement debts open"       check_no_blocking_debts
check_item "Out-of-scope items defined"               check_out_of_scope
echo ""

# ── Manual validation questions ───────────────────────────────────────────────
printf '%b%b── Manual Validation Questions ──%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
ba_dim "  Please answer these questions based on your knowledge of the project."
echo ""

manual_check() {
  local question="$1" description="$2"
  printf '%b▶ %s%b\n' "$BA_YELLOW" "$question" "$BA_NC"
  local raw norm
  if ba_is_auto; then
    # Auto mode: mark as TBD (unsure) to preserve the manual nature of
    # these checks — a human still needs to confirm them.
    SKIPPED=$((SKIPPED + 1))
    CHECKLIST_RESULTS+=("| ❓ TBD  | $description |")
    printf '%b    ❓ Auto: marked as TBD (needs human review)%b\n' "$BA_YELLOW" "$BA_NC"
    return
  fi
  while : ; do
    printf '  (y=yes / n=no / u=unsure): '
    IFS= read -r raw
    norm=$(to_lower "$raw")
    case "$norm" in
      y|yes)
        PASSED=$((PASSED + 1))
        CHECKLIST_RESULTS+=("| ✅ PASS | $description |")
        printf '%b    ✅ Confirmed%b\n' "$BA_GREEN" "$BA_NC"
        return
        ;;
      n|no)
        FAILED=$((FAILED + 1))
        CHECKLIST_RESULTS+=("| ❌ FAIL | $description |")
        printf '%b    ❌ Logged as gap%b\n' "$BA_RED" "$BA_NC"
        return
        ;;
      u|unsure)
        SKIPPED=$((SKIPPED + 1))
        CHECKLIST_RESULTS+=("| ❓ TBD  | $description |")
        printf '%b    ❓ Marked as TBD%b\n' "$BA_YELLOW" "$BA_NC"
        return
        ;;
      *) printf '%b  Please enter y, n, or u.%b\n' "$BA_RED" "$BA_NC" ;;
    esac
  done
}

manual_check \
  "Does every stakeholder group have at least one user story representing their needs?" \
  "All stakeholder groups represented in user stories"

manual_check \
  "Do all the requirements trace back to the problem statement (nothing included just 'because it would be nice')?" \
  "Requirements traceable to problem statement"

manual_check \
  "Does the team agree on what is IN scope vs OUT of scope?" \
  "Scope clearly defined and agreed"

manual_check \
  "Are all requirements free of direct contradictions? (answer YES if there are NO conflicts)" \
  "No conflicting requirements"

manual_check \
  "Have the main stakeholders reviewed and agreed with these requirements?" \
  "Key stakeholder sign-off obtained or planned"

manual_check \
  "Are all 'must have' user stories specific enough for a developer to start building?" \
  "Must-have stories are specific enough to develop"

# ── Collect reviewer info ─────────────────────────────────────────────────────
echo ""
printf '%b%b── Sign-Off Details ──%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
echo ""
reviewer_name=$(ba_ask "Your name (person completing this validation):")
[ -z "$reviewer_name" ] && reviewer_name="Anonymous"
review_date=$(date '+%Y-%m-%d')

echo ""
ba_dim "  Pass: $PASSED  |  Issues: $FAILED  |  TBD: $SKIPPED"
echo ""

if [ "$FAILED" -eq 0 ] && [ "$SKIPPED" -eq 0 ]; then
  signoff_status="✅ APPROVED"
  printf '%b%b  🎉 All checks passed! Requirements are ready for development.%b\n' "$BA_GREEN" "$BA_BOLD" "$BA_NC"
elif [ "$FAILED" -le 2 ] && [ "$SKIPPED" -le 2 ]; then
  signoff_status="⚠️ CONDITIONALLY APPROVED"
  printf '%b%b  ⚠  Minor gaps detected. Review the issues above before starting development.%b\n' "$BA_YELLOW" "$BA_BOLD" "$BA_NC"
else
  signoff_status="❌ NOT READY"
  printf '%b%b  ❌ Several gaps found. Resolve the issues above before starting development.%b\n' "$BA_RED" "$BA_BOLD" "$BA_NC"
fi
echo ""

# ── Write validation report ───────────────────────────────────────────────────
{
  echo "# Validation Report"
  echo ""
  echo "> Review date: $review_date | Reviewer: $reviewer_name"
  echo ""
  echo "## Status: $signoff_status"
  echo ""
  echo "| Checks Passed | Issues Found | TBD |"
  echo "|---|---|---|"
  echo "| $PASSED | $FAILED | $SKIPPED |"
  echo ""
  echo "## Checklist Results"
  echo ""
  echo "| Result | Item |"
  echo "|---|---|"
  for r in "${CHECKLIST_RESULTS[@]}"; do echo "$r"; done
  echo ""
  echo "## Sign-Off"
  echo ""
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| Reviewer | $reviewer_name |"
  echo "| Date | $review_date |"
  echo "| Status | $signoff_status |"
  echo ""
  echo "> **Next Step:** Share \`REQUIREMENTS-FINAL.md\` with the development team."
  echo "> Resolve all ❌ items and 🔴 blocking debts before sprint planning."
  echo ""
} > "$VALIDATION_FILE"

# ── Compile final document ────────────────────────────────────────────────────
printf '%b%b── Compiling Final Requirements Document ──%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
echo ""
project_name="My Project"
if [ -f "$BA_OUTPUT_DIR/01-project-intake.md" ]; then
  extracted=$(grep '| \*\*Project Name\*\* |' "$BA_OUTPUT_DIR/01-project-intake.md" 2>/dev/null | head -1 | sed 's/| \*\*Project Name\*\* | \(.*\) |/\1/')
  [ -n "$extracted" ] && project_name="$extracted"
fi

{
  echo "# Requirements Document"
  echo ""
  echo "> Project: $project_name"
  echo "> Compiled: $(date '+%Y-%m-%d %H:%M')"
  echo "> Status: $signoff_status"
  echo ""
  echo "---"
  echo ""
  for section in \
    "01-project-intake.md" \
    "02-stakeholders.md" \
    "03-requirements.md" \
    "04-user-stories.md" \
    "05-nfr.md" \
    "06-requirement-debts.md" \
    "07-validation-report.md"; do
    local_path="$BA_OUTPUT_DIR/$section"
    if [ -f "$local_path" ]; then
      cat "$local_path"
      echo ""
      echo "---"
      echo ""
    fi
  done
} > "$FINAL_FILE"

ba_success_rule "🎉 BA Session Complete!"
printf '  %bKey files generated:%b\n' "$BA_BOLD" "$BA_NC"
printf '  %b📄 %s%b\n' "$BA_CYAN" "$FINAL_FILE" "$BA_NC"
printf '  %b📋 %s%b\n' "$BA_CYAN" "$VALIDATION_FILE" "$BA_NC"
printf '  %b📁 %s/%b\n' "$BA_CYAN" "$BA_OUTPUT_DIR" "$BA_NC"
echo ""
printf '  %bRecommended next steps:%b\n' "$BA_BOLD" "$BA_NC"
printf '  1. Share %bREQUIREMENTS-FINAL.md%b with your development team\n' "$BA_BOLD" "$BA_NC"
printf '  2. Resolve all %b🔴 Blocking%b debts before the first sprint\n' "$BA_RED" "$BA_NC"
echo "  3. Book a requirements review meeting with stakeholders"
echo "  4. Import user stories into your project management tool (Jira, Linear, etc.)"
echo ""
