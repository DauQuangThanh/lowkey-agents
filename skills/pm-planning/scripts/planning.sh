#!/bin/bash
# =============================================================================
# planning.sh — Phase 1: Project Planning
# Captures: project name, methodology, WBS, milestones, dependencies,
# resource allocation, communication cadence, and definition of done.
# Output: pm-output/01-project-plan.md
# =============================================================================

set -u  # error on undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
pm_parse_flags "$@"


# ── Try to load project context from ba-output if it exists ──────────────────
BA_INTAKE_FILE="$(cd "$SCRIPT_DIR/../.." && pwd)/../ba-output/01-project-intake.md"
PROJECT_NAME=""
METHODOLOGY=""

if [ -f "$BA_INTAKE_FILE" ]; then
  pm_dim "Found Business Analyst context at $BA_INTAKE_FILE"
  # Try to extract project name and methodology (simple grep)
  PROJECT_NAME=$(grep -E '^# Project:' "$BA_INTAKE_FILE" | head -1 | sed 's/^# Project: //' || printf '')
  METHODOLOGY=$(grep -E '^\*\*Methodology:\*\*' "$BA_INTAKE_FILE" | head -1 | sed 's/.*\*\*Methodology:\*\* //' || printf '')
fi

pm_banner "Phase 1: Project Planning"

# ── Question 1: Project Name ──────────────────────────────────────────────────
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME=$(pm_ask "What is the project name?")
fi
pm_dim "Project: $PROJECT_NAME"

# ── Question 2: Methodology ───────────────────────────────────────────────────
if [ -z "$METHODOLOGY" ]; then
  METHODOLOGY=$(pm_ask_choice \
    "Which development methodology will you use?" \
    "Agile/Scrum" \
    "Kanban" \
    "Waterfall" \
    "Hybrid" \
    "Not decided yet")
fi
pm_dim "Methodology: $METHODOLOGY"

# ── Question 3: WBS Items ─────────────────────────────────────────────────────
printf '\n%b▶ Define the top-level work items in your project.%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (Examples: Planning, Design, Development, Testing, Deployment)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   Enter each item on a new line. When done, type an empty line.%b\n' "$PM_DIM" "$PM_NC"

WBS_ITEMS=""
while true; do
  item=$(pm_ask "Add WBS item (or press Enter to finish)")
  [ -z "$item" ] && break
  if [ -z "$WBS_ITEMS" ]; then
    WBS_ITEMS="$item"
  else
    WBS_ITEMS="$WBS_ITEMS"$'\n'"$item"
  fi
  pm_dim "Added: $item"
done

if [ -z "$WBS_ITEMS" ]; then
  pm_dim "No WBS items defined — logging as debt."
  pm_add_debt "Planning" "WBS not defined" "No top-level work items provided" "Cannot plan timeline or resource allocation"
  WBS_ITEMS="(TBD)"
fi

# ── Question 4: Milestones ────────────────────────────────────────────────────
printf '\n%b▶ Define key milestones with target dates.%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (Format: Milestone Name | DD/MM/YYYY | Acceptance Criteria | Owner)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   When done, type an empty line.%b\n' "$PM_DIM" "$PM_NC"

MILESTONES=""
while true; do
  milestone=$(pm_ask "Add milestone (or press Enter to finish)")
  [ -z "$milestone" ] && break
  if [ -z "$MILESTONES" ]; then
    MILESTONES="$milestone"
  else
    MILESTONES="$MILESTONES"$'\n'"$milestone"
  fi
  pm_dim "Added: $milestone"
done

if [ -z "$MILESTONES" ]; then
  pm_dim "No milestones defined — logging as debt."
  pm_add_debt "Planning" "Milestones not defined" "No key milestones or target dates provided" "Cannot track progress or manage expectations"
  MILESTONES="(TBD)"
fi

# ── Question 5: Resource Allocation ───────────────────────────────────────────
RESOURCE_APPROACH=$(pm_ask_choice \
  "How should resources be allocated?" \
  "Dedicated team (full-time)" \
  "Shared resources (split across projects)" \
  "Mixed (some dedicated, some shared)" \
  "Not decided yet")
pm_dim "Resource approach: $RESOURCE_APPROACH"

# ── Question 6: Dependencies & Critical Path ──────────────────────────────────
printf '\n%b▶ Identify critical path items and dependencies.%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (Example: Design must complete before Development starts)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   When done, type an empty line.%b\n' "$PM_DIM" "$PM_NC"

DEPENDENCIES=""
while true; do
  dep=$(pm_ask "Add dependency (or press Enter to finish)")
  [ -z "$dep" ] && break
  if [ -z "$DEPENDENCIES" ]; then
    DEPENDENCIES="$dep"
  else
    DEPENDENCIES="$DEPENDENCIES"$'\n'"$dep"
  fi
  pm_dim "Added: $dep"
done

if [ -z "$DEPENDENCIES" ]; then
  pm_dim "No explicit dependencies defined — will assess during planning."
fi

# ── Question 7: Communication Cadence ─────────────────────────────────────────
COMMUNICATION=$(pm_ask_choice \
  "What is your communication plan cadence?" \
  "Daily standup" \
  "Weekly meetings" \
  "Bi-weekly" \
  "Monthly" \
  "As-needed")
pm_dim "Communication: $COMMUNICATION"

# ── Question 8: Definition of Done ────────────────────────────────────────────
printf '\n%b▶ Define what "done" means for this project.%b\n' "$PM_YELLOW" "$PM_NC"
printf '%b   (Examples: All tests pass, Security review complete, Users trained, etc.)%b\n' "$PM_DIM" "$PM_NC"
printf '%b   When done, type an empty line.%b\n' "$PM_DIM" "$PM_NC"

DOD=""
while true; do
  criterion=$(pm_ask "Add Definition of Done criterion (or press Enter to finish)")
  [ -z "$criterion" ] && break
  if [ -z "$DOD" ]; then
    DOD="$criterion"
  else
    DOD="$DOD"$'\n'"$criterion"
  fi
  pm_dim "Added: $criterion"
done

if [ -z "$DOD" ]; then
  pm_dim "Definition of Done not provided — logging as debt."
  pm_add_debt "Planning" "Definition of Done unclear" "No explicit DoD provided" "Cannot determine when deliverables are complete"
  DOD="(TBD)"
fi

# ── Confirmation ──────────────────────────────────────────────────────────────
printf '\n'
pm_ask_yn "Save this plan?"
if [ $? -ne 0 ]; then
  pm_dim "Plan discarded. Exiting."
  exit 0
fi

# ── Write Output ──────────────────────────────────────────────────────────────
OUTPUT_FILE="$PM_OUTPUT_DIR/01-project-plan.md"

{
  printf '# Project Plan: %s\n\n' "$PROJECT_NAME"
  printf '**Date:** %s\n' "$(date '+%d/%m/%Y')"
  printf '**Methodology:** %s\n' "$METHODOLOGY"
  printf '**Output Directory:** %s\n\n' "$PM_OUTPUT_DIR"

  printf '## Scope Statement\n'
  printf '[One paragraph describing what is being delivered and why — to be completed by project stakeholders]\n\n'

  printf '## Work Breakdown Structure (WBS)\n'
  printf '### Top-Level Items\n'
  printf '%s\n\n' "$WBS_ITEMS" | sed 's/^/- /'

  printf '## Milestones & Schedule\n'
  printf '| Milestone | Target Date | Acceptance Criteria | Owner |\n'
  printf '|---|---|---|---|\n'
  if [ "$MILESTONES" != "(TBD)" ]; then
    printf '%s\n' "$MILESTONES" | while IFS= read -r line; do
      printf '| %s | TBD | TBD | TBD |\n' "$line"
    done
  else
    printf '| (TBD) | | | |\n'
  fi
  printf '\n'

  printf '## Dependencies & Critical Path\n'
  if [ -n "$DEPENDENCIES" ]; then
    printf '%s\n' "$DEPENDENCIES" | sed 's/^/- /'
  else
    printf -- '- (None identified yet)\n'
  fi
  printf '\n'

  printf '## Resource Allocation\n'
  printf '**Approach:** %s\n\n' "$RESOURCE_APPROACH"
  printf '| Role | Name | FTE | Notes |\n'
  printf '|---|---|---|---|\n'
  printf '| Developer | TBD | TBD | TBD |\n'
  printf '| QA / Tester | TBD | TBD | TBD |\n'
  printf '| Product Owner | TBD | TBD | TBD |\n'
  printf '| Project Manager | TBD | TBD | TBD |\n\n'

  printf '## Communication Plan\n'
  printf '**Cadence:** %s\n' "$COMMUNICATION"
  printf -- '- Standup/Status meetings: [To be scheduled]\n'
  printf -- '- Status reports: [To be scheduled]\n'
  printf -- '- Steering committee: [To be scheduled]\n\n'

  printf '## Definition of Done (Project Level)\n'
  if [ "$DOD" != "(TBD)" ]; then
    printf '%s\n' "$DOD" | sed 's/^/- [ ] /'
  else
    printf -- '- [ ] (TBD)\n'
  fi
  printf '\n'

  printf '## Next Steps\n'
  printf '1. Flesh out scope statement\n'
  printf '2. Identify and assign resource owners\n'
  printf '3. Add target dates and acceptance criteria to milestones\n'
  printf '4. Refine WBS to Level 2 and 3\n'
  printf '5. Create detailed schedule (Gantt chart or sprint plan)\n'
} > "$OUTPUT_FILE"

pm_success_rule "Project plan written to $OUTPUT_FILE"
printf '\n'

# ── Final Summary ─────────────────────────────────────────────────────────────
pm_dim "Summary:"
pm_dim "  Project: $PROJECT_NAME"
pm_dim "  Methodology: $METHODOLOGY"
pm_dim "  WBS Items: $(printf '%s' "$WBS_ITEMS" | wc -l | tr -d ' ') items"
pm_dim "  Milestones: $(if [ "$MILESTONES" = "(TBD)" ]; then printf 'TBD'; else printf '%s' "$MILESTONES" | wc -l | tr -d ' '; fi) defined"
pm_dim "  Resource Approach: $RESOURCE_APPROACH"
pm_dim "  Communication: $COMMUNICATION"

DEBT_COUNT=$(pm_current_debt_count)
if [ "$DEBT_COUNT" -gt 0 ]; then
  printf '\n%b⚠ %d open PM debt(s) to resolve — see %s%b\n' \
    "$PM_YELLOW" "$DEBT_COUNT" "$PM_DEBT_FILE" "$PM_NC"
fi

printf '\n%b✓ Phase 1 complete.%b\n\n' "$PM_GREEN" "$PM_NC"
