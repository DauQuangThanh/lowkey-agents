#!/bin/bash
# =============================================================================
# fix.sh — Phase 2: per-item fix loop.
#
# Behaviour:
#   - Ensures a fix branch exists; never modifies main/master directly.
#   - Walks the batch from $BF_OUTPUT_DIR/.triage-head.tmp, showing each item
#     with its steps-to-reproduce and expected/actual fields.
#   - Prompts the user (interactive) or Claude (auto, via the agent .md
#     instructions) to apply a patch. The script itself does NOT perform
#     the code edit — it records the git diff after each Edit the agent
#     makes, commits on the fix branch, and logs the outcome.
#   - At each item: applied / deferred / skipped — debt logged for
#     non-applied.
#
# Outputs:
#   - $BF_OUTPUT_DIR/02-fixes.md
#   - $BF_OUTPUT_DIR/02-fixes.extract
#   - $BF_OUTPUT_DIR/patches/<ID>.diff (per applied fix)
#   - $BF_OUTPUT_DIR/all-patches.diff  (consolidated)
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

bf_parse_flags "$@"

OUTPUT_FILE="$BF_OUTPUT_DIR/02-fixes.md"
EXTRACT_FILE="$BF_OUTPUT_DIR/02-fixes.extract"
PATCH_DIR="$BF_OUTPUT_DIR/patches"
ALL_PATCHES="$BF_OUTPUT_DIR/all-patches.diff"
BATCH_FILE="$BF_OUTPUT_DIR/.triage-head.tmp"

mkdir -p "$PATCH_DIR"

bf_banner "Phase 2 — Fix loop"

# ── Safety rails ─────────────────────────────────────────────────────────────
if [ ! -f "$BATCH_FILE" ]; then
  printf '%bERROR:%b Triage batch file not found: %s\n' "$BF_RED" "$BF_NC" "$BATCH_FILE" >&2
  printf 'Run Phase 1 first: bash <SKILL_DIR>/bf-triage/scripts/triage.sh\n' >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  printf '%bERROR:%b git not on PATH. bug-fixer requires git.\n' "$BF_RED" "$BF_NC" >&2
  exit 1
fi

# Repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$REPO_ROOT" ]; then
  printf '%bERROR:%b Not inside a git repository.\n' "$BF_RED" "$BF_NC" >&2
  exit 1
fi

# Dirty-tree check — unless --dry-run
if ! bf_is_dry_run; then
  if [ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]; then
    printf '%bERROR:%b working tree is dirty. Commit or stash first, or use --dry-run.\n' "$BF_RED" "$BF_NC" >&2
    exit 1
  fi
fi

# Branch requirement for auto mode
if bf_is_auto && ! bf_is_dry_run; then
  if [ -z "${BF_BRANCH:-}" ]; then
    printf '%bERROR:%b auto mode requires --branch NAME (never patches the current branch).\n' "$BF_RED" "$BF_NC" >&2
    exit 1
  fi
fi

# Ensure / create fix branch (skip in dry-run)
CURRENT_BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
FIX_BRANCH=""
if ! bf_is_dry_run; then
  if [ -z "${BF_BRANCH:-}" ]; then
    FIX_BRANCH="bf/auto-$(date +%Y%m%d-%H%M%S)"
    bf_dim "  No --branch given; creating $FIX_BRANCH"
  else
    FIX_BRANCH="$BF_BRANCH"
  fi
  if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$FIX_BRANCH"; then
    git -C "$REPO_ROOT" checkout "$FIX_BRANCH" >/dev/null
  else
    git -C "$REPO_ROOT" checkout -b "$FIX_BRANCH" >/dev/null
  fi
  bf_dim "  Branch: $FIX_BRANCH"
else
  FIX_BRANCH="(dry-run — no branch switch)"
fi

# ── Config ───────────────────────────────────────────────────────────────────
MAX_FILES_PER_FIX=$(bf_get MAX_FILES_PER_FIX "Max files per fix (default 1):" "1")
MAX_LINES_PER_FIX=$(bf_get MAX_LINES_PER_FIX "Max total lines changed per fix (default 20):" "20")
COMMIT_STYLE=$(bf_get COMMIT_STYLE "Commit style:" "conventional")

# ── Per-item loop ────────────────────────────────────────────────────────────
FIXED=""; DEFERRED=""; SKIPPED=""; COMMITS=""
bf_num=0

# Start the markdown output
{
  echo "# Phase 2 — Fixes"
  echo ""
  echo "**Timestamp:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Mode:** $(bf_is_auto && echo Auto || echo Interactive)"
  echo "**Branch:** $FIX_BRANCH"
  echo "**Dry-run:** $(bf_is_dry_run && echo yes || echo no)"
  echo ""
} > "$OUTPUT_FILE"

: > "$ALL_PATCHES"

while IFS='|' read -r rank id source severity priority component title; do
  [ -z "$id" ] && continue
  bf_num=$((bf_num + 1))
  bf_id=$(printf 'BF-%02d' "$bf_num")

  printf '\n%b─── %s — resolves %s ────────────────────%b\n' "$BF_BOLD" "$bf_id" "$id" "$BF_NC"
  printf '  Source:    %s\n' "$source"
  printf '  Severity:  %s\n' "$severity"
  printf '  Priority:  %s\n' "$priority"
  printf '  Component: %s\n' "${component:-unknown}"
  printf '  Title:     %s\n\n' "$title"

  # Decision
  if bf_is_auto; then
    # In auto mode, the agent instructions tell Claude to inspect + patch
    # between script invocations. This script just records the current state
    # of the working tree after that presumed patch.
    decision="apply"
  else
    choice=$(bf_ask_choice "Action for this item:" \
      "Apply patch (you / Claude will edit files before confirming)" \
      "Skip (move to next without change)" \
      "Defer (log BFDEBT and move on)")
    case "$choice" in
      Apply*) decision="apply" ;;
      Skip*)  decision="skip" ;;
      Defer*) decision="defer" ;;
      *)      decision="skip" ;;
    esac
  fi

  patch_file="$PATCH_DIR/${id}.diff"

  case "$decision" in
    apply)
      # Interactive mode: wait for the user (or Claude) to finish editing.
      if ! bf_is_auto; then
        bf_dim "  → Make the code edits now, then press Enter to capture the diff."
        bf_dim "    (Or: press Enter with no changes to treat as deferred.)"
        IFS= read -r _dummy
      fi

      # Capture diff of working-tree vs HEAD
      if ! bf_is_dry_run; then
        git -C "$REPO_ROOT" diff HEAD > "$patch_file" 2>/dev/null || true
      else
        git -C "$REPO_ROOT" diff HEAD > "$patch_file" 2>/dev/null || true
      fi

      # Measure change size
      files_changed=$(git -C "$REPO_ROOT" diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
      lines_changed=$(git -C "$REPO_ROOT" diff --numstat HEAD 2>/dev/null | awk '{added+=$1; deleted+=$2} END {print added+deleted+0}')

      if [ "$files_changed" -eq 0 ]; then
        decision="defer"
        bf_add_debt "Fix" "$id — no diff produced" \
          "Apply-patch was chosen but working tree has no changes" \
          "Fix not applied; bug still open"
        bf_dim "  (no changes detected — marking as deferred)"
        rm -f "$patch_file"
        DEFERRED="${DEFERRED}${id},"
        append_section="deferred"
      else
        # Guard rails (auto mode only)
        if bf_is_auto; then
          if [ "$files_changed" -gt "$MAX_FILES_PER_FIX" ]; then
            bf_add_debt "Fix" "$id exceeds file limit" \
              "Patch touches $files_changed files (limit $MAX_FILES_PER_FIX)" \
              "Patch not committed; review manually"
            git -C "$REPO_ROOT" reset --hard HEAD >/dev/null 2>&1 || true
            DEFERRED="${DEFERRED}${id},"
            append_section="rejected-size"
          elif [ "${lines_changed:-0}" -gt "$MAX_LINES_PER_FIX" ]; then
            bf_add_debt "Fix" "$id exceeds line limit" \
              "Patch touches ${lines_changed} lines (limit $MAX_LINES_PER_FIX)" \
              "Patch not committed; review manually"
            git -C "$REPO_ROOT" reset --hard HEAD >/dev/null 2>&1 || true
            DEFERRED="${DEFERRED}${id},"
            append_section="rejected-size"
          else
            append_section="applied"
          fi
        else
          append_section="applied"
        fi

        if [ "$append_section" = "applied" ]; then
          # Commit
          if ! bf_is_dry_run; then
            git -C "$REPO_ROOT" add -A
            type_prefix="fix"
            case "$source" in
              csdebt) type_prefix="security" ;;
              cqdebt) type_prefix="refactor" ;;
            esac
            commit_msg="${type_prefix}(${id}): ${title}"
            git -C "$REPO_ROOT" commit -m "$commit_msg" >/dev/null 2>&1 || true
            commit_sha=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "")
          else
            commit_sha="(dry-run)"
          fi

          FIXED="${FIXED}${id},"
          COMMITS="${COMMITS}${commit_sha},"

          # Append to consolidated patch file
          {
            printf '# === %s — %s ===\n' "$bf_id" "$id"
            cat "$patch_file"
            printf '\n\n'
          } >> "$ALL_PATCHES"
        fi
      fi
      ;;
    skip)
      SKIPPED="${SKIPPED}${id},"
      append_section="skipped"
      ;;
    defer)
      bf_add_debt "Fix" "$id deferred" \
        "Operator chose to defer this item" \
        "Bug remains open; re-triage next round"
      DEFERRED="${DEFERRED}${id},"
      append_section="deferred"
      ;;
  esac

  # Write per-item section to the markdown
  {
    echo "## $bf_id: $id — $title"
    echo ""
    echo "| Field | Value |"
    echo "|---|---|"
    echo "| Resolves | $id |"
    echo "| Source | $source |"
    echo "| Severity | $severity |"
    echo "| Priority | $priority |"
    echo "| Component | ${component:-unknown} |"
    echo "| Outcome | $append_section |"
    if [ "$append_section" = "applied" ]; then
      echo "| Files changed | $files_changed |"
      echo "| Lines changed | ${lines_changed:-0} |"
      echo "| Branch | $FIX_BRANCH |"
      echo "| Commit | ${commit_sha:-} |"
      echo ""
      echo "### Diff"
      echo ""
      echo "\`\`\`diff"
      cat "$patch_file" 2>/dev/null
      echo "\`\`\`"
    fi
    echo ""
    echo "---"
    echo ""
  } >> "$OUTPUT_FILE"

done < "$BATCH_FILE"

FIXED="${FIXED%,}"; DEFERRED="${DEFERRED%,}"; SKIPPED="${SKIPPED%,}"; COMMITS="${COMMITS%,}"
[ -z "$FIXED" ] && FIXED="(none)"
[ -z "$DEFERRED" ] && DEFERRED="(none)"
[ -z "$SKIPPED" ] && SKIPPED="(none)"
[ -z "$COMMITS" ] && COMMITS="(none)"

bf_write_extract "$EXTRACT_FILE" \
  "FIXED_IDS=$FIXED" \
  "DEFERRED_IDS=$DEFERRED" \
  "SKIPPED_IDS=$SKIPPED" \
  "BRANCH=$FIX_BRANCH" \
  "COMMITS=$COMMITS" \
  "DRY_RUN=$(bf_is_dry_run && echo 1 || echo 0)" \
  "PATCH_DIR=$PATCH_DIR" \
  "CONSOLIDATED_PATCH=$ALL_PATCHES"

bf_success_rule "✅ Phase 2 Complete"
printf '  Fixed:    %s\n' "$FIXED"
printf '  Deferred: %s\n' "$DEFERRED"
printf '  Skipped:  %s\n' "$SKIPPED"
printf '  Branch:   %s\n' "$FIX_BRANCH"
printf '  Markdown: %s\n' "$OUTPUT_FILE"
printf '  Patches:  %s/\n' "$PATCH_DIR"
printf '\nNext: Phase 3 — bash <SKILL_DIR>/bf-regression/scripts/regression.sh\n\n'
