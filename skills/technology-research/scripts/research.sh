#!/bin/bash
# =============================================================================
# research.sh — Phase 2: Technology Research
# For each in-scope decision area, capture 2–4 candidate technologies with
# maturity, licence, hosting, cost signal, pros/cons, and fit.
# Output: $ARCH_OUTPUT_DIR/02-technology-research.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
arch_parse_flags "$@"


OUTPUT_FILE="$ARCH_OUTPUT_DIR/02-technology-research.md"
AREA="Technology Research"

start_tdebts=$(arch_current_tdebt_count)

# ── Header ────────────────────────────────────────────────────────────────────
arch_banner "🔍  Step 2 of 6 — Technology Research"
arch_dim "  For each decision area in scope, we'll capture 2–3 candidate technologies"
arch_dim "  with their trade-offs. The agent should pair this with WebSearch/WebFetch"
arch_dim "  to verify facts — never cite a version or price you haven't confirmed."
echo ""

# ── Init output ──────────────────────────────────────────────────────────────
DATE_NOW=$(date '+%Y-%m-%d')
{
  echo "# Technology Research"
  echo ""
  echo "> Captured: $DATE_NOW"
  echo ""
  echo "Candidate technologies per architectural decision area. Each candidate is rated for"
  echo "fit against the constraints captured in \`01-architecture-intake.md\`."
  echo ""
  echo "| Field | Meaning |"
  echo "|---|---|"
  echo "| Maturity | Emerging / Established / Declining |"
  echo "| Licence | MIT / Apache / Commercial / Mixed / Other |"
  echo "| Hosting | Self-host / Managed / Both |"
  echo "| Cost | \$ low / \$\$ medium / \$\$\$ high |"
  echo "| Fit | High / Medium / Low (against our constraints) |"
  echo ""
  echo "---"
  echo ""
} > "$OUTPUT_FILE"

# ── Per-candidate capture helper ─────────────────────────────────────────────
capture_candidate() {
  local area_name="$1" cand_name="$2"
  local maturity licence hosting cost pros cons fit

  printf '%b    Candidate: %s%b\n' "$ARCH_CYAN" "$cand_name" "$ARCH_NC"

  maturity=$(arch_ask_choice "    Maturity?" \
    "Emerging — < 2 years old, small community" \
    "Established — widely adopted, strong community" \
    "Declining — still usable but shrinking ecosystem" \
    "Unknown")
  [ "$maturity" = "Unknown" ] && arch_add_tdebt "$area_name" \
    "Maturity unknown for $cand_name" \
    "Candidate's maturity was not verified this session" \
    "Risk of picking a declining or unproven technology"

  licence=$(arch_ask "    Licence? (e.g. MIT, Apache 2.0, Commercial, BSL, or 'TBD — verify')")
  [ -z "$licence" ] && licence="TBD — verify"
  if [ "$licence" = "TBD — verify" ]; then
    arch_add_tdebt "$area_name" "Licence not verified for $cand_name" \
      "Licence terms not confirmed this session" \
      "Legal/procurement risk — may block adoption"
  fi

  hosting=$(arch_ask_choice "    Hosting model?" \
    "Self-host only" \
    "Managed / SaaS only" \
    "Both — self-host or managed" \
    "Unknown")

  cost=$(arch_ask_choice "    Typical cost signal?" \
    "\$ — low (free / cheap)" \
    "\$\$ — medium" \
    "\$\$\$ — high (enterprise)" \
    "Unknown")

  pros=$(arch_ask "    Top pros? (one line — comma-separated)")
  [ -z "$pros" ] && pros="TBD"

  cons=$(arch_ask "    Top cons / risks? (one line — comma-separated)")
  [ -z "$cons" ] && cons="TBD"

  fit=$(arch_ask_choice "    Fit against our constraints?" \
    "High — strongly aligned" \
    "Medium — mostly aligned, some gaps" \
    "Low — significant gaps")

  {
    echo "| $cand_name | $maturity | $licence | $hosting | $cost | $pros | $cons | $fit |"
  } >> "$OUTPUT_FILE"
}

# ── Per-area walker ───────────────────────────────────────────────────────────
walk_area() {
  local area_title="$1" hint="$2"
  echo ""
  printf '%b%b── %s ──%b\n' "$ARCH_CYAN" "$ARCH_BOLD" "$area_title" "$ARCH_NC"
  arch_dim "  $hint"
  echo ""

  local in_scope
  in_scope=$(arch_ask_yn "Is [$area_title] in scope for this architecture?")
  if [ "$in_scope" = "no" ]; then
    {
      echo "## $area_title"
      echo ""
      echo "_Not in scope for this architecture._"
      echo ""
    } >> "$OUTPUT_FILE"
    return
  fi

  # Write table header for this area
  {
    echo "## $area_title"
    echo ""
    echo "| Candidate | Maturity | Licence | Hosting | Cost | Pros | Cons | Fit |"
    echo "|---|---|---|---|---|---|---|---|"
  } >> "$OUTPUT_FILE"

  local added=0 add_more cand_name
  while true; do
    if [ "$added" -ge 4 ]; then
      arch_dim "  Reached 4 candidates — moving on."
      break
    fi
    cand_name=$(arch_ask "  Candidate name? (e.g. 'PostgreSQL 16', 'Node.js 20 LTS') — Enter to stop")
    if [ -z "$cand_name" ]; then
      break
    fi
    capture_candidate "$area_title" "$cand_name"
    added=$((added + 1))
    echo ""
    add_more=$(arch_ask_yn "  Add another candidate for [$area_title]?")
    if [ "$add_more" = "no" ]; then break; fi
  done

  if [ "$added" -lt 2 ]; then
    arch_add_tdebt "$area_title" "Fewer than 2 candidates captured for $area_title" \
      "Only $added candidate(s) recorded — comparison is weak" \
      "Decision may be biased / not justifiable"
  fi

  echo "" >> "$OUTPUT_FILE"
}

# ── Walk all decision areas ───────────────────────────────────────────────────
walk_area "Frontend framework & rendering" \
  "React / Vue / Angular / Svelte / server-rendered; SPA vs SSR vs SSG; styling"
walk_area "Backend runtime & language" \
  "Node.js, Python, Go, Java/Kotlin, .NET, Ruby, Rust"
walk_area "API style" \
  "REST, GraphQL, gRPC, tRPC, or event-driven"
walk_area "Database(s)" \
  "Relational (PostgreSQL, MySQL, SQL Server), Document (MongoDB, DynamoDB), KV (Redis), Search (OpenSearch), Analytics (BigQuery, Snowflake), Vector"
walk_area "Messaging / eventing" \
  "Kafka, RabbitMQ, SQS/SNS, NATS, Google Pub/Sub, or none"
walk_area "Caching" \
  "In-process, Redis, CDN, or none"
walk_area "Identity & access" \
  "Build vs Auth0 / Cognito / Entra ID / Keycloak; session vs JWT/OIDC"
walk_area "Hosting & compute" \
  "Kubernetes (EKS/AKS/GKE), ECS, Cloud Run, Lambda/Functions, App Service, VMs"
walk_area "Observability" \
  "OpenTelemetry + Grafana/Loki/Tempo, Datadog, New Relic, CloudWatch, Azure Monitor"
walk_area "CI/CD" \
  "GitHub Actions, GitLab CI, Azure DevOps, Jenkins, CircleCI"
walk_area "Security tooling" \
  "Secrets manager, WAF, SAST/DAST, dependency scanning"
walk_area "AI / ML services (if applicable)" \
  "Model hosting, vector store, orchestration framework"

# ── Finish ───────────────────────────────────────────────────────────────────
end_tdebts=$(arch_current_tdebt_count)
new_tdebts=$((end_tdebts - start_tdebts))

arch_success_rule "✅ Technology Research Complete"
printf '%b  Saved to: %s%b\n' "$ARCH_GREEN" "$OUTPUT_FILE" "$ARCH_NC"
if [ "$new_tdebts" -gt 0 ]; then
  printf '%b  ⚠  %d technical debt(s) logged to: %s%b\n' "$ARCH_YELLOW" "$new_tdebts" "$ARCH_TDEBT_FILE" "$ARCH_NC"
fi
echo ""
