#!/bin/bash
# =============================================================================
# design.sh — Phase 1: Detailed Design
# Translates architecture diagrams into module/class structures, API contracts,
# database schemas, async flows, sequence diagrams, and dependency graphs.
# Writes output to $DEV_OUTPUT_DIR/01-detailed-design.md
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Step 3: accept --auto / --answers flags
dev_parse_flags "$@"


OUTPUT_FILE="$DEV_OUTPUT_DIR/01-detailed-design.md"
AREA="Detailed Design"

start_ddebts=$(dev_current_ddebt_count)

dev_banner "📐  Phase 1 of 4 — Detailed Design"
dev_dim "  Translate the architecture diagrams and ADRs into module/class"
dev_dim "  structures, API contracts, database schemas, and sequence diagrams."
echo ""

# Check for architecture input
if [ -f "$DEV_ARCH_INPUT_DIR/04-architecture.md" ]; then
  printf '%b  ✓ Found architecture documentation in: %s%b\n\n' "$DEV_GREEN" "$DEV_ARCH_INPUT_DIR" "$DEV_NC"
  arch_summary=$(head -20 "$DEV_ARCH_INPUT_DIR/04-architecture.md" | tail -15)
  dev_dim "  Quick summary from architecture:"
  echo "$arch_summary" | sed 's/^/    /'
  printf '\n'
  confirm=$(dev_ask_yn "Use this architecture as the basis for design?")
  if [ "$confirm" = "no" ]; then
    printf '%b  ⚠  Proceeding without architecture baseline.%b\n\n' "$DEV_YELLOW" "$DEV_NC"
  fi
else
  printf '%b  ⚠  No architecture.md found in %s%b\n' "$DEV_YELLOW" "$DEV_ARCH_INPUT_DIR" "$DEV_NC"
  printf '%b  Recommend running the architect subagent first.%b\n\n' "$DEV_YELLOW" "$DEV_NC"
fi

# ── Question 1: Module Breakdown ─────────────────────────────────────────────
printf '%b%b── Q1: Module Breakdown ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  For each Container from the C4 diagram, list the 3–5 major modules."
dev_dim "  Example: Orders, Inventory, Payments, Reporting, Auth"
modules=$(dev_ask "  List your modules (comma-separated):")
if [ -z "$modules" ]; then
  modules="TBD — modules not yet identified"
  dev_add_ddebt "$AREA" "Module breakdown incomplete" \
    "Modules were not identified or captured" \
    "Cannot proceed with class design without clear module boundaries"
fi
echo ""

# ── Question 2: Class/Component Structure ────────────────────────────────────
printf '%b%b── Q2: Class/Component Structure ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Sketch the key classes/types per module: controllers, services,"
dev_dim "  repositories, domain models, validators, adapters."
dev_dim "  Pattern preference? (Layered, Hexagonal/Ports&Adapters, CQRS, etc.)"
class_structure=$(dev_ask "  Describe the structure (e.g. 'Layered: Presentation/Domain/Data' or 'Hexagonal'):")
if [ -z "$class_structure" ]; then
  class_structure="TBD — class structure not yet decided"
  dev_add_ddebt "$AREA" "Class/component structure incomplete" \
    "No class structure or pattern decided" \
    "Developers will not know how to organize code into classes"
fi
echo ""

# ── Question 3: API Endpoints / Interface Contracts ──────────────────────────
printf '%b%b── Q3: API Endpoints / Interface Contracts ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  List the major API endpoints (REST, gRPC, messages)."
dev_dim "  For each: method + path, input schema, output schema, auth, errors."
api_endpoints=$(dev_ask "  Describe the top 5–10 endpoints (can be brief; refine later):")
if [ -z "$api_endpoints" ]; then
  api_endpoints="TBD — endpoints not yet listed"
  dev_add_ddebt "$AREA" "API endpoints not designed" \
    "No API endpoints or interface contracts captured" \
    "Frontend and backend teams cannot design in parallel"
fi
echo ""

# ── Question 4: Database Schema ──────────────────────────────────────────────
printf '%b%b── Q4: Database Schema ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Sketch the logical data model: entities, relationships, cardinality."
dev_dim "  Which tables are write-heavy vs. read-heavy? Denormalization needed?"
db_schema=$(dev_ask "  Describe the main tables/collections and relationships:")
if [ -z "$db_schema" ]; then
  db_schema="TBD — database schema not yet designed"
  dev_add_ddebt "$AREA" "Database schema incomplete" \
    "No database schema designed" \
    "Data layer implementation cannot start without schema"
fi
echo ""

# ── Question 5: Async/Event Design ───────────────────────────────────────────
printf '%b%b── Q5: Async/Event Design ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  What work should happen asynchronously (email, audit, data sync)?"
dev_dim "  Message queue? Event log? Webhooks? Consistency guarantees?"
async_design=$(dev_ask "  Describe async flows and event/message patterns:")
if [ -z "$async_design" ]; then
  async_design="TBD — async design not yet decided (assume synchronous for now)"
fi
echo ""

# ── Question 6: Cross-Cutting Concerns ───────────────────────────────────────
printf '%b%b── Q6: Cross-Cutting Concerns ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Logging, error handling, auth/authz, caching, feature flags."
dev_dim "  Where do these live in the module tree?"
cross_cutting=$(dev_ask "  Describe cross-cutting concerns and their location:")
if [ -z "$cross_cutting" ]; then
  cross_cutting="TBD — cross-cutting patterns to be defined"
  dev_add_ddebt "$AREA" "Cross-cutting concerns not specified" \
    "No logging, error handling, or auth patterns defined" \
    "Each developer will implement these differently"
fi
echo ""

# ── Question 7: Sequence Diagrams for Critical Flows ────────────────────────
printf '%b%b── Q7: Sequence Diagrams ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  For the top 3–4 critical flows (e.g. checkout, auth, search),"
dev_dim "  sketch the call sequence across modules and services."
sequences=$(dev_ask "  List critical flows and briefly sketch their sequences:")
if [ -z "$sequences" ]; then
  sequences="TBD — sequence diagrams to be created"
  dev_add_ddebt "$AREA" "Sequence diagrams not captured" \
    "No flows or sequence diagrams sketched" \
    "Developers may not understand call ordering and dependencies"
fi
echo ""

# ── Question 8: Dependency Map ───────────────────────────────────────────────
printf '%b%b── Q8: Dependency Map ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
dev_dim "  Which modules can depend on which others? Circular dependencies?"
dev_dim "  What's the natural build/implementation order?"
dep_map=$(dev_ask "  Describe the module dependency graph and build order:")
if [ -z "$dep_map" ]; then
  dep_map="TBD — dependency map to be determined"
  dev_add_ddebt "$AREA" "Module dependencies not mapped" \
    "No dependency graph or build order established" \
    "Implementation sequencing will be unclear"
fi
echo ""

# ── Confirmation ─────────────────────────────────────────────────────────────
printf '\n%b%b── Confirm All Answers ──%b\n' "$DEV_CYAN" "$DEV_BOLD" "$DEV_NC"
printf '\n%b  Modules:%b %s\n' "$DEV_DIM" "$DEV_NC" "$modules"
printf '%b  Class Structure:%b %s\n' "$DEV_DIM" "$DEV_NC" "$class_structure"
printf '%b  API Endpoints:%b %s\n' "$DEV_DIM" "$DEV_NC" "${api_endpoints:0:60}..."
printf '%b  Database:%b %s\n' "$DEV_DIM" "$DEV_NC" "${db_schema:0:60}..."
printf '%b  Async Flows:%b %s\n' "$DEV_DIM" "$DEV_NC" "${async_design:0:60}..."
printf '%b  Cross-Cutting:%b %s\n' "$DEV_DIM" "$DEV_NC" "${cross_cutting:0:60}..."
printf '%b  Sequences:%b %s\n' "$DEV_DIM" "$DEV_NC" "${sequences:0:60}..."
printf '%b  Dependencies:%b %s\n\n' "$DEV_DIM" "$DEV_NC" "${dep_map:0:60}..."

if dev_is_auto; then
  ready="yes"
else
  ready=$(dev_ask_yn "Write these to the design document?")
fi
if [ "$ready" = "no" ]; then
  printf '%b  Cancelled. No changes made.%b\n\n' "$DEV_YELLOW" "$DEV_NC"
  exit 0
fi

# ── Write output file ────────────────────────────────────────────────────────
{
  echo "# Detailed Design — [Project Name]"
  echo ""
  echo "**Date:** $(date '+%Y-%m-%d')"
  echo "**Developer:** [Name]"
  echo "**Architecture Source:** arch-output/ (see 04-architecture.md)"
  echo ""
  echo "## Overview"
  echo ""
  echo "This document translates the C4 architecture diagrams and ADRs into concrete"
  echo "module/class structures, API contracts, database schemas, and implementation"
  echo "sequences. It serves as the blueprint for code implementation."
  echo ""
  echo "---"
  echo ""
  echo "## Module Breakdown"
  echo ""
  echo "**Modules (Q1):**"
  echo ""
  echo "${modules}"
  echo ""
  echo "---"
  echo ""
  echo "## Class / Component Structure"
  echo ""
  echo "**Pattern (Q2):**"
  echo ""
  echo "${class_structure}"
  echo ""
  echo "---"
  echo ""
  echo "## API Endpoints & Interface Contracts"
  echo ""
  echo "**Endpoints (Q3):**"
  echo ""
  echo "${api_endpoints}"
  echo ""
  echo "---"
  echo ""
  echo "## Database Schema"
  echo ""
  echo "**Schema (Q4):**"
  echo ""
  echo "${db_schema}"
  echo ""
  echo "---"
  echo ""
  echo "## Async / Event Flows"
  echo ""
  echo "**Flows (Q5):**"
  echo ""
  echo "${async_design}"
  echo ""
  echo "---"
  echo ""
  echo "## Cross-Cutting Concerns"
  echo ""
  echo "**Concerns (Q6):**"
  echo ""
  echo "${cross_cutting}"
  echo ""
  echo "---"
  echo ""
  echo "## Sequence Diagrams"
  echo ""
  echo "**Critical Flows (Q7):**"
  echo ""
  echo "${sequences}"
  echo ""
  echo "---"
  echo ""
  echo "## Module Dependency Graph"
  echo ""
  echo "**Dependencies (Q8):**"
  echo ""
  echo "${dep_map}"
  echo ""
  echo "---"
  echo ""
  echo "## Known Unknowns / Design Debts"
  echo ""
  echo "_See 05-design-debts.md_"
  echo ""
} > "$OUTPUT_FILE"

printf '%b  ✅ Saved: %s%b\n\n' "$DEV_GREEN" "$OUTPUT_FILE" "$DEV_NC"

end_ddebts=$(dev_current_ddebt_count)
new_ddebts=$((end_ddebts - start_ddebts))

dev_success_rule "✅ Detailed Design Complete"
printf '%b  Output:  %s%b\n' "$DEV_GREEN" "$OUTPUT_FILE" "$DEV_NC"
if [ "$new_ddebts" -gt 0 ]; then
  printf '%b  ⚠  %d design debt(s) logged to: %s%b\n' "$DEV_YELLOW" "$new_ddebts" "$DEV_DEBT_FILE" "$DEV_NC"
fi
echo ""
