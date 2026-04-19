#!/bin/bash
# =============================================================================
# build-stories.sh — Phase 4: User Story Builder
# Interactive guided user story creation with acceptance criteria.
# Output: $BA_OUTPUT_DIR/04-user-stories.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
ba_parse_flags "$@"


OUTPUT_FILE="$BA_OUTPUT_DIR/04-user-stories.md"
AREA="User Stories"

start_debts=$(ba_current_debt_count)

STORY_COUNT=0
STORIES=()
STORY_IDS=()
STORY_ACTIONS=()
STORY_PRIORITIES=()
STORY_COMPLEXITIES=()
STORY_ROLES=()

build_story() {
  STORY_COUNT=$((STORY_COUNT + 1))
  local story_id
  story_id=$(printf "US-%03d" "$STORY_COUNT")
  echo ""
  printf '%b%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
  printf '%b%b  Story %s%b\n' "$BA_CYAN" "$BA_BOLD" "$story_id" "$BA_NC"
  printf '%b%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$BA_CYAN" "$BA_BOLD" "$BA_NC"
  echo ""
  ba_dim "  A user story follows this pattern:"
  ba_dim "  \"As a [WHO], I want to [WHAT], so that [WHY].\""
  echo ""

  # WHO
  printf '%b  Part 1 — WHO is performing this action?%b\n' "$BA_CYAN" "$BA_NC"
  ba_dim "  Example: 'registered user', 'admin', 'warehouse manager', 'customer'"
  local role
  role=$(ba_ask "  As a...")
  if [ -z "$role" ]; then
    role="user"
    ba_add_debt "$AREA" "User role missing in story $story_id" \
      "The user type for story $story_id was not specified" \
      "Story cannot be properly prioritised without knowing the user"
  fi

  # WHAT
  echo ""
  printf '%b  Part 2 — WHAT do they want to do?%b\n' "$BA_CYAN" "$BA_NC"
  ba_dim "  Example: 'view all my pending orders', 'reset my password'"
  local action
  action=$(ba_ask "  I want to...")
  if [ -z "$action" ]; then
    action="[action not specified]"
    ba_add_debt "$AREA" "Action missing in story $story_id" \
      "The action/feature for story $story_id was not specified" \
      "Story cannot be developed without knowing what to build"
  fi

  # WHY
  echo ""
  printf '%b  Part 3 — WHY do they want it? What benefit does it give them?%b\n' "$BA_CYAN" "$BA_NC"
  ba_dim "  Example: 'so I can track delivery status', 'so I can regain access quickly'"
  local benefit
  benefit=$(ba_ask "  So that...")
  if [ -z "$benefit" ]; then
    benefit="[benefit not specified]"
    ba_add_debt "$AREA" "Benefit missing in story $story_id" \
      "The business value for story $story_id was not specified" \
      "Without knowing the 'why', acceptance criteria are hard to define"
  fi

  # PRIORITY
  echo ""
  printf '%b  Part 4 — Priority (MoSCoW method)%b\n' "$BA_CYAN" "$BA_NC"
  ba_dim "  Must = core feature, Should = important, Could = nice to have, Won't = out of scope"
  echo ""
  local priority
  priority=$(ba_ask_choice "  Priority level:" \
    "Must Have — Cannot launch without this" \
    "Should Have — Important but not blocking launch" \
    "Could Have — Nice to have if time allows" \
    "Won't Have (this release) — Out of scope for now")

  # COMPLEXITY
  echo ""
  printf '%b  Part 5 — Complexity estimate%b\n' "$BA_CYAN" "$BA_NC"
  echo ""
  local complexity
  complexity=$(ba_ask_choice "  How complex does this feel?" \
    "Small — A few hours of work" \
    "Medium — A few days of work" \
    "Large — A week or more of work" \
    "Unknown — I'm not sure")

  # ACCEPTANCE CRITERIA
  echo ""
  printf '%b  Part 6 — Acceptance Criteria%b\n' "$BA_CYAN" "$BA_NC"
  ba_dim "  These are the conditions that must be true for this story to be 'done'."
  ba_dim "  Example: 'User can see a list of their last 10 orders sorted by date'"
  echo ""

  local criteria_list=""
  local ac_count=0
  ba_dim "  Add at least 2 acceptance criteria (press Enter with no text to stop):"
  while : ; do
    ac_count=$((ac_count + 1))
    printf '%b  Criterion %d (or press Enter to finish): %b\n' "$BA_YELLOW" "$ac_count" "$BA_NC"
    IFS= read -r criterion
    [ -z "$criterion" ] && break
    criteria_list="${criteria_list}- [ ] ${criterion}"$'\n'
  done

  if [ -z "$criteria_list" ]; then
    criteria_list="- [ ] [Acceptance criteria not yet defined]"$'\n'
    ba_add_debt "$AREA" "No acceptance criteria for $story_id" \
      "Story '$story_id' has no acceptance criteria" \
      "Cannot determine when this story is done; blocks testing and sign-off"
  fi

  # NOTES
  echo ""
  ba_dim "  Any assumptions, dependencies, or notes? (Press Enter to skip)"
  local notes
  notes=$(ba_ask "  Notes:")
  [ -z "$notes" ] && notes="None"

  # Build story block
  local story_block
  story_block="## $story_id: $action
**As a** $role,
**I want to** $action,
**so that** $benefit.

### Acceptance Criteria
$criteria_list

**Priority:** $priority
**Complexity:** $complexity
**Notes:** $notes
"

  STORIES+=("$story_block")
  STORY_IDS+=("$story_id")
  STORY_ROLES+=("$role")
  STORY_ACTIONS+=("$action")
  STORY_PRIORITIES+=("$priority")
  STORY_COMPLEXITIES+=("$complexity")

  echo ""
  printf '%b  ✅ Story %s saved!%b\n' "$BA_GREEN" "$story_id" "$BA_NC"
  printf '%b     "As a %s, I want to %s"%b\n' "$BA_GREEN" "$role" "$action" "$BA_NC"
}

# ── Header ────────────────────────────────────────────────────────────────────
ba_banner "📖  Step 4 of 7 — User Story Builder"
ba_dim "  A user story describes a feature from the perspective of the person using it."
ba_dim "  We'll build them one at a time. You can add as many as you like."
echo ""

if [ -f "$BA_OUTPUT_DIR/03-requirements.md" ]; then
  ba_dim "  Tip: I found your requirements from Step 3. You can use them as a guide."
  echo ""
fi

# ── Story loop ────────────────────────────────────────────────────────────────
build_story
while : ; do
  echo ""
  add_more=$(ba_ask_yn "Would you like to add another user story?")
  [ "$add_more" = "no" ] && break
  build_story
done

# ── Summary ───────────────────────────────────────────────────────────────────
ba_success_rule "✅ User Story Summary ($STORY_COUNT stories created)"

if ! ba_confirm_save "Save all stories? (y=save / n=redo)"; then
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# User Stories"
  echo ""
  echo "> Captured: $DATE_NOW | Total: $STORY_COUNT stories"
  echo ""
  echo "## Quick Reference"
  echo ""
  echo "| ID | As a... | I want to... | Priority | Complexity |"
  echo "|---|---|---|---|---|"
  i=0
  while [ "$i" -lt "${#STORY_IDS[@]}" ]; do
    echo "| ${STORY_IDS[$i]} | ${STORY_ROLES[$i]} | ${STORY_ACTIONS[$i]} | ${STORY_PRIORITIES[$i]} | ${STORY_COMPLEXITIES[$i]} |"
    i=$((i + 1))
  done
  echo ""
  echo "---"
  echo ""
  for s in "${STORIES[@]}"; do
    echo "$s"
    echo ""
    echo "---"
    echo ""
  done
} > "$OUTPUT_FILE"

end_debts=$(ba_current_debt_count)
new_debts=$((end_debts - start_debts))

printf '%b  Saved to: %s%b\n' "$BA_GREEN" "$OUTPUT_FILE" "$BA_NC"
if [ "$new_debts" -gt 0 ]; then
  printf '%b  ⚠  %d debt(s) logged.%b\n' "$BA_YELLOW" "$new_debts" "$BA_NC"
fi
echo ""
