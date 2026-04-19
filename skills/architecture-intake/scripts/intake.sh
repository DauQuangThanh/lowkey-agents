#!/bin/bash
# =============================================================================
# intake.sh — Phase 1: Architecture Intake
# Captures the drivers that shape every architectural decision.
# Output: $ARCH_OUTPUT_DIR/01-architecture-intake.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
arch_parse_flags "$@"


OUTPUT_FILE="$ARCH_OUTPUT_DIR/01-architecture-intake.md"
AREA="Architecture Intake"

start_tdebts=$(arch_current_tdebt_count)

# ── Header ────────────────────────────────────────────────────────────────────
arch_banner "🏛   Step 1 of 6 — Architecture Intake"
arch_dim "  Let's lock down the drivers that will shape every architecture decision."
arch_dim "  Most answers are numbered choices or y/n. Skip with Enter if unsure."
echo ""

# ── Handover from BA ─────────────────────────────────────────────────────────
BA_FINAL="$ARCH_BA_INPUT_DIR/REQUIREMENTS-FINAL.md"
if [ -f "$BA_FINAL" ]; then
  printf '%b  ✔ Found BA output: %s%b\n' "$ARCH_GREEN" "$BA_FINAL" "$ARCH_NC"
  arch_dim "  The architect agent can read this for problem statement, NFRs, and open debts."
else
  printf '%b  ⚠ No BA output found at: %s%b\n' "$ARCH_YELLOW" "$BA_FINAL" "$ARCH_NC"
  arch_dim "  For best results, run the business-analyst first. Continuing anyway..."
  arch_add_tdebt "$AREA" "No BA requirements input found" \
    "ba-output/REQUIREMENTS-FINAL.md was not present at intake time" \
    "Architecture decisions may lack traceability to requirements/NFRs"
fi
echo ""

# ── Q1: Top quality attribute ────────────────────────────────────────────────
printf '%b%bQuestion 1 / 6 — Most important quality attribute%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"
arch_dim "  Which one matters MOST for this system? (you can add more later)"
echo ""
TOP_QA=$(arch_ask_choice "Select one:" \
  "Performance — speed matters most (low latency, high throughput)" \
  "Security — sensitive data, compliance, privacy-first" \
  "Scalability — rapid growth expected, handle large spikes" \
  "Availability — 24/7 uptime, high-stakes downtime cost" \
  "Maintainability — small team, long-lived codebase" \
  "Cost — strict budget, cost-sensitive" \
  "Time-to-market — ship fast, refactor later" \
  "Not sure yet")
if [ "$TOP_QA" = "Not sure yet" ]; then
  arch_add_tdebt "$AREA" "Primary quality attribute not ranked" \
    "Top quality-attribute driver has not been decided" \
    "ADR trade-offs cannot be judged without a priority ordering"
fi

# ── Q2: Hard constraints ─────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 2 / 6 — Hard constraints%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"
arch_dim "  Are there fixed rules the architecture MUST follow?"
arch_dim "  Examples: 'must run on-prem', 'no GPL libraries', 'must be GDPR-compliant', 'only AWS approved'."
arch_dim "  List all that apply, separated by semicolons. Press Enter if none."
echo ""
CONSTRAINTS=$(arch_ask "Your answer:")
if [ -z "$CONSTRAINTS" ]; then
  CONSTRAINTS="None declared"
  arch_add_tdebt "$AREA" "Hard constraints not declared" \
    "No cloud/licence/residency/compliance constraints captured" \
    "Technology shortlist may include non-viable options"
fi

# ── Q3: Team context ─────────────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 3 / 6 — Team context%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"
echo ""
TEAM_SIZE=$(arch_ask_choice "How large is the engineering team that will build AND run this?" \
  "Solo — 1 engineer" \
  "Small — 2 to 5 engineers" \
  "Medium — 6 to 15 engineers" \
  "Large — more than 15 engineers")

TEAM_SKILLS=$(arch_ask "What is the team's strongest existing tech stack? (e.g. 'Python + PostgreSQL', '.NET + SQL Server', 'Node.js + React')")
if [ -z "$TEAM_SKILLS" ]; then
  TEAM_SKILLS="Unknown"
  arch_add_tdebt "$AREA" "Team skill set not captured" \
    "Team's strongest stack is unknown" \
    "Risk of choosing a stack the team cannot operate"
fi

# ── Q4: Operational envelope ─────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 4 / 6 — Operational envelope%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"
echo ""
USER_LOAD=$(arch_ask_choice "Expected user load in year 1?" \
  "Tiny — up to 100 users / 1 req/s" \
  "Small — up to 1,000 users / 10 req/s" \
  "Medium — up to 10,000 users / 100 req/s" \
  "Large — up to 100,000 users / 1,000 req/s" \
  "Very Large — 100,000+ users / 10,000+ req/s" \
  "Unknown")
if [ "$USER_LOAD" = "Unknown" ]; then
  arch_add_tdebt "$AREA" "User load not estimated" \
    "Year-1 load is unknown" \
    "Capacity, sizing, and cost estimates are unreliable"
fi

DATA_VOLUME=$(arch_ask_choice "Expected data volume by end of year 1?" \
  "Small — under 10 GB" \
  "Medium — 10 GB to 1 TB" \
  "Large — 1 TB to 100 TB" \
  "Very Large — over 100 TB" \
  "Unknown")
if [ "$DATA_VOLUME" = "Unknown" ]; then
  arch_add_tdebt "$AREA" "Data volume not estimated" \
    "Year-1 data size is unknown" \
    "Storage tier and database choice cannot be finalised"
fi

SLA=$(arch_ask_choice "What SLA (uptime) is required?" \
  "Best-effort — no SLA (internal tool)" \
  "Standard — 99.0% (about 7h downtime / month)" \
  "High — 99.5% (about 3.5h / month)" \
  "Very High — 99.9% (about 45 min / month)" \
  "Extreme — 99.99% (about 4 min / month)" \
  "Unknown")
if [ "$SLA" = "Unknown" ]; then
  arch_add_tdebt "$AREA" "SLA target not defined" \
    "Uptime target is unknown" \
    "Redundancy, multi-region, and failover decisions cannot be made"
fi

RTO_RPO=$(arch_ask "RTO (max recovery time after failure) and RPO (max acceptable data loss)? e.g. 'RTO 1h / RPO 15min' — Enter to skip")
if [ -z "$RTO_RPO" ]; then
  RTO_RPO="TBD"
  arch_add_tdebt "$AREA" "RTO/RPO not defined" \
    "Disaster recovery targets are unknown" \
    "Backup strategy and DR topology cannot be designed"
fi

# ── Q5: Integration surface ──────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 5 / 6 — Integration surface%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"
arch_dim "  Which external systems must this talk to? (comma-separated list — Enter if none)"
arch_dim "  Examples: 'Azure AD, Stripe, SAP, Twilio, BigQuery'"
echo ""
INTEGRATIONS=$(arch_ask "Your answer:")
[ -z "$INTEGRATIONS" ] && INTEGRATIONS="None"

# ── Q6: Deployment preference ────────────────────────────────────────────────
echo ""
printf '%b%bQuestion 6 / 6 — Deployment preference%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$ARCH_NC"
echo ""
DEPLOYMENT=$(arch_ask_choice "Where should this system run?" \
  "AWS" \
  "Azure" \
  "Google Cloud" \
  "Multi-cloud" \
  "On-prem / self-hosted" \
  "Hybrid (cloud + on-prem)" \
  "No strong preference")
if [ "$DEPLOYMENT" = "No strong preference" ]; then
  arch_add_tdebt "$AREA" "Deployment target undecided" \
    "Cloud/on-prem choice is open" \
    "Hosting, networking, and managed-service ADRs cannot be finalised"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
arch_success_rule "✅ Architecture Intake Summary"
printf '  %bTop QA driver:%b        %s\n' "$ARCH_BOLD" "$ARCH_NC" "$TOP_QA"
printf '  %bConstraints:%b          %s\n' "$ARCH_BOLD" "$ARCH_NC" "$CONSTRAINTS"
printf '  %bTeam:%b                 %s — strongest stack: %s\n' "$ARCH_BOLD" "$ARCH_NC" "$TEAM_SIZE" "$TEAM_SKILLS"
printf '  %bUser load:%b            %s\n' "$ARCH_BOLD" "$ARCH_NC" "$USER_LOAD"
printf '  %bData volume:%b          %s\n' "$ARCH_BOLD" "$ARCH_NC" "$DATA_VOLUME"
printf '  %bSLA:%b                  %s\n' "$ARCH_BOLD" "$ARCH_NC" "$SLA"
printf '  %bRTO / RPO:%b            %s\n' "$ARCH_BOLD" "$ARCH_NC" "$RTO_RPO"
printf '  %bIntegrations:%b         %s\n' "$ARCH_BOLD" "$ARCH_NC" "$INTEGRATIONS"
printf '  %bDeployment:%b           %s\n' "$ARCH_BOLD" "$ARCH_NC" "$DEPLOYMENT"
echo ""

if ! arch_confirm_save "Does this look correct? (y=save / n=redo)"; then
  arch_dim "  Restarting step 1..."
  exec bash "$0"
fi

# ── Write output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Architecture Intake"
  echo ""
  echo "> Captured: $DATE_NOW"
  if [ -f "$BA_FINAL" ]; then
    echo "> Requirements basis: \`$BA_FINAL\`"
  else
    echo "> Requirements basis: **NOT PROVIDED** — see TDEBTs"
  fi
  echo ""
  echo "## 1. Quality Attribute Drivers"
  echo ""
  echo "- **Top driver:** $TOP_QA"
  echo ""
  echo "## 2. Hard Constraints"
  echo ""
  echo "$CONSTRAINTS"
  echo ""
  echo "## 3. Team Context"
  echo ""
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| Team size | $TEAM_SIZE |"
  echo "| Strongest stack | $TEAM_SKILLS |"
  echo ""
  echo "## 4. Operational Envelope"
  echo ""
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| Expected user load (Y1) | $USER_LOAD |"
  echo "| Expected data volume (Y1) | $DATA_VOLUME |"
  echo "| SLA target | $SLA |"
  echo "| RTO / RPO | $RTO_RPO |"
  echo ""
  echo "## 5. Integration Surface"
  echo ""
  echo "$INTEGRATIONS"
  echo ""
  echo "## 6. Deployment Preference"
  echo ""
  echo "$DEPLOYMENT"
  echo ""
} > "$OUTPUT_FILE"

end_tdebts=$(arch_current_tdebt_count)
new_tdebts=$((end_tdebts - start_tdebts))

printf '%b  Saved to: %s%b\n' "$ARCH_GREEN" "$OUTPUT_FILE" "$ARCH_NC"
if [ "$new_tdebts" -gt 0 ]; then
  printf '%b  ⚠  %d technical debt(s) logged to: %s%b\n' "$ARCH_YELLOW" "$new_tdebts" "$ARCH_TDEBT_FILE" "$ARCH_NC"
fi
echo ""
