#!/bin/bash
# =============================================================================
# register.sh — Phase 4: aggregate change register with upstream/downstream impact.
#
# Reads:
#   - $BF_OUTPUT_DIR/02-fixes.extract        (FIXED_IDS, BRANCH, COMMITS)
#   - $BF_OUTPUT_DIR/02-fixes.md             (per-fix diffs)
#   - $BF_OUTPUT_DIR/03-regression-tests.extract (TEST_IDS)
#   - git diff stats from the consolidated patch
# Writes:
#   - $BF_OUTPUT_DIR/04-change-register.md     (the upstream+downstream feed)
#   - $BF_OUTPUT_DIR/04-change-register.extract
#   - $BF_OUTPUT_DIR/05-upstream-impact.md     (per-upstream-agent drill-down)
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

bf_parse_flags "$@"

REGISTER_MD="$BF_OUTPUT_DIR/04-change-register.md"
REGISTER_EXTRACT="$BF_OUTPUT_DIR/04-change-register.extract"
UPSTREAM_MD="$BF_OUTPUT_DIR/05-upstream-impact.md"

FIX_EXTRACT="$BF_OUTPUT_DIR/02-fixes.extract"
REG_TEST_EXTRACT="$BF_OUTPUT_DIR/03-regression-tests.extract"
ALL_PATCHES="$BF_OUTPUT_DIR/all-patches.diff"

bf_banner "Phase 4 — Change register"

if [ ! -f "$FIX_EXTRACT" ]; then
  printf '%bERROR:%b Phase 2 extract not found. Run bf-fix first.%b\n' "$BF_RED" "$BF_NC" "$BF_NC" >&2
  exit 1
fi

FIXED_IDS=$(bf_read_extract "$FIX_EXTRACT" FIXED_IDS)
BRANCH=$(bf_read_extract "$FIX_EXTRACT" BRANCH)
COMMITS=$(bf_read_extract "$FIX_EXTRACT" COMMITS)
TEST_IDS=$(bf_read_extract "$REG_TEST_EXTRACT" TEST_IDS 2>/dev/null || echo "")
PATCH_DIR=$(bf_read_extract "$FIX_EXTRACT" PATCH_DIR)

# Aggregate files touched across the whole batch
ALL_FILES=""
if [ -f "$ALL_PATCHES" ]; then
  ALL_FILES=$(grep -E '^\+\+\+ b/' "$ALL_PATCHES" 2>/dev/null \
    | sed -E 's|^\+\+\+ b/||' \
    | sort -u \
    | tr '\n' ';')
fi
[ -z "$ALL_FILES" ] && ALL_FILES="(none)"

# Classify upstream impact by path heuristic
classify_upstream() {
  local files="$1"
  local hits_ba="" hits_arch="" hits_dev="" hits_ux=""
  IFS=';'
  for f in $files; do
    [ -z "$f" ] && continue
    case "$f" in
      *docs/requirements/*|*ba-output/*|*REQUIREMENTS*) hits_ba="${hits_ba}${f};" ;;
    esac
    case "$f" in
      *docs/architecture/*|*arch-output/*|*ADR-*|*adr/*) hits_arch="${hits_arch}${f};" ;;
    esac
    case "$f" in
      *src/*|*lib/*|*app/*|*internal/*|*pkg/*) hits_dev="${hits_dev}${f};" ;;
    esac
    case "$f" in
      *ui/*|*frontend/*|*components/*|*views/*|*pages/*|*.tsx|*.jsx|*.vue|*.svelte) hits_ux="${hits_ux}${f};" ;;
    esac
  done
  unset IFS
  printf '%s|%s|%s|%s' "${hits_ba%;}" "${hits_arch%;}" "${hits_dev%;}" "${hits_ux%;}"
}

IFS='|' read -r UP_BA UP_ARCH UP_DEV UP_UX <<<"$(classify_upstream "$ALL_FILES")"
[ -z "$UP_BA" ]   && UP_BA="(none apparent)"
[ -z "$UP_ARCH" ] && UP_ARCH="(none apparent)"
[ -z "$UP_DEV" ]  && UP_DEV="(none apparent)"
[ -z "$UP_UX" ]   && UP_UX="(none apparent)"

# Downstream reviewers that should re-run
DOWN_CQR="$ALL_FILES"
DOWN_CSR="$ALL_FILES"
DOWN_TESTER="See 03-regression-tests.md ($TEST_IDS)"

# ── Write change-register.md ─────────────────────────────────────────────────
{
  echo "# Change Register"
  echo ""
  echo "**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Branch:** $BRANCH"
  echo "**Fixed IDs:** $FIXED_IDS"
  echo "**Commits:**   $COMMITS"
  echo "**Regression test IDs:** ${TEST_IDS:-(none)}"
  echo ""
  echo "## Files Modified (Batch)"
  echo ""
  if [ "$ALL_FILES" = "(none)" ]; then
    echo "_No files modified — either no fixes applied or dry-run only._"
  else
    IFS=';'
    for f in $ALL_FILES; do
      [ -z "$f" ] && continue
      echo "- \`$f\`"
    done
    unset IFS
  fi
  echo ""
  echo "## Per-Fix Table"
  echo ""
  echo "| Fix | Resolves | Source | Files | Tests | Commit | Upstream hint | Downstream |"
  echo "|---|---|---|---|---|---|---|---|"

  # Walk 02-fixes.md per-section to extract per-fix details
  python3 - "$BF_OUTPUT_DIR/02-fixes.md" "$TEST_IDS" <<'PY'
import re, sys, pathlib
fixes_md = pathlib.Path(sys.argv[1])
test_ids = sys.argv[2] if len(sys.argv) > 2 else ""
if not fixes_md.exists():
    sys.exit(0)
text = fixes_md.read_text()
# Split by BF-NN sections
parts = re.split(r'^## (BF-\d+):', text, flags=re.MULTILINE)
# parts = [preamble, id1, body1, id2, body2, ...]
for i in range(1, len(parts), 2):
    bf_id = parts[i]
    body = parts[i+1] if i+1 < len(parts) else ""
    def field(name):
        m = re.search(rf'\| {name} \| (.+?) \|', body)
        return m.group(1).strip() if m else ""
    resolves = field("Resolves")
    source   = field("Source")
    outcome  = field("Outcome")
    commit   = field("Commit")
    files_changed = field("Files changed")
    if outcome != "applied":
        continue
    # Upstream hint: pick one of the four based on the Component (rough)
    up = "developer"  # default
    # Very rough — a real system would read the file paths, but the
    # per-fix section doesn't list them; operator can refine.
    print(f"| {bf_id} | {resolves} | {source} | {files_changed} | {test_ids or '(TBD)'} | {commit} | {up} | cqr, csr, tester |")
PY
  echo ""
  echo "## Downstream Reviewers"
  echo ""
  echo "- **code-quality-reviewer:** re-run on touched files (see extract \`FILES_MODIFIED\`)"
  echo "- **code-security-reviewer:** re-run on touched files"
  echo "- **tester:** merge regression tests from \`03-regression-tests.md\` into \`test-output/02-test-cases.md\`, then re-execute"
  echo ""
  echo "---"
} > "$REGISTER_MD"

# ── Write upstream-impact.md ─────────────────────────────────────────────────
{
  echo "# Upstream Impact"
  echo ""
  echo "**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Branch:** $BRANCH"
  echo ""
  echo "Each section below is consumed by the named agent on its next run to"
  echo "decide whether its earlier outputs need revising."
  echo ""
  echo "## business-analyst"
  echo ""
  echo "Paths that may relate to requirement changes (heuristic):"
  echo ""
  if [ "$UP_BA" = "(none apparent)" ]; then
    echo "- $UP_BA"
  else
    IFS=';'; for f in $UP_BA; do [ -n "$f" ] && echo "- \`$f\`"; done; unset IFS
  fi
  echo ""
  echo "Action on next BA run: if any fix changes user-observable behaviour,"
  echo "re-visit the matching user story's acceptance criteria."
  echo ""
  echo "## architect"
  echo ""
  echo "Paths under architecture/docs (heuristic):"
  echo ""
  if [ "$UP_ARCH" = "(none apparent)" ]; then
    echo "- $UP_ARCH"
  else
    IFS=';'; for f in $UP_ARCH; do [ -n "$f" ] && echo "- \`$f\`"; done; unset IFS
  fi
  echo ""
  echo "Action on next architect run: check ADRs referenced by the fix commit"
  echo "messages — any new pattern introduced probably needs a superseding ADR."
  echo ""
  echo "## developer"
  echo ""
  echo "Source paths touched (heuristic):"
  echo ""
  if [ "$UP_DEV" = "(none apparent)" ]; then
    echo "- $UP_DEV"
  else
    IFS=';'; for f in $UP_DEV; do [ -n "$f" ] && echo "- \`$f\`"; done; unset IFS
  fi
  echo ""
  echo "Action on next developer run: update \`dev-output/01-detailed-design.md\`"
  echo "if module boundaries / class structure / APIs changed."
  echo ""
  echo "## ux-designer"
  echo ""
  echo "UI/UX paths touched (heuristic):"
  echo ""
  if [ "$UP_UX" = "(none apparent)" ]; then
    echo "- $UP_UX"
  else
    IFS=';'; for f in $UP_UX; do [ -n "$f" ] && echo "- \`$f\`"; done; unset IFS
  fi
  echo ""
  echo "Action on next UX run: re-check wireframes if user-facing UI changed."
  echo ""
  echo "---"
} > "$UPSTREAM_MD"

# ── Write extract ────────────────────────────────────────────────────────────
bf_write_extract "$REGISTER_EXTRACT" \
  "FILES_MODIFIED=$ALL_FILES" \
  "UPSTREAM_AFFECTED=ba:$UP_BA;arch:$UP_ARCH;dev:$UP_DEV;ux:$UP_UX" \
  "DOWNSTREAM_AFFECTED=cqr;csr;tester" \
  "BRANCH=$BRANCH" \
  "FIXED_IDS=$FIXED_IDS" \
  "COMMITS=$COMMITS" \
  "TEST_IDS=$TEST_IDS"

bf_success_rule "✅ Phase 4 Complete"
printf '  Change register:  %s\n' "$REGISTER_MD"
printf '  Upstream impact:  %s\n' "$UPSTREAM_MD"
printf '  Extract:          %s\n' "$REGISTER_EXTRACT"
printf '\nNext: Phase 5 — bash <SKILL_DIR>/bf-validation/scripts/validate.sh\n\n'
