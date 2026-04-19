#!/bin/bash
# =============================================================================
# _common.sh — Shared helpers for Scrum Master skills.
#
# SOURCING (from a sibling script in the same scripts/ folder):
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/_common.sh"
#
# Features:
#   - Bash 3.2+ compatible (works on macOS default shell)
#   - Respects $SM_OUTPUT_DIR, falls back to ./sm-output
#   - Consistent SMDEBT numbering across all skills
#   - Shared ask / ask_yn / ask_choice / add_debt helpers
# =============================================================================

# ── Bash version guard ────────────────────────────────────────────────────────
if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
  echo "ERROR: Bash 3.2 or later is required." >&2
  echo "       Current: ${BASH_VERSION:-unknown}" >&2
  exit 1
fi

# ── Colours ──────────────────────────────────────────────────────────────────
SM_YELLOW='\033[1;33m'; SM_RED='\033[0;31m'; SM_GREEN='\033[0;32m'
SM_BLUE='\033[0;34m'; SM_CYAN='\033[0;36m'; SM_MAGENTA='\033[0;35m'
SM_BOLD='\033[1m'; SM_DIM='\033[2m'; SM_NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
SM_OUTPUT_DIR="${SM_OUTPUT_DIR:-$(pwd)/sm-output}"
SM_DEBT_FILE="$SM_OUTPUT_DIR/06-sm-debts.md"
mkdir -p "$SM_OUTPUT_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────

# to_lower: Bash 3.2-compatible lowercase conversion.
to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# sm_ask <prompt>: prints prompt, reads a single line, echoes the trimmed answer.
sm_ask() {
  local prompt="$1" answer
  printf '%b▶ %s%b\n' "$SM_YELLOW" "$prompt" "$SM_NC" >&2
  IFS= read -r answer
  answer="$(printf '%s' "$answer" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$answer"
}

# sm_ask_yn <prompt>: echoes "yes" or "no". Loops until user gives y/n.
sm_ask_yn() {
  local prompt="$1" raw norm
  while true; do
    printf '%b▶ %s (y/n): %b\n' "$SM_YELLOW" "$prompt" "$SM_NC" >&2
    IFS= read -r raw
    norm="$(to_lower "$raw")"
    case "$norm" in
      y|yes) printf '%s' "yes"; return 0 ;;
      n|no)  printf '%s' "no";  return 0 ;;
      *)     printf '%b  Please type y or n.%b\n' "$SM_RED" "$SM_NC" >&2 ;;
    esac
  done
}

# sm_ask_choice <prompt> <option1> <option2> ...: echoes the chosen option string.
sm_ask_choice() {
  local prompt="$1"; shift
  local options=("$@")
  local i choice total="${#options[@]}"

  printf '%b▶ %s%b\n' "$SM_YELLOW" "$prompt" "$SM_NC" >&2
  for ((i=0; i<total; i++)); do
    printf '  %d) %s\n' "$((i+1))" "${options[$i]}"
  done
  while true; do
    IFS= read -r choice
    case "$choice" in
      ''|*[!0-9]*) ;; # not a number
      *)
        if [ "$choice" -ge 1 ] && [ "$choice" -le "$total" ]; then
          printf '%s' "${options[$((choice-1))]}"
          return 0
        fi
        ;;
    esac
    printf '%b  Please enter a number between 1 and %d.%b\n' "$SM_RED" "$total" "$SM_NC" >&2
  done
}

# sm_confirm_save <prompt>: y/n, returns 0 if user said y (save), 1 if n (redo).
sm_confirm_save() {
  local answer
  answer=$(sm_ask_yn "$1")
  [ "$answer" = "yes" ]
}

# sm_current_debt_count: echoes the current number of SMDEBT-NN entries.
sm_current_debt_count() {
  if [ -f "$SM_DEBT_FILE" ]; then
    local n
    n=$(grep -c '^## SMDEBT-' "$SM_DEBT_FILE" 2>/dev/null || printf '0')
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
    printf '%d' "$n"
  else
    printf '0'
  fi
}

# sm_add_debt <area> <title> <description> <impact>
# Appends a new debt with the next sequential ID to the shared debt file.
sm_add_debt() {
  local area="$1" title="$2" desc="$3" impact="$4"
  local current next id
  current=$(sm_current_debt_count)
  next=$((current + 1))
  id=$(printf '%02d' "$next")

  {
    printf '\n'
    printf '## SMDEBT-%s: %s\n' "$id" "$title"
    printf '**Area:** %s\n' "$area"
    printf '**Description:** %s\n' "$desc"
    printf '**Impact:** %s\n' "$impact"
    printf '**Owner:** TBD\n'
    printf '**Priority:** 🟡 Important\n'
    printf '**Target Date:** TBD\n'
    printf '**Status:** Open\n'
    printf '\n'
  } >> "$SM_DEBT_FILE"
}

# sm_banner <text>: prints a two-line boxed banner.
sm_banner() {
  printf '\n'
  printf '%b╔══════════════════════════════════════════════════════════╗%b\n' "$SM_YELLOW$SM_BOLD" "$SM_NC"
  printf '%b║  %-56s║%b\n' "$SM_YELLOW$SM_BOLD" "$1" "$SM_NC"
  printf '%b╚══════════════════════════════════════════════════════════╝%b\n' "$SM_YELLOW$SM_BOLD" "$SM_NC"
  printf '\n'
}

# sm_success_rule <text>: green horizontal rule.
sm_success_rule() {
  printf '\n'
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$SM_GREEN$SM_BOLD" "$SM_NC"
  printf '%b  %s%b\n' "$SM_GREEN$SM_BOLD" "$1" "$SM_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$SM_GREEN$SM_BOLD" "$SM_NC"
  printf '\n'
}

# sm_dim <text>: prints in dim grey.
sm_dim() { printf '%b%s%b\n' "$SM_DIM" "$1" "$SM_NC"; }

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1
#
# Adds a dual-mode (interactive + non-interactive/auto) layer on top of the
# existing sm_ask / _ask_yn / _ask_choice / _add_debt helpers. Scripts
# that want auto support call sm_get / _get_yn / _get_choice with a
# stable KEY and pick up values from (in priority order):
#
#   1. an environment variable named $KEY
#   2. the --answers <file> (KEY=VALUE pairs)
#   3. any configured upstream extract files
#   4. the documented default
#   5. interactive prompt — only when not in auto mode
#
# Activation: pass --auto on the CLI (via sm_parse_flags "$@") or set
# SM_AUTO=1 in the environment. See IMPROVEMENT-PLAN.md for the full
# contract.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
: "${SM_AUTO:=0}"; export SM_AUTO
: "${SM_ANSWERS:=}"; export SM_ANSWERS

# Upstream-extract search paths. Agents that read upstream output should
# append to this array from their phase scripts, e.g.:
#   CQR_UPSTREAM_EXTRACTS+=("$DEV_OUTPUT_DIR/02-coding-plan.extract")
if [ -z "${SM_UPSTREAM_EXTRACTS+x}" ]; then
  SM_UPSTREAM_EXTRACTS=()
fi

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts should call:  sm_parse_flags "$@"
# Recognised: --auto, --answers <file>, --answers=<file>. Unknown flags are
# ignored so the helper composes with scripts that have their own arg parsing.
sm_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)        SM_AUTO=1; export SM_AUTO; shift ;;
      --answers)     SM_ANSWERS="${2:-}"; export SM_ANSWERS; shift 2 ;;
      --answers=*)   SM_ANSWERS="${1#--answers=}"; export SM_ANSWERS; shift ;;
      *)             shift ;;
    esac
  done
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
sm_is_auto() {
  case "${SM_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Extract-file reader ──────────────────────────────────────────────────────
# Reads KEY=VALUE pairs (one per line, `#` comments allowed) from the given
# file. Echoes the value for the requested key, or empty.
sm_read_extract() {
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
# sm_resolve <KEY> [default]
# Priority: env var → answers file → upstream extracts → default. Echoes the
# resolved value, or empty if none and no default.
sm_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  # 1) Env var named exactly $key
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) Answers file
  if [ -n "${SM_ANSWERS:-}" ] && [ -f "${SM_ANSWERS}" ]; then
    val=$(sm_read_extract "${SM_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  # 3) Upstream extracts (first match wins)
  local f
  for f in ${SM_UPSTREAM_EXTRACTS[@]+"${SM_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(sm_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  # 4) Default
  printf '%s' "$default"
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# sm_add_debt_auto <area> <title> <description> <impact>
# Thin wrapper over the existing sm_add_debt so auto-resolved gaps use
# the agent's normal debt format. Agents with non-standard _add_debt
# signatures (cqr, re) override this below in their canonical _common.sh.
sm_add_debt_auto() {
  sm_add_debt "$@"
}

# ── Unified getters (interactive + auto) ─────────────────────────────────────
# sm_get <KEY> <prompt> [default]
sm_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(sm_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if sm_is_auto; then
    if [ -z "$default" ]; then
      sm_add_debt_auto "Auto-resolve" "Missing answer: $key" \
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
  val=$(sm_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

# sm_get_yn <KEY> <prompt> [default_yes_or_no]
sm_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(sm_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if sm_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    sm_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  sm_ask_yn "$prompt"
}

# sm_get_choice <KEY> <prompt> <opt1> <opt2> ...
# Auto mode: match resolved value (exact or prefix) against options; if no
# match, first option is used and a debt is logged.
sm_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(sm_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if sm_is_auto; then
      sm_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' does not match any known option" \
        "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if sm_is_auto; then
    sm_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode" \
      "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  sm_ask_choice "$prompt" "${options[@]}"
}

# ── Extract-file writer ──────────────────────────────────────────────────────
# sm_write_extract <output_path> <KEY1=VAL1> <KEY2=VAL2> ...
# Writes a machine-readable companion file alongside the markdown output so
# downstream agents can read structured answers without re-parsing markdown.
sm_write_extract() {
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
_sm_ask_orig()        { true; }   # placeholder, replaced below
_sm_ask_yn_orig()     { true; }
_sm_ask_choice_orig() { true; }
# Capture originals once, then replace with auto-aware wrappers.
if ! declare -f _sm_ask_orig_real >/dev/null 2>&1 && declare -f sm_ask >/dev/null 2>&1; then
  eval "_sm_ask_orig_real()        $(declare -f sm_ask | sed '1d')"
  eval "_sm_ask_yn_orig_real()     $(declare -f sm_ask_yn | sed '1d')"
  eval "_sm_ask_choice_orig_real() $(declare -f sm_ask_choice | sed '1d')"

  sm_ask() {
    if sm_is_auto; then printf ''; return 0; fi
    _sm_ask_orig_real "$@"
  }
  sm_ask_yn() {
    if sm_is_auto; then printf 'no'; return 0; fi
    _sm_ask_yn_orig_real "$@"
  }
  sm_ask_choice() {
    if sm_is_auto; then
      # Auto mode: return the first option
      local prompt="$1"; shift
      printf '%s' "${1:-}"
      return 0
    fi
    _sm_ask_choice_orig_real "$@"
  }
fi


# Auto-aware sm_confirm_save
if declare -f sm_confirm_save >/dev/null 2>&1; then
  eval "_sm_confirm_save_orig_real() $(declare -f sm_confirm_save | sed '1d')"
  sm_confirm_save() {
    if sm_is_auto; then
      # In auto mode, auto-confirm (skip redo loops).
      printf 'yes'
      return 0
    fi
    _sm_confirm_save_orig_real "$@"
  }
fi
