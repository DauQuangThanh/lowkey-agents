#!/bin/bash
# =============================================================================
# run-all.sh — Scrum Master Workflow Orchestrator
# Runs all 5 phases and compiles a consolidated SM-FINAL.md report.
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Step 1: parse --auto / --answers flags
sm_parse_flags "$@"


# ── Banner ────────────────────────────────────────────────────────────────────
sm_banner "🚀  Scrum Master Workflow (Full Sprint Cycle)"
sm_dim "  Running all 5 phases: Planning → Standups → Retro → Impediments → Health"
sm_dim "  Each phase will save its output file. At the end, I'll compile a final report."
echo ""

# ── Run all phases ────────────────────────────────────────────────────────────

echo ""
sm_dim "Starting Phase 1: Sprint Planning..."
bash "$SCRIPT_DIR/../../sm-sprint-planning/scripts/sprint-planning.sh"
echo ""

sm_dim "Starting Phase 2: Daily Standup..."
bash "$SCRIPT_DIR/../../sm-standup/scripts/standup.sh"
echo ""

sm_dim "Starting Phase 3: Sprint Retrospective..."
bash "$SCRIPT_DIR/../../sm-retrospective/scripts/retro.sh"
echo ""

sm_dim "Starting Phase 4: Impediment Tracker..."
bash "$SCRIPT_DIR/../../sm-impediments/scripts/impediments.sh"
echo ""

sm_dim "Starting Phase 5: Team Health & Velocity..."
bash "$SCRIPT_DIR/../../sm-team-health/scripts/team-health.sh"
echo ""

# ── Compile final report ──────────────────────────────────────────────────────

FINAL_OUTPUT="$SM_OUTPUT_DIR/SM-FINAL.md"

{
  echo "# Scrum Master Summary Report"
  echo ""
  echo "> **Compiled:** $(date '+%Y-%m-%d %H:%M')"
  echo ""
  echo "---"
  echo ""
  echo "## Sprint Cycle Overview"
  echo ""
  echo "This report compiles all five Scrum Master phases for a complete sprint cycle:"
  echo ""
  echo "1. **Sprint Planning** — Goals, capacity, story commitment"
  echo "2. **Daily Standups** — Team updates and impediments"
  echo "3. **Sprint Retrospective** — Start/Stop/Continue and improvement actions"
  echo "4. **Impediment Tracking** — Blockers and escalations"
  echo "5. **Team Health** — Velocity, morale, and coaching needs"
  echo ""
  echo "---"
  echo ""
  echo "## Phase Outputs"
  echo ""
  echo "### Phase 1: Sprint Plan"
  echo ""
  if [ -f "$SM_OUTPUT_DIR/01-sprint-plan.md" ]; then
    echo "✅ Generated: \`01-sprint-plan.md\`"
    echo ""
    head -20 "$SM_OUTPUT_DIR/01-sprint-plan.md" | tail -n +3 | sed 's/^/  /'
    echo ""
  else
    echo "⚠️  Sprint plan not found"
  fi
  echo ""
  echo "### Phase 2: Standup Log"
  echo ""
  if [ -f "$SM_OUTPUT_DIR/02-standup-log.md" ]; then
    echo "✅ Generated: \`02-standup-log.md\`"
    echo ""
    grep -A 5 "## Impediments Summary" "$SM_OUTPUT_DIR/02-standup-log.md" | head -8 | sed 's/^/  /'
    echo ""
  else
    echo "⚠️  Standup log not found"
  fi
  echo ""
  echo "### Phase 3: Retrospective"
  echo ""
  if [ -f "$SM_OUTPUT_DIR/03-retrospective.md" ]; then
    echo "✅ Generated: \`03-retrospective.md\`"
    echo ""
    grep -A 3 "## Start / Stop / Continue" "$SM_OUTPUT_DIR/03-retrospective.md" | head -6 | sed 's/^/  /'
    echo ""
  else
    echo "⚠️  Retrospective not found"
  fi
  echo ""
  echo "### Phase 4: Impediment Log"
  echo ""
  if [ -f "$SM_OUTPUT_DIR/04-impediment-log.md" ]; then
    echo "✅ Generated: \`04-impediment-log.md\`"
    echo ""
    grep "^##" "$SM_OUTPUT_DIR/04-impediment-log.md" | head -3 | sed 's/^/  /'
    echo ""
  else
    echo "⚠️  Impediment log not found"
  fi
  echo ""
  echo "### Phase 5: Team Health"
  echo ""
  if [ -f "$SM_OUTPUT_DIR/05-team-health.md" ]; then
    echo "✅ Generated: \`05-team-health.md\`"
    echo ""
    grep -A 4 "## Team Health Metrics" "$SM_OUTPUT_DIR/05-team-health.md" | head -7 | sed 's/^/  /'
    echo ""
  else
    echo "⚠️  Team health report not found"
  fi
  echo ""
  echo "---"
  echo ""
  echo "## Scrum Master Debts"
  echo ""
  if [ -f "$SM_DEBT_FILE" ]; then
    DEBT_COUNT=$(grep -c '^## SMDEBT-' "$SM_DEBT_FILE" 2>/dev/null || echo 0)
    echo "**Total Debts:** $DEBT_COUNT"
    echo ""
    echo "See \`06-sm-debts.md\` for complete tracking."
  else
    echo "No debts recorded."
  fi
  echo ""
  echo "---"
  echo ""
  echo "## Next Steps"
  echo ""
  echo "1. Review individual phase files for detailed information"
  echo "2. Address any SMDEBT items before the next sprint"
  echo "3. Follow up on action items from retrospective"
  echo "4. Share key metrics with stakeholders"
  echo ""
} > "$FINAL_OUTPUT"

sm_success_rule "✅ Scrum Master Workflow Complete!"
sm_dim "All phases completed and final report compiled."
sm_dim ""
sm_dim "Output files:"
sm_dim "  - 01-sprint-plan.md (sprint goals and commitment)"
sm_dim "  - 02-standup-log.md (team updates and blockers)"
sm_dim "  - 03-retrospective.md (retrospective and improvements)"
sm_dim "  - 04-impediment-log.md (blockers and escalations)"
sm_dim "  - 05-team-health.md (velocity and morale)"
sm_dim "  - 06-sm-debts.md (outstanding debts)"
sm_dim "  - SM-FINAL.md (consolidated report)"
echo ""
