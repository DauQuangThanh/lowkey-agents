#!/bin/bash
# =============================================================================
# _common.sh — Shared helpers embedded inside this skill.
#
# SOURCING (from a sibling script in the same scripts/ folder):
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/_common.sh"
#
# Features:
#   - Bash 3.2+ compatible (works on macOS default shell)
#   - Respects $CQR_OUTPUT_DIR, falls back to ./cqr-output
#   - Continuous CQDEBT numbering across all code quality reviewer skills
#   - Shared cqr_ask / cqr_ask_yn / cqr_ask_choice / cqr_add_debt helpers
# =============================================================================

# ── Bash version guard ────────────────────────────────────────────────────────
if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
  echo "ERROR: Bash 3.2 or later is required." >&2
  echo "       Current: ${BASH_VERSION:-unknown}" >&2
  exit 1
fi

# ── Colours (CQR_ prefix for green theme) ─────────────────────────────────────
CQR_RED='\033[0;31m'; CQR_GREEN='\033[0;32m'; CQR_YELLOW='\033[1;33m'
CQR_BLUE='\033[0;34m'; CQR_CYAN='\033[0;36m'; CQR_ORANGE='\033[0;33m'
CQR_BOLD='\033[1m'; CQR_DIM='\033[2m'; CQR_NC='\033[0m'
CQR_BRIGHT_GREEN='\033[1;32m'

# ── Paths ─────────────────────────────────────────────────────────────────────
CQR_OUTPUT_DIR="${CQR_OUTPUT_DIR:-$(pwd)/cqr-output}"
CQR_DEBT_FILE="$CQR_OUTPUT_DIR/05-cq-debts.md"
mkdir -p "$CQR_OUTPUT_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────

# to_lower: Bash 3.2-compatible lowercase conversion.
to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# slugify: lowercase, replace non-alphanum with hyphens, collapse.
cqr_slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]/-/g' -e 's/-\{1,\}/-/g' -e 's/^-//' -e 's/-$//'
}

# cqr_ask: Prompt and read a line of input (trimmed)
cqr_ask() {
  local prompt="$1" answer
  printf '%b▶ %s%b\n' "$CQR_YELLOW" "$prompt" "$CQR_NC" >&2
  IFS= read -r answer
  answer="$(printf '%s' "$answer" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$answer"
}

# cqr_ask_yn: Prompt for yes/no, return "yes" or "no"
cqr_ask_yn() {
  local prompt="$1" raw norm
  while true; do
    printf '%b▶ %s (y/n): %b\n' "$CQR_YELLOW" "$prompt" "$CQR_NC" >&2
    IFS= read -r raw
    norm="$(to_lower "$raw")"
    case "$norm" in
      y|yes) printf '%s' "yes"; return 0 ;;
      n|no)  printf '%s' "no";  return 0 ;;
      *)     printf '%b  Please type y or n.%b\n' "$CQR_RED" "$CQR_NC" >&2 ;;
    esac
  done
}

# cqr_ask_choice: Prompt with numbered choices, return selected option
cqr_ask_choice() {
  local prompt="$1"; shift
  local options=("$@")
  local i choice total="${#options[@]}"
  printf '%b▶ %s%b\n' "$CQR_YELLOW" "$prompt" "$CQR_NC" >&2
  for ((i=0; i<total; i++)); do
    printf '  %d) %s\n' "$((i+1))" "${options[$i]}"
  done
  while true; do
    IFS= read -r choice
    choice="$(printf '%s' "$choice" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [ "$choice" -ge 1 ] && [ "$choice" -le "$total" ] 2>/dev/null; then
      printf '%s' "${options[$((choice-1))]}"
      return 0
    else
      printf '%b  Please enter a number between 1 and %d.%b\n' "$CQR_RED" "$total" "$CQR_NC" >&2
    fi
  done
}

# cqr_confirm_save: Ask user to confirm answer; return "yes" if ok, else "redo"
cqr_confirm_save() {
  local answer="$1"
  printf '\n%bYou answered: %b%s%b\n' "$CQR_CYAN" "$CQR_BOLD" "$answer" "$CQR_NC"
  local yn=$(cqr_ask_yn "Is this correct?")
  if [ "$yn" = "yes" ]; then
    printf 'yes'
  else
    printf 'redo'
  fi
}

# cqr_current_debt_count: Count CQDEBT-NN entries in the debt file
cqr_current_debt_count() {
  if [ -f "$CQR_DEBT_FILE" ]; then
    grep -c '^## CQDEBT-' "$CQR_DEBT_FILE" 2>/dev/null || echo 0
  else
    echo 0
  fi
}

# cqr_add_debt: Add a debt entry to 05-cq-debts.md
# Usage: cqr_add_debt "Title" "Description" "severity" "effort"
# severity: Critical, Major, Minor, Info
# effort: S (small), M (medium), L (large)
cqr_add_debt() {
  local title="$1" description="$2" severity="$3" effort="$4"
  local count=$(cqr_current_debt_count)
  local next_id=$((count + 1))

  # Ensure debt file exists with header
  if [ ! -f "$CQR_DEBT_FILE" ]; then
    cat > "$CQR_DEBT_FILE" << 'EOF'
# Code Quality Debt Register (CQDEBT-NN)

This file tracks technical debt entries discovered during code quality reviews.
Format: CQDEBT-NN (2-digit incrementing ID)
Status: tracked (awaiting resolution)

---

EOF
  fi

  # Append debt entry
  cat >> "$CQR_DEBT_FILE" << EOF

## CQDEBT-$(printf '%02d' "$next_id"): $title

| Field | Value |
|---|---|
| **Status** | Tracked |
| **Severity** | $severity |
| **Effort** | $effort |
| **Found** | $(date -u +'%Y-%m-%dT%H:%M:%SZ') |
| **Description** | $description |

EOF
}

# cqr_banner: Print a section banner
cqr_banner() {
  local text="$1"
  printf '\n%b%s%b\n' "$CQR_BRIGHT_GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$CQR_NC"
  printf '%b%s%b\n' "$CQR_BRIGHT_GREEN" "$text" "$CQR_NC"
  printf '%b%s%b\n' "$CQR_BRIGHT_GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$CQR_NC"
}

# cqr_success_rule: Print a success divider
cqr_success_rule() {
  printf '\n%b%s%b\n' "$CQR_GREEN" "─────────────────────────────────────────" "$CQR_NC"
}

# cqr_dim: Print dimmed text
cqr_dim() {
  printf '%b%s%b\n' "$CQR_DIM" "$1" "$CQR_NC"
}

# Export for subshells
export CQR_OUTPUT_DIR CQR_DEBT_FILE
export CQR_RED CQR_GREEN CQR_YELLOW CQR_BLUE CQR_CYAN CQR_ORANGE CQR_BOLD CQR_DIM CQR_NC CQR_BRIGHT_GREEN

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1
#
# Adds a dual-mode (interactive + non-interactive/auto) layer on top of the
# existing cqr_ask / _ask_yn / _ask_choice / _add_debt helpers. Scripts
# that want auto support call cqr_get / _get_yn / _get_choice with a
# stable KEY and pick up values from (in priority order):
#
#   1. an environment variable named $KEY
#   2. the --answers <file> (KEY=VALUE pairs)
#   3. any configured upstream extract files
#   4. the documented default
#   5. interactive prompt — only when not in auto mode
#
# Activation: pass --auto on the CLI (via cqr_parse_flags "$@") or set
# CQR_AUTO=1 in the environment. See IMPROVEMENT-PLAN.md for the full
# contract.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
: "${CQR_AUTO:=0}"; export CQR_AUTO
: "${CQR_ANSWERS:=}"; export CQR_ANSWERS

# Upstream-extract search paths. Agents that read upstream output should
# append to this array from their phase scripts, e.g.:
#   CQR_UPSTREAM_EXTRACTS+=("$DEV_OUTPUT_DIR/02-coding-plan.extract")
if [ -z "${CQR_UPSTREAM_EXTRACTS+x}" ]; then
  # Canonical upstream directories for CQR — developer output (primary) and
  # architect output (secondary). Env var overrides supported.
  _CQR_DEV_OUT="${DEV_OUTPUT_DIR:-$(pwd)/dev-output}"
  _CQR_ARCH_OUT="${ARCH_OUTPUT_DIR:-$(pwd)/arch-output}"
  CQR_UPSTREAM_EXTRACTS=(
    "$_CQR_DEV_OUT/01-detailed-design.extract"
    "$_CQR_DEV_OUT/02-coding-plan.extract"
    "$_CQR_DEV_OUT/03-unit-test-plan.extract"
    "$_CQR_ARCH_OUT/01-architecture-intake.extract"
  )
fi

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts should call:  cqr_parse_flags "$@"
# Recognised: --auto, --answers <file>, --answers=<file>. Unknown flags are
# ignored so the helper composes with scripts that have their own arg parsing.
cqr_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)        CQR_AUTO=1; export CQR_AUTO; shift ;;
      --answers)     CQR_ANSWERS="${2:-}"; export CQR_ANSWERS; shift 2 ;;
      --answers=*)   CQR_ANSWERS="${1#--answers=}"; export CQR_ANSWERS; shift ;;
      *)             shift ;;
    esac
  done
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
cqr_is_auto() {
  case "${CQR_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Extract-file reader ──────────────────────────────────────────────────────
# Reads KEY=VALUE pairs (one per line, `#` comments allowed) from the given
# file. Echoes the value for the requested key, or empty.
cqr_read_extract() {
  local file="$1" key="$2"
  [ -f "$file" ] || return 0
  awk -F= -v k="$key" '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1)
      if ($1 == k) {
        val = $2
        for (i = 3; i <= NF; i++) val = val "=" $i
        sub(/^[[:space:]]+/, "", val)
        sub(/[[:space:]]+$/, "", val)
        print val
        exit
      }
    }
  ' "$file"
}

# ── Resolution chain ─────────────────────────────────────────────────────────
# cqr_resolve <KEY> [default]
# Priority: env var → answers file → upstream extracts → default. Echoes the
# resolved value, or empty if none and no default.
cqr_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  # 1) Env var named exactly $key
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) Answers file
  if [ -n "${CQR_ANSWERS:-}" ] && [ -f "${CQR_ANSWERS}" ]; then
    val=$(cqr_read_extract "${CQR_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  # 3) Upstream extracts (first match wins)
  local f
  for f in ${CQR_UPSTREAM_EXTRACTS[@]+"${CQR_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(cqr_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  # 4) Default
  printf '%s' "$default"
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# cqr_add_debt_auto <area> <title> <description> <impact>
# Maps the standard 4-arg (area/title/description/impact) shape onto CQR's
# native cqr_add_debt(title, description, severity, effort) signature.
cqr_add_debt_auto() {
  local area="$1" title="$2" description="$3" impact="$4"
  cqr_add_debt "[${area}] ${title}" "${description} — Impact: ${impact}" "Major" "M"
}

# ── Unified getters (interactive + auto) ─────────────────────────────────────
# cqr_get <KEY> <prompt> [default]
cqr_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(cqr_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if cqr_is_auto; then
    if [ -z "$default" ]; then
      cqr_add_debt_auto "Auto-resolve" "Missing answer: $key" \
        "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
        "Downstream output for this field will be blank"
    fi
    printf '%s' "$default"
    return 0
  fi
  # Interactive fallback
  if [ -n "$default" ]; then
    printf '  (default: %s — press Enter to accept)\n' "$default" >&2
  fi
  val=$(cqr_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

# cqr_get_yn <KEY> <prompt> [default_yes_or_no]
cqr_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(cqr_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if cqr_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    cqr_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  cqr_ask_yn "$prompt"
}

# cqr_get_choice <KEY> <prompt> <opt1> <opt2> ...
# Auto mode: match resolved value (exact or prefix) against options; if no
# match, first option is used and a debt is logged.
cqr_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(cqr_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if cqr_is_auto; then
      cqr_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' does not match any known option" \
        "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if cqr_is_auto; then
    cqr_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode" \
      "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  cqr_ask_choice "$prompt" "${options[@]}"
}

# ── Extract-file writer ──────────────────────────────────────────────────────
# cqr_write_extract <output_path> <KEY1=VAL1> <KEY2=VAL2> ...
# Writes a machine-readable companion file alongside the markdown output so
# downstream agents can read structured answers without re-parsing markdown.
cqr_write_extract() {
  local out="$1"; shift
  local parent
  parent=$(dirname "$out")
  [ -d "$parent" ] || mkdir -p "$parent"
  {
    printf '# Auto-generated extract — KEY=VALUE per line. Edit with care.\n'
    printf '# Generated: %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    local kv
    for kv in "$@"; do
      printf '%s\n' "$kv"
    done
  } > "$out"
}

# ── End of auto-mode helpers ─────────────────────────────────────────────────


# Auto-short-circuit added by IMPROVEMENT-PLAN Step 3A
_cqr_ask_orig()        { true; }   # placeholder, replaced below
_cqr_ask_yn_orig()     { true; }
_cqr_ask_choice_orig() { true; }
# Capture originals once, then replace with auto-aware wrappers.
if ! declare -f _cqr_ask_orig_real >/dev/null 2>&1 && declare -f cqr_ask >/dev/null 2>&1; then
  eval "_cqr_ask_orig_real()        $(declare -f cqr_ask | sed '1d')"
  eval "_cqr_ask_yn_orig_real()     $(declare -f cqr_ask_yn | sed '1d')"
  eval "_cqr_ask_choice_orig_real() $(declare -f cqr_ask_choice | sed '1d')"

  cqr_ask() {
    if cqr_is_auto; then printf ''; return 0; fi
    _cqr_ask_orig_real "$@"
  }
  cqr_ask_yn() {
    if cqr_is_auto; then printf 'no'; return 0; fi
    _cqr_ask_yn_orig_real "$@"
  }
  cqr_ask_choice() {
    if cqr_is_auto; then
      # Auto mode: return the first option
      local prompt="$1"; shift
      printf '%s' "${1:-}"
      return 0
    fi
    _cqr_ask_choice_orig_real "$@"
  }
fi


# Auto-aware cqr_confirm_save
if declare -f cqr_confirm_save >/dev/null 2>&1; then
  eval "_cqr_confirm_save_orig_real() $(declare -f cqr_confirm_save | sed '1d')"
  cqr_confirm_save() {
    if cqr_is_auto; then
      # In auto mode, auto-confirm (skip redo loops).
      printf 'yes'
      return 0
    fi
    _cqr_confirm_save_orig_real "$@"
  }
fi
