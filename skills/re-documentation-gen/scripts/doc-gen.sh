#!/bin/bash
# Phase 6: Documentation Generation & Compilation
# Aggregates the outputs of phases 1–5 into:
#   - 06-documentation.md (full stitched document)
#   - RE-FINAL.md          (executive summary)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

if declare -f re_parse_flags >/dev/null 2>&1; then
  re_parse_flags "$@"
fi

re_init_debt_file
DOC_FILE="$RE_OUTPUT_DIR/06-documentation.md"
FINAL_FILE="$RE_OUTPUT_DIR/RE-FINAL.md"

PHASE_1="$RE_OUTPUT_DIR/01-codebase-inventory.md"
PHASE_2="$RE_OUTPUT_DIR/02-architecture.md"
PHASE_3="$RE_OUTPUT_DIR/03-api-documentation.md"
PHASE_4="$RE_OUTPUT_DIR/04-data-model.md"
PHASE_5="$RE_OUTPUT_DIR/05-dependency-map.md"
DEBT_FILE="$RE_OUTPUT_DIR/07-re-debts.md"

# ── Check which phases ran ───────────────────────────────────────────────────
missing=()
for f in "$PHASE_1" "$PHASE_2" "$PHASE_3" "$PHASE_4" "$PHASE_5"; do
  [ -f "$f" ] || missing+=("$(basename "$f")")
done
if [ "${#missing[@]}" -gt 0 ]; then
  re_warning "Missing upstream phases: ${missing[*]}"
  re_add_debt_auto "Documentation" "Missing upstream phase outputs" \
    "Phase 6 ran without: ${missing[*]}" \
    "Final documentation will have gaps for these phases"
fi

# ── Extract values from phase .extract companions (if present) ───────────────
read_ext() {
  # read_ext <extract-file> <key> [default]
  local f="$1" k="$2" default="${3:-}"
  [ -f "$f" ] || { printf '%s' "$default"; return 0; }
  local v
  v=$(grep -E "^${k}=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
  [ -z "$v" ] && v="$default"
  printf '%s' "$v"
}

total_files=$(read_ext "$RE_OUTPUT_DIR/01-codebase-inventory.extract" TOTAL_FILES "(unknown)")
total_loc=$(read_ext "$RE_OUTPUT_DIR/01-codebase-inventory.extract"   TOTAL_LOC   "(unknown)")
primary_lang=$(read_ext "$RE_OUTPUT_DIR/01-codebase-inventory.extract" PRIMARY_LANGUAGE "$(read_ext "$RE_OUTPUT_DIR/01-codebase-inventory.extract" LANGUAGES "(unknown)")")
frameworks=$(read_ext "$RE_OUTPUT_DIR/02-architecture.extract" FRAMEWORKS "(none detected)")
layers=$(read_ext    "$RE_OUTPUT_DIR/02-architecture.extract" LAYERS     "(none detected)")
deployment=$(read_ext "$RE_OUTPUT_DIR/02-architecture.extract" DEPLOYMENT "(none detected)")
rest_count=$(read_ext "$RE_OUTPUT_DIR/03-api-documentation.extract" REST_ROUTE_COUNT "0")
storage_files=$(read_ext "$RE_OUTPUT_DIR/03-api-documentation.extract" CLIENT_STORAGE_FILES "0")
databases=$(read_ext  "$RE_OUTPUT_DIR/04-data-model.extract" DATABASES "(none detected)")
orms=$(read_ext       "$RE_OUTPUT_DIR/04-data-model.extract" ORMS      "(none detected)")
storage_refs=$(read_ext "$RE_OUTPUT_DIR/04-data-model.extract" CLIENT_STORAGE_KEY_REFS "0")
manifests=$(read_ext  "$RE_OUTPUT_DIR/05-dependency-map.extract" MANIFESTS "(none found)")
direct_deps=$(read_ext "$RE_OUTPUT_DIR/05-dependency-map.extract" DIRECT_DEPS "0")
dev_deps=$(read_ext    "$RE_OUTPUT_DIR/05-dependency-map.extract" DEV_DEPS     "0")

debt_count=$(re_current_debt_count)

# ── Write stitched 06-documentation.md ───────────────────────────────────────
{
  echo "# Reverse Engineering Report — Full Documentation"
  echo ""
  echo "**Generated:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo ""
  echo "This document stitches together every RE phase output for a project"
  echo "you can hand to a new engineer as-is."
  echo ""
  echo "---"
  echo ""
  for f in "$PHASE_1" "$PHASE_2" "$PHASE_3" "$PHASE_4" "$PHASE_5"; do
    if [ -f "$f" ]; then
      cat "$f"
      echo ""
      echo "---"
      echo ""
    fi
  done
  if [ -f "$DEBT_FILE" ]; then
    cat "$DEBT_FILE"
  fi
} > "$DOC_FILE"

# ── Write RE-FINAL.md (executive summary) ────────────────────────────────────
{
  echo "# RE-FINAL — Reverse Engineering Executive Summary"
  echo ""
  echo "**Generated:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Source root:** \`$(read_ext "$RE_OUTPUT_DIR/01-codebase-inventory.extract" SOURCE_ROOT "${SOURCE_ROOT:-unknown}")\`"
  echo ""
  echo "## At a Glance"
  echo ""
  echo "| Dimension | Value |"
  echo "|---|---|"
  echo "| Primary language    | $primary_lang |"
  echo "| Total files         | $total_files |"
  echo "| Total lines of code | $total_loc |"
  echo "| Frameworks detected | $frameworks |"
  echo "| Layer directories   | $layers |"
  echo "| Deployment artefacts | $deployment |"
  echo "| REST routes         | $rest_count |"
  echo "| Client storage refs | $storage_refs ($storage_files files) |"
  echo "| Databases           | $databases |"
  echo "| ORMs                | $orms |"
  echo "| Package manifests   | $manifests |"
  echo "| Direct dependencies | $direct_deps |"
  echo "| Dev dependencies    | $dev_deps |"
  echo "| RE debts logged     | $debt_count |"
  echo ""
  echo "## Phase Completeness"
  echo ""
  for label in "Codebase Inventory:01-codebase-inventory.md" \
               "Architecture:02-architecture.md" \
               "APIs:03-api-documentation.md" \
               "Data Model:04-data-model.md" \
               "Dependencies:05-dependency-map.md"; do
    name="${label%%:*}"
    file="${label##*:}"
    if [ -f "$RE_OUTPUT_DIR/$file" ]; then
      echo "- ✅ $name (\`$file\`)"
    else
      echo "- ❌ $name (\`$file\` missing — phase didn't run)"
    fi
  done
  echo ""
  echo "## Next Steps"
  echo ""
  echo "1. Review \`06-documentation.md\` for the complete stitched report."
  echo "2. Clear \`07-re-debts.md\` ($debt_count item(s)) — areas the scripts could not determine automatically."
  step=3
  if [ "$rest_count" = "0" ] && [ "$storage_refs" != "0" ]; then
    echo "${step}. This is a client-only application — its \"API\" is the browser storage contract, not HTTP."
    step=$((step + 1))
  fi
  if [ "$direct_deps" = "0" ] && [ "$primary_lang" != "(unknown)" ]; then
    echo "${step}. Zero external dependencies — suitable for air-gapped / offline deployment."
  fi
  echo ""
  echo "---"
  echo ""
  echo "_Generated by the RE workflow. See individual phase files in \`$RE_OUTPUT_DIR\` for detail._"
  echo ""
} > "$FINAL_FILE"

re_success "Phase 6 complete — documentation compiled"
echo ""
echo "Outputs:"
echo "  - $DOC_FILE (full documentation)"
echo "  - $FINAL_FILE (executive summary)"
echo "  - $DEBT_FILE ($debt_count debt(s) tracked)"
