#!/bin/bash
# =============================================================================
# _common.sh — Shared helpers for Test Architect skills.
#
# SOURCING (from a sibling script in the same scripts/ folder):
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/_common.sh"
#
# Features:
#   - Bash 3.2+ compatible (works on macOS default shell)
#   - Respects $TA_OUTPUT_DIR, falls back to ./ta-output
#   - Continuous TADEBT numbering across all TA skills
#   - Shared ta_ask / ta_ask_yn / ta_ask_choice / ta_confirm_save helpers
# =============================================================================

# ── Bash version guard ────────────────────────────────────────────────────────
if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
  echo "ERROR: Bash 3.2 or later is required." >&2
  echo "       Current: ${BASH_VERSION:-unknown}" >&2
  exit 1
fi

# ── Colours ──────────────────────────────────────────────────────────────────
TA_RED='\033[0;31m'; TA_GREEN='\033[0;32m'; TA_YELLOW='\033[1;33m'
TA_BLUE='\033[0;34m'; TA_CYAN='\033[0;36m'; TA_MAGENTA='\033[0;35m'
TA_BOLD='\033[1m'; TA_DIM='\033[2m'; TA_NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
TA_OUTPUT_DIR="${TA_OUTPUT_DIR:-$(pwd)/ta-output}"
TA_BA_INPUT_DIR="${TA_BA_INPUT_DIR:-$(pwd)/ba-output}"
TA_ARCH_INPUT_DIR="${TA_ARCH_INPUT_DIR:-$(pwd)/arch-output}"
TA_DEBT_FILE="$TA_OUTPUT_DIR/06-ta-debts.md"
mkdir -p "$TA_OUTPUT_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

ta_ask() {
  local prompt="$1" answer
  printf '%b▶ %s%b\n' "$TA_YELLOW" "$prompt" "$TA_NC" >&2
  IFS= read -r answer
  answer="$(printf '%s' "$answer" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$answer"
}

ta_ask_yn() {
  local prompt="$1" raw norm
  while true; do
    printf '%b▶ %s (y/n): %b\n' "$TA_YELLOW" "$prompt" "$TA_NC" >&2
    IFS= read -r raw
    norm="$(to_lower "$raw")"
    case "$norm" in
      y|yes) printf '%s' "yes"; return 0 ;;
      n|no)  printf '%s' "no";  return 0 ;;
      *)     printf '%b  Please type y or n.%b\n' "$TA_RED" "$TA_NC" >&2 ;;
    esac
  done
}

ta_ask_choice() {
  local prompt="$1"; shift
  local options=("$@")
  local i choice total="${#options[@]}"
  printf '%b▶ %s%b\n' "$TA_YELLOW" "$prompt" "$TA_NC" >&2
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
    printf '%b  Please enter a number between 1 and %d.%b\n' "$TA_RED" "$total" "$TA_NC" >&2
  done
}

ta_confirm_save() {
  local answer
  answer=$(ta_ask_yn "$1")
  [ "$answer" = "yes" ]
}

ta_current_debt_count() {
  if [ -f "$TA_DEBT_FILE" ]; then
    local n
    n=$(grep -c '^## TADEBT-' "$TA_DEBT_FILE" 2>/dev/null || printf '0')
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
    printf '%d' "$n"
  else
    printf '0'
  fi
}

ta_next_debt_id() {
  local current next
  current=$(ta_current_debt_count)
  next=$((current + 1))
  printf 'TADEBT-%02d' "$next"
}

ta_add_debt() {
  local title="$1" desc="$2" impact="$3"
  local id
  id=$(ta_next_debt_id)

  {
    printf '\n'
    printf '## %s: %s\n' "$id" "$title"
    printf '**Description:** %s\n' "$desc"
    printf '**Impact:** %s\n' "$impact"
    printf '**Owner:** TBD\n'
    printf '**Priority:** 🟡 Important\n'
    printf '**Target Date:** TBD\n'
    printf '**Status:** Open\n'
    printf '\n'
  } >> "$TA_DEBT_FILE"
}

ta_banner() {
  printf '\n'
  printf '%b╔══════════════════════════════════════════════════════════╗%b\n' "$TA_CYAN$TA_BOLD" "$TA_NC"
  printf '%b║  %-56s║%b\n' "$TA_CYAN$TA_BOLD" "$1" "$TA_NC"
  printf '%b╚══════════════════════════════════════════════════════════╝%b\n' "$TA_CYAN$TA_BOLD" "$TA_NC"
  printf '\n'
}

ta_success_rule() {
  printf '\n'
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$TA_GREEN$TA_BOLD" "$TA_NC"
  printf '%b  %s%b\n' "$TA_GREEN$TA_BOLD" "$1" "$TA_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$TA_GREEN$TA_BOLD" "$TA_NC"
  printf '\n'
}

ta_dim() { printf '%b%s%b\n' "$TA_DIM" "$1" "$TA_NC"; }

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1
#
# Adds a dual-mode (interactive + non-interactive/auto) layer on top of the
# existing ta_ask / _ask_yn / _ask_choice / _add_debt helpers. Scripts
# that want auto support call ta_get / _get_yn / _get_choice with a
# stable KEY and pick up values from (in priority order):
#
#   1. an environment variable named $KEY
#   2. the --answers <file> (KEY=VALUE pairs)
#   3. any configured upstream extract files
#   4. the documented default
#   5. interactive prompt — only when not in auto mode
#
# Activation: pass --auto on the CLI (via ta_parse_flags "$@") or set
# TA_AUTO=1 in the environment. See IMPROVEMENT-PLAN.md for the full
# contract.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
: "${TA_AUTO:=0}"; export TA_AUTO
: "${TA_ANSWERS:=}"; export TA_ANSWERS

# Upstream-extract search paths. Agents that read upstream output should
# append to this array from their phase scripts, e.g.:
#   CQR_UPSTREAM_EXTRACTS+=("$DEV_OUTPUT_DIR/02-coding-plan.extract")
if [ -z "${TA_UPSTREAM_EXTRACTS+x}" ]; then
  TA_UPSTREAM_EXTRACTS=()
fi

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts should call:  ta_parse_flags "$@"
# Recognised: --auto, --answers <file>, --answers=<file>. Unknown flags are
# ignored so the helper composes with scripts that have their own arg parsing.
ta_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)        TA_AUTO=1; export TA_AUTO; shift ;;
      --answers)     TA_ANSWERS="${2:-}"; export TA_ANSWERS; shift 2 ;;
      --answers=*)   TA_ANSWERS="${1#--answers=}"; export TA_ANSWERS; shift ;;
      *)             shift ;;
    esac
  done
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
ta_is_auto() {
  case "${TA_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Extract-file reader ──────────────────────────────────────────────────────
# Reads KEY=VALUE pairs (one per line, `#` comments allowed) from the given
# file. Echoes the value for the requested key, or empty.
ta_read_extract() {
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
# ta_resolve <KEY> [default]
# Priority: env var → answers file → upstream extracts → default. Echoes the
# resolved value, or empty if none and no default.
ta_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  # 1) Env var named exactly $key
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) Answers file
  if [ -n "${TA_ANSWERS:-}" ] && [ -f "${TA_ANSWERS}" ]; then
    val=$(ta_read_extract "${TA_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  # 3) Upstream extracts (first match wins)
  local f
  for f in ${TA_UPSTREAM_EXTRACTS[@]+"${TA_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(ta_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  # 4) Default
  printf '%s' "$default"
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# ta_add_debt_auto <area> <title> <description> <impact>
# Thin wrapper over the existing ta_add_debt so auto-resolved gaps use
# the agent's normal debt format. Agents with non-standard _add_debt
# signatures (cqr, re) override this below in their canonical _common.sh.
ta_add_debt_auto() {
  ta_add_debt "$@"
}

# ── Unified getters (interactive + auto) ─────────────────────────────────────
# ta_get <KEY> <prompt> [default]
ta_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(ta_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if ta_is_auto; then
    if [ -z "$default" ]; then
      ta_add_debt_auto "Auto-resolve" "Missing answer: $key" \
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
  val=$(ta_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

# ta_get_yn <KEY> <prompt> [default_yes_or_no]
ta_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(ta_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if ta_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    ta_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  ta_ask_yn "$prompt"
}

# ta_get_choice <KEY> <prompt> <opt1> <opt2> ...
# Auto mode: match resolved value (exact or prefix) against options; if no
# match, first option is used and a debt is logged.
ta_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(ta_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if ta_is_auto; then
      ta_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' does not match any known option" \
        "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if ta_is_auto; then
    ta_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode" \
      "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  ta_ask_choice "$prompt" "${options[@]}"
}

# ── Extract-file writer ──────────────────────────────────────────────────────
# ta_write_extract <output_path> <KEY1=VAL1> <KEY2=VAL2> ...
# Writes a machine-readable companion file alongside the markdown output so
# downstream agents can read structured answers without re-parsing markdown.
ta_write_extract() {
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
_ta_ask_orig()        { true; }   # placeholder, replaced below
_ta_ask_yn_orig()     { true; }
_ta_ask_choice_orig() { true; }
# Capture originals once, then replace with auto-aware wrappers.
if ! declare -f _ta_ask_orig_real >/dev/null 2>&1 && declare -f ta_ask >/dev/null 2>&1; then
  eval "_ta_ask_orig_real()        $(declare -f ta_ask | sed '1d')"
  eval "_ta_ask_yn_orig_real()     $(declare -f ta_ask_yn | sed '1d')"
  eval "_ta_ask_choice_orig_real() $(declare -f ta_ask_choice | sed '1d')"

  ta_ask() {
    if ta_is_auto; then printf ''; return 0; fi
    _ta_ask_orig_real "$@"
  }
  ta_ask_yn() {
    if ta_is_auto; then printf 'no'; return 0; fi
    _ta_ask_yn_orig_real "$@"
  }
  ta_ask_choice() {
    if ta_is_auto; then
      # Auto mode: return the first option
      local prompt="$1"; shift
      printf '%s' "${1:-}"
      return 0
    fi
    _ta_ask_choice_orig_real "$@"
  }
fi


# Auto-aware ta_confirm_save
if declare -f ta_confirm_save >/dev/null 2>&1; then
  eval "_ta_confirm_save_orig_real() $(declare -f ta_confirm_save | sed '1d')"
  ta_confirm_save() {
    if ta_is_auto; then
      # In auto mode, auto-confirm (skip redo loops).
      printf 'yes'
      return 0
    fi
    _ta_confirm_save_orig_real "$@"
  }
fi
