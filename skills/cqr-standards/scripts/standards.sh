#!/bin/bash
# =============================================================================
# standards.sh — Phase 1: Coding Standards Review
#
# Audits the codebase for adherence to naming conventions, file structure,
# import ordering, documentation standards, linting tools, and deviations.
#
# Usage:
#   bash <SKILL_DIR>/cqr-standards/scripts/standards.sh [--auto] [--answers FILE]
#
# Outputs:
#   - $CQR_OUTPUT_DIR/01-standards-review.md
#   - $CQR_OUTPUT_DIR/01-standards-review.extract   (machine-readable)
#   - $CQR_OUTPUT_DIR/05-cq-debts.md                 (if debts created)
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# Accept --auto / --answers from caller (orchestrator or direct user).
cqr_parse_flags "$@"

OUTPUT_FILE="$CQR_OUTPUT_DIR/01-standards-review.md"
EXTRACT_FILE="$CQR_OUTPUT_DIR/01-standards-review.extract"

# ── Defaults (used in auto mode or when user picks "Not sure") ────────────────
DEF_LANGUAGE="JavaScript/TypeScript"
DEF_STYLE="Airbnb (JavaScript)"
DEF_NAMING="PascalCase classes + camelCase rest"
DEF_STRUCTURE="By feature (users/, products/, ...)"
DEF_IMPORTS="Stdlib → third-party → local"
DEF_DOCS="Google docstrings / JSDoc"
DEF_LINTER="ESLint + Prettier"
DEF_DEVIATIONS="None"

# ── Header ────────────────────────────────────────────────────────────────────
cqr_banner "Phase 1: Coding Standards Review"

if cqr_is_auto; then
  printf '\n%b[Auto mode]%b Reading from upstream + answers file; no prompts.\n\n' "$CQR_BOLD" "$CQR_NC"
else
  cat <<'EOF'

This phase audits your codebase for adherence to coding standards. You'll see
eight numbered-choice questions covering language, style guide, naming, folder
structure, imports, documentation, linting, and known deviations.

For each question:
  • Pick a number (1–N) from the menu.
  • Choose "Other — specify" to enter a custom value.
  • Choose "Not sure" to accept a sensible default and log a debt.

EOF
fi

# ── Q1: Languages ─────────────────────────────────────────────────────────────
[ "$(cqr_is_auto && echo y || echo n)" = "n" ] && {
  cqr_success_rule
  printf '%b[Q1 of 8] Primary programming language%b\n' "$CQR_BOLD" "$CQR_NC"
}
LANGUAGE=$(cqr_get_choice LANGUAGE "Primary programming language:" \
  "JavaScript" \
  "TypeScript" \
  "Python" \
  "Go" \
  "Java" \
  "C#" \
  "Rust" \
  "Ruby" \
  "PHP" \
  "Other — specify" \
  "Not sure — use default ($DEF_LANGUAGE) and log debt")
case "$LANGUAGE" in
  "Other — specify") LANGUAGE=$(cqr_get LANGUAGE_SPECIFY "Specify language(s):" "$DEF_LANGUAGE") ;;
  "Not sure"*)
    cqr_add_debt_auto "Standards" "Language not confirmed" \
      "User could not confirm primary language in Phase 1" \
      "Standards guidance will default to $DEF_LANGUAGE"
    LANGUAGE="$DEF_LANGUAGE" ;;
esac

# ── Q2: Style guide ───────────────────────────────────────────────────────────
cqr_is_auto || { cqr_success_rule; printf '%b[Q2 of 8] Coding style guide%b\n' "$CQR_BOLD" "$CQR_NC"; }
STYLE=$(cqr_get_choice STYLE "Style guide:" \
  "PEP 8 (Python)" \
  "Black (Python)" \
  "Airbnb (JavaScript)" \
  "Google (multi-language)" \
  "Standard JS" \
  "Microsoft (C#/.NET)" \
  "Go conventions (Effective Go)" \
  "Custom internal guide" \
  "Other — specify" \
  "Not sure — use default ($DEF_STYLE) and log debt")
case "$STYLE" in
  "Other — specify") STYLE=$(cqr_get STYLE_SPECIFY "Specify style guide:" "$DEF_STYLE") ;;
  "Not sure"*)
    cqr_add_debt_auto "Standards" "Style guide not confirmed" \
      "User could not confirm the style guide" \
      "Guidance will assume $DEF_STYLE"
    STYLE="$DEF_STYLE" ;;
esac

# ── Q3: Naming conventions ────────────────────────────────────────────────────
cqr_is_auto || { cqr_success_rule; printf '%b[Q3 of 8] Naming conventions%b\n' "$CQR_BOLD" "$CQR_NC"; }
NAMING=$(cqr_get_choice NAMING "Naming convention bundle:" \
  "All camelCase (variables + functions + classes)" \
  "All snake_case" \
  "PascalCase classes + camelCase functions/variables" \
  "PascalCase classes + snake_case functions/variables" \
  "Mixed by file / language" \
  "Other — specify" \
  "Not sure — use default ($DEF_NAMING) and log debt")
case "$NAMING" in
  "Other — specify") NAMING=$(cqr_get NAMING_SPECIFY "Specify naming rules:" "$DEF_NAMING") ;;
  "Not sure"*)
    cqr_add_debt_auto "Standards" "Naming conventions not confirmed" \
      "User could not confirm naming rules" \
      "Guidance will assume $DEF_NAMING"
    NAMING="$DEF_NAMING" ;;
esac

# ── Q4: File/folder structure ─────────────────────────────────────────────────
cqr_is_auto || { cqr_success_rule; printf '%b[Q4 of 8] File & folder structure%b\n' "$CQR_BOLD" "$CQR_NC"; }
STRUCTURE=$(cqr_get_choice STRUCTURE "Folder layout:" \
  "By layer (controllers/, services/, data/)" \
  "By feature (users/, products/, ...)" \
  "Domain-driven (entities/, services/, repositories/)" \
  "Flat (everything in src/)" \
  "Monorepo with packages" \
  "Other — specify" \
  "Not sure — use default ($DEF_STRUCTURE) and log debt")
case "$STRUCTURE" in
  "Other — specify") STRUCTURE=$(cqr_get STRUCTURE_SPECIFY "Describe the structure:" "$DEF_STRUCTURE") ;;
  "Not sure"*)
    cqr_add_debt_auto "Standards" "Folder structure not confirmed" \
      "User could not confirm folder layout" \
      "Guidance will assume $DEF_STRUCTURE"
    STRUCTURE="$DEF_STRUCTURE" ;;
esac

# ── Q5: Import ordering ───────────────────────────────────────────────────────
cqr_is_auto || { cqr_success_rule; printf '%b[Q5 of 8] Import & dependency ordering%b\n' "$CQR_BOLD" "$CQR_NC"; }
IMPORTS=$(cqr_get_choice IMPORTS "Import/dependency ordering:" \
  "Stdlib → third-party → local" \
  "Alphabetical (all)" \
  "Grouped by type, unordered within" \
  "None enforced" \
  "Other — specify" \
  "Not sure — use default ($DEF_IMPORTS) and log debt")
case "$IMPORTS" in
  "Other — specify") IMPORTS=$(cqr_get IMPORTS_SPECIFY "Specify rule:" "$DEF_IMPORTS") ;;
  "Not sure"*)
    cqr_add_debt_auto "Standards" "Import ordering not confirmed" \
      "User could not confirm import ordering" \
      "Guidance will assume $DEF_IMPORTS"
    IMPORTS="$DEF_IMPORTS" ;;
esac

# ── Q6: Documentation ─────────────────────────────────────────────────────────
cqr_is_auto || { cqr_success_rule; printf '%b[Q6 of 8] Documentation standards%b\n' "$CQR_BOLD" "$CQR_NC"; }
DOCS=$(cqr_get_choice DOCS "Documentation format:" \
  "JSDoc (JavaScript)" \
  "Google docstrings (Python)" \
  "NumPy docstrings (Python)" \
  "Sphinx (Python)" \
  "XML doc comments (C#/.NET)" \
  "GoDoc (Go)" \
  "Inline comments only (WHY, not WHAT)" \
  "None required" \
  "Other — specify" \
  "Not sure — use default ($DEF_DOCS) and log debt")
case "$DOCS" in
  "Other — specify") DOCS=$(cqr_get DOCS_SPECIFY "Specify:" "$DEF_DOCS") ;;
  "Not sure"*)
    cqr_add_debt_auto "Standards" "Documentation format not confirmed" \
      "User could not confirm documentation standard" \
      "Guidance will assume $DEF_DOCS"
    DOCS="$DEF_DOCS" ;;
esac

# ── Q7: Linting ───────────────────────────────────────────────────────────────
cqr_is_auto || { cqr_success_rule; printf '%b[Q7 of 8] Linting & formatting%b\n' "$CQR_BOLD" "$CQR_NC"; }
LINTER=$(cqr_get_choice LINTER "Linter / formatter:" \
  "ESLint + Prettier" \
  "Pylint + Black" \
  "Ruff + Black" \
  "golangci-lint + gofmt" \
  "Checkstyle + Spotless (Java)" \
  "StyleCop + Roslyn analyzers (C#)" \
  "Rustfmt + Clippy (Rust)" \
  "None / ad hoc" \
  "Other — specify" \
  "Not sure — use default ($DEF_LINTER) and log debt")
case "$LINTER" in
  "Other — specify") LINTER=$(cqr_get LINTER_SPECIFY "Specify tools:" "$DEF_LINTER") ;;
  "Not sure"*)
    cqr_add_debt_auto "Standards" "Linter not confirmed" \
      "User could not confirm linting tools" \
      "Guidance will assume $DEF_LINTER"
    LINTER="$DEF_LINTER" ;;
esac

# ── Q8: Known deviations ──────────────────────────────────────────────────────
cqr_is_auto || { cqr_success_rule; printf '%b[Q8 of 8] Known deviations from the standard%b\n' "$CQR_BOLD" "$CQR_NC"; }
DEVIATIONS=$(cqr_get DEVIATIONS "Known deviations (legacy modules, experiments, vendor integrations). Press Enter for 'None'." "$DEF_DEVIATIONS")
[ -z "$DEVIATIONS" ] && DEVIATIONS="$DEF_DEVIATIONS"

# ── Write markdown output ─────────────────────────────────────────────────────
printf '\n%b✓ Writing standards review to %s...%b\n' "$CQR_GREEN" "$OUTPUT_FILE" "$CQR_NC"

cat > "$OUTPUT_FILE" <<EOF
# Phase 1: Coding Standards Review

**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')
**Status:** Complete
**Mode:** $(cqr_is_auto && echo Auto || echo Interactive)

## Standards Baseline

| Standard | Value |
|---|---|
| **Language(s)** | $LANGUAGE |
| **Style Guide** | $STYLE |
| **Naming Conventions** | $NAMING |
| **File Structure** | $STRUCTURE |
| **Import Ordering** | $IMPORTS |
| **Documentation** | $DOCS |
| **Linting Tools** | $LINTER |
| **Known Deviations** | $DEVIATIONS |

## Next Phase

Phase 2 (Complexity & Maintainability Analysis) will measure cyclomatic complexity,
function/file sizes, and dependency coupling.

Run: \`bash <SKILL_DIR>/cqr-complexity/scripts/complexity.sh\`

---
EOF

# ── Write extract file ────────────────────────────────────────────────────────
cqr_write_extract "$EXTRACT_FILE" \
  "LANGUAGE=$LANGUAGE" \
  "STYLE=$STYLE" \
  "NAMING=$NAMING" \
  "STRUCTURE=$STRUCTURE" \
  "IMPORTS=$IMPORTS" \
  "DOCS=$DOCS" \
  "LINTER=$LINTER" \
  "DEVIATIONS=$DEVIATIONS"

cqr_success_rule
printf '%b✅ Phase 1 Complete.%b\n' "$CQR_GREEN" "$CQR_NC"
printf '  Markdown: %s\n' "$OUTPUT_FILE"
printf '  Extract:  %s\n' "$EXTRACT_FILE"
printf '\nNext: Phase 2 — bash <SKILL_DIR>/cqr-complexity/scripts/complexity.sh\n\n'
