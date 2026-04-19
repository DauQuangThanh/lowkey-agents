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
#   - Respects $DEV_OUTPUT_DIR, falls back to ./dev-output
#   - Continuous DDEBT numbering across all developer skills
#   - Shared dev_ask / dev_ask_yn / dev_ask_choice / dev_add_ddebt helpers
# =============================================================================

# ── Bash version guard ────────────────────────────────────────────────────────
if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
  echo "ERROR: Bash 3.2 or later is required." >&2
  echo "       Current: ${BASH_VERSION:-unknown}" >&2
  exit 1
fi

# ── Colours (DEV_ prefix for green theme) ─────────────────────────────────────
DEV_RED='\033[0;31m'; DEV_GREEN='\033[0;32m'; DEV_YELLOW='\033[1;33m'
DEV_BLUE='\033[0;34m'; DEV_CYAN='\033[0;36m'; DEV_ORANGE='\033[0;33m'
DEV_BOLD='\033[1m'; DEV_DIM='\033[2m'; DEV_NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
DEV_OUTPUT_DIR="${DEV_OUTPUT_DIR:-$(pwd)/dev-output}"
DEV_ARCH_INPUT_DIR="${DEV_ARCH_INPUT_DIR:-$(pwd)/arch-output}"
DEV_BA_INPUT_DIR="${DEV_BA_INPUT_DIR:-$(pwd)/ba-output}"
DEV_DEBT_FILE="$DEV_OUTPUT_DIR/05-design-debts.md"
mkdir -p "$DEV_OUTPUT_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────

# to_lower: Bash 3.2-compatible lowercase conversion.
to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# slugify: lowercase, replace non-alphanum with hyphens, collapse.
dev_slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]/-/g' -e 's/-\{1,\}/-/g' -e 's/^-//' -e 's/-$//'
}

dev_ask() {
  local prompt="$1" answer
  printf '%b▶ %s%b\n' "$DEV_YELLOW" "$prompt" "$DEV_NC" >&2
  IFS= read -r answer
  answer="$(printf '%s' "$answer" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$answer"
}

dev_ask_yn() {
  local prompt="$1" raw norm
  while true; do
    printf '%b▶ %s (y/n): %b\n' "$DEV_YELLOW" "$prompt" "$DEV_NC" >&2
    IFS= read -r raw
    norm="$(to_lower "$raw")"
    case "$norm" in
      y|yes) printf '%s' "yes"; return 0 ;;
      n|no)  printf '%s' "no";  return 0 ;;
      *)     printf '%b  Please type y or n.%b\n' "$DEV_RED" "$DEV_NC" >&2 ;;
    esac
  done
}

dev_ask_choice() {
  local prompt="$1"; shift
  local options=("$@")
  local i choice total="${#options[@]}"
  printf '%b▶ %s%b\n' "$DEV_YELLOW" "$prompt" "$DEV_NC" >&2
  for ((i=0; i<total; i++)); do
    printf '  %d) %s\n' "$((i+1))" "${options[$i]}"
  done
  while true; do
    IFS= read -r choice
    case "$choice" in
      ''|*[!0-9]*) ;;
      *)
        if [ "$choice" -ge 1 ] && [ "$choice" -le "$total" ]; then
          printf '%s' "${options[$((choice-1))]}"
          return 0
        fi
        ;;
    esac
    printf '%b  Please enter a number between 1 and %d.%b\n' "$DEV_RED" "$total" "$DEV_NC" >&2
  done
}

dev_confirm_save() {
  local answer
  answer=$(dev_ask_yn "$1")
  [ "$answer" = "yes" ]
}

dev_current_ddebt_count() {
  if [ -f "$DEV_DEBT_FILE" ]; then
    local n
    n=$(grep -c '^## DDEBT-' "$DEV_DEBT_FILE" 2>/dev/null || printf '0')
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
    printf '%d' "$n"
  else
    printf '0'
  fi
}

# dev_add_ddebt <area> <title> <description> <impact>
dev_add_ddebt() {
  local area="$1" title="$2" desc="$3" impact="$4"
  local current next id
  current=$(dev_current_ddebt_count)
  next=$((current + 1))
  id=$(printf '%02d' "$next")

  {
    printf '\n'
    printf '## DDEBT-%s: %s\n' "$id" "$title"
    printf '**Area:** %s\n' "$area"
    printf '**Description:** %s\n' "$desc"
    printf '**Impact:** %s\n' "$impact"
    printf '**Owner:** TBD\n'
    printf '**Priority:** 🟡 Important\n'
    printf '**Target Date:** TBD\n'
    printf '**Linked:** TBD\n'
    printf '**Status:** Open\n'
    printf '\n'
  } >> "$DEV_DEBT_FILE"
}

dev_banner() {
  printf '\n'
  printf '%b╔══════════════════════════════════════════════════════════╗%b\n' "$DEV_ORANGE$DEV_BOLD" "$DEV_NC"
  printf '%b║  %-56s║%b\n' "$DEV_ORANGE$DEV_BOLD" "$1" "$DEV_NC"
  printf '%b╚══════════════════════════════════════════════════════════╝%b\n' "$DEV_ORANGE$DEV_BOLD" "$DEV_NC"
  printf '\n'
}

dev_success_rule() {
  printf '\n'
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$DEV_GREEN$DEV_BOLD" "$DEV_NC"
  printf '%b  %s%b\n' "$DEV_GREEN$DEV_BOLD" "$1" "$DEV_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$DEV_GREEN$DEV_BOLD" "$DEV_NC"
  printf '\n'
}

dev_dim() { printf '%b%s%b\n' "$DEV_DIM" "$1" "$DEV_NC"; }

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1
#
# Adds a dual-mode (interactive + non-interactive/auto) layer on top of the
# existing dev_ask / _ask_yn / _ask_choice / _add_debt helpers. Scripts
# that want auto support call dev_get / _get_yn / _get_choice with a
# stable KEY and pick up values from (in priority order):
#
#   1. an environment variable named $KEY
#   2. the --answers <file> (KEY=VALUE pairs)
#   3. any configured upstream extract files
#   4. the documented default
#   5. interactive prompt — only when not in auto mode
#
# Activation: pass --auto on the CLI (via dev_parse_flags "$@") or set
# DEV_AUTO=1 in the environment. See IMPROVEMENT-PLAN.md for the full
# contract.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
: "${DEV_AUTO:=0}"; export DEV_AUTO
: "${DEV_ANSWERS:=}"; export DEV_ANSWERS

# Upstream-extract search paths. Agents that read upstream output should
# append to this array from their phase scripts, e.g.:
#   CQR_UPSTREAM_EXTRACTS+=("$DEV_OUTPUT_DIR/02-coding-plan.extract")
if [ -z "${DEV_UPSTREAM_EXTRACTS+x}" ]; then
  DEV_UPSTREAM_EXTRACTS=()
fi

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts should call:  dev_parse_flags "$@"
# Recognised: --auto, --answers <file>, --answers=<file>. Unknown flags are
# ignored so the helper composes with scripts that have their own arg parsing.
dev_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)        DEV_AUTO=1; export DEV_AUTO; shift ;;
      --answers)     DEV_ANSWERS="${2:-}"; export DEV_ANSWERS; shift 2 ;;
      --answers=*)   DEV_ANSWERS="${1#--answers=}"; export DEV_ANSWERS; shift ;;
      *)             shift ;;
    esac
  done
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
dev_is_auto() {
  case "${DEV_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Extract-file reader ──────────────────────────────────────────────────────
# Reads KEY=VALUE pairs (one per line, `#` comments allowed) from the given
# file. Echoes the value for the requested key, or empty.
dev_read_extract() {
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
# dev_resolve <KEY> [default]
# Priority: env var → answers file → upstream extracts → default. Echoes the
# resolved value, or empty if none and no default.
dev_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  # 1) Env var named exactly $key
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) Answers file
  if [ -n "${DEV_ANSWERS:-}" ] && [ -f "${DEV_ANSWERS}" ]; then
    val=$(dev_read_extract "${DEV_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  # 3) Upstream extracts (first match wins)
  local f
  for f in ${DEV_UPSTREAM_EXTRACTS[@]+"${DEV_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(dev_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  # 4) Default
  printf '%s' "$default"
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# dev_add_debt_auto <area> <title> <description> <impact>
# Thin wrapper over the existing dev_add_debt so auto-resolved gaps use
# the agent's normal debt format. Agents with non-standard _add_debt
# signatures (cqr, re) override this below in their canonical _common.sh.
dev_add_debt_auto() {
  dev_add_debt "$@"
}

# ── Unified getters (interactive + auto) ─────────────────────────────────────
# dev_get <KEY> <prompt> [default]
dev_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(dev_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if dev_is_auto; then
    if [ -z "$default" ]; then
      dev_add_debt_auto "Auto-resolve" "Missing answer: $key" \
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
  val=$(dev_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

# dev_get_yn <KEY> <prompt> [default_yes_or_no]
dev_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(dev_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if dev_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    dev_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  dev_ask_yn "$prompt"
}

# dev_get_choice <KEY> <prompt> <opt1> <opt2> ...
# Auto mode: match resolved value (exact or prefix) against options; if no
# match, first option is used and a debt is logged.
dev_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(dev_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if dev_is_auto; then
      dev_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' does not match any known option" \
        "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if dev_is_auto; then
    dev_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode" \
      "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  dev_ask_choice "$prompt" "${options[@]}"
}

# ── Extract-file writer ──────────────────────────────────────────────────────
# dev_write_extract <output_path> <KEY1=VAL1> <KEY2=VAL2> ...
# Writes a machine-readable companion file alongside the markdown output so
# downstream agents can read structured answers without re-parsing markdown.
dev_write_extract() {
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
_dev_ask_orig()        { true; }   # placeholder, replaced below
_dev_ask_yn_orig()     { true; }
_dev_ask_choice_orig() { true; }
# Capture originals once, then replace with auto-aware wrappers.
if ! declare -f _dev_ask_orig_real >/dev/null 2>&1 && declare -f dev_ask >/dev/null 2>&1; then
  eval "_dev_ask_orig_real()        $(declare -f dev_ask | sed '1d')"
  eval "_dev_ask_yn_orig_real()     $(declare -f dev_ask_yn | sed '1d')"
  eval "_dev_ask_choice_orig_real() $(declare -f dev_ask_choice | sed '1d')"

  dev_ask() {
    if dev_is_auto; then printf ''; return 0; fi
    _dev_ask_orig_real "$@"
  }
  dev_ask_yn() {
    if dev_is_auto; then printf 'no'; return 0; fi
    _dev_ask_yn_orig_real "$@"
  }
  dev_ask_choice() {
    if dev_is_auto; then
      # Auto mode: return the first option
      local prompt="$1"; shift
      printf '%s' "${1:-}"
      return 0
    fi
    _dev_ask_choice_orig_real "$@"
  }
fi


# Auto-aware dev_confirm_save
if declare -f dev_confirm_save >/dev/null 2>&1; then
  eval "_dev_confirm_save_orig_real() $(declare -f dev_confirm_save | sed '1d')"
  dev_confirm_save() {
    if dev_is_auto; then
      # In auto mode, auto-confirm (skip redo loops).
      printf 'yes'
      return 0
    fi
    _dev_confirm_save_orig_real "$@"
  }
fi
