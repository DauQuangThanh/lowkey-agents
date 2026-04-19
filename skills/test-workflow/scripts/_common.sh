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
#   - Respects $TEST_OUTPUT_DIR, falls back to ./test-output
#   - Consistent TQDEBT numbering across all skills (reads existing count)
#   - Shared tst_ask / tst_ask_yn / tst_ask_choice / tst_confirm_save helpers
# =============================================================================

# ── Bash version guard ────────────────────────────────────────────────────────
# We require at least Bash 3.2 (default on macOS). Anything older will fail
# on basic arrays. Bash 4+ syntax (${var,,}) is explicitly avoided.
if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
  echo "ERROR: Bash 3.2 or later is required." >&2
  echo "       Current: ${BASH_VERSION:-unknown}" >&2
  exit 1
fi

# ── Colours ──────────────────────────────────────────────────────────────────
TST_RED='\033[0;31m'; TST_GREEN='\033[0;32m'; TST_YELLOW='\033[1;33m'
TST_BLUE='\033[0;34m'; TST_CYAN='\033[0;36m'; TST_MAGENTA='\033[0;35m'
TST_BOLD='\033[1m'; TST_DIM='\033[2m'; TST_NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
# OUTPUT_DIR may be overridden via TEST_OUTPUT_DIR env var; defaults to $PWD/test-output.
TEST_OUTPUT_DIR="${TEST_OUTPUT_DIR:-$(pwd)/test-output}"
TST_DEBT_FILE="$TEST_OUTPUT_DIR/05-test-debts.md"
mkdir -p "$TEST_OUTPUT_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────

# to_lower: Bash 3.2-compatible lowercase conversion (avoids ${var,,}).
to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# tst_ask <prompt>: prints prompt, reads a single line, echoes the trimmed answer.
tst_ask() {
  local prompt="$1" answer
  printf '%b▶ %s%b\n' "$TST_YELLOW" "$prompt" "$TST_NC" >&2
  IFS= read -r answer
  # Trim leading/trailing whitespace without bashisms.
  answer="$(printf '%s' "$answer" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$answer"
}

# tst_ask_yn <prompt>: echoes "yes" or "no". Loops until user gives y/n.
tst_ask_yn() {
  local prompt="$1" raw norm
  while true; do
    printf '%b▶ %s (y/n): %b\n' "$TST_YELLOW" "$prompt" "$TST_NC" >&2
    IFS= read -r raw
    norm="$(to_lower "$raw")"
    case "$norm" in
      y|yes) printf '%s' "yes"; return 0 ;;
      n|no)  printf '%s' "no";  return 0 ;;
      *)     printf '%b  Please type y or n.%b\n' "$TST_RED" "$TST_NC" >&2 ;;
    esac
  done
}

# tst_ask_choice <prompt> <option1> <option2> ...: echoes the chosen option string.
tst_ask_choice() {
  local prompt="$1"; shift
  local options=("$@")
  local i choice total="${#options[@]}"

  printf '%b▶ %s%b\n' "$TST_YELLOW" "$prompt" "$TST_NC" >&2
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
    printf '%b  Please enter a number between 1 and %d.%b\n' "$TST_RED" "$total" "$TST_NC" >&2
  done
}

# tst_confirm_save <prompt>: y/n, returns 0 if user said y (save), 1 if n (redo).
tst_confirm_save() {
  local answer
  answer=$(tst_ask_yn "$1")
  [ "$answer" = "yes" ]
}

# tst_current_debt_count: echoes the current number of TQDEBT-NN entries in the
# shared debt file. Used to give new debts a continuous ID across skills.
tst_current_debt_count() {
  if [ -f "$TST_DEBT_FILE" ]; then
    local n
    n=$(grep -c '^## TQDEBT-' "$TST_DEBT_FILE" 2>/dev/null || printf '0')
    # Handle the multi-line fallback from some `grep` variants.
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
    printf '%d' "$n"
  else
    printf '0'
  fi
}

# tst_add_debt <area> <title> <description> <impact>
# Appends a new debt with the next sequential ID to the shared debt file.
# Default Priority = 🟡 Important, Owner = TBD, Status = Open, Target = TBD.
tst_add_debt() {
  local area="$1" title="$2" desc="$3" impact="$4"
  local current next id
  current=$(tst_current_debt_count)
  next=$((current + 1))
  id=$(printf '%02d' "$next")

  {
    printf '\n'
    printf '## TQDEBT-%s: %s\n' "$id" "$title"
    printf '**Area:** %s\n' "$area"
    printf '**Description:** %s\n' "$desc"
    printf '**Impact:** %s\n' "$impact"
    printf '**Owner:** TBD\n'
    printf '**Priority:** 🟡 Important\n'
    printf '**Target Date:** TBD\n'
    printf '**Status:** Open\n'
    printf '\n'
  } >> "$TST_DEBT_FILE"
}

# tst_banner <line1> <line2>: prints a two-line boxed banner.
tst_banner() {
  printf '\n'
  printf '%b╔══════════════════════════════════════════════════════════╗%b\n' "$TST_CYAN$TST_BOLD" "$TST_NC"
  printf '%b║  %-56s║%b\n' "$TST_CYAN$TST_BOLD" "$1" "$TST_NC"
  printf '%b╚══════════════════════════════════════════════════════════╝%b\n' "$TST_CYAN$TST_BOLD" "$TST_NC"
  printf '\n'
}

# tst_success_rule <text>: green horizontal rule.
tst_success_rule() {
  printf '\n'
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$TST_GREEN$TST_BOLD" "$TST_NC"
  printf '%b  %s%b\n' "$TST_GREEN$TST_BOLD" "$1" "$TST_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$TST_GREEN$TST_BOLD" "$TST_NC"
  printf '\n'
}

# tst_dim <text>: prints in dim grey.
tst_dim() { printf '%b%s%b\n' "$TST_DIM" "$1" "$TST_NC"; }

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1
#
# Adds a dual-mode (interactive + non-interactive/auto) layer on top of the
# existing tst_ask / _ask_yn / _ask_choice / _add_debt helpers. Scripts
# that want auto support call tst_get / _get_yn / _get_choice with a
# stable KEY and pick up values from (in priority order):
#
#   1. an environment variable named $KEY
#   2. the --answers <file> (KEY=VALUE pairs)
#   3. any configured upstream extract files
#   4. the documented default
#   5. interactive prompt — only when not in auto mode
#
# Activation: pass --auto on the CLI (via tst_parse_flags "$@") or set
# TEST_AUTO=1 in the environment. See IMPROVEMENT-PLAN.md for the full
# contract.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
: "${TEST_AUTO:=0}"; export TEST_AUTO
: "${TEST_ANSWERS:=}"; export TEST_ANSWERS

# Upstream-extract search paths. Agents that read upstream output should
# append to this array from their phase scripts, e.g.:
#   CQR_UPSTREAM_EXTRACTS+=("$DEV_OUTPUT_DIR/02-coding-plan.extract")
if [ -z "${TEST_UPSTREAM_EXTRACTS+x}" ]; then
  TEST_UPSTREAM_EXTRACTS=()
fi

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts should call:  tst_parse_flags "$@"
# Recognised: --auto, --answers <file>, --answers=<file>. Unknown flags are
# ignored so the helper composes with scripts that have their own arg parsing.
tst_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)        TEST_AUTO=1; export TEST_AUTO; shift ;;
      --answers)     TEST_ANSWERS="${2:-}"; export TEST_ANSWERS; shift 2 ;;
      --answers=*)   TEST_ANSWERS="${1#--answers=}"; export TEST_ANSWERS; shift ;;
      *)             shift ;;
    esac
  done
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
tst_is_auto() {
  case "${TEST_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Extract-file reader ──────────────────────────────────────────────────────
# Reads KEY=VALUE pairs (one per line, `#` comments allowed) from the given
# file. Echoes the value for the requested key, or empty.
tst_read_extract() {
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
# tst_resolve <KEY> [default]
# Priority: env var → answers file → upstream extracts → default. Echoes the
# resolved value, or empty if none and no default.
tst_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  # 1) Env var named exactly $key
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) Answers file
  if [ -n "${TEST_ANSWERS:-}" ] && [ -f "${TEST_ANSWERS}" ]; then
    val=$(tst_read_extract "${TEST_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  # 3) Upstream extracts (first match wins)
  local f
  for f in ${TEST_UPSTREAM_EXTRACTS[@]+"${TEST_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(tst_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  # 4) Default
  printf '%s' "$default"
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# tst_add_debt_auto <area> <title> <description> <impact>
# Thin wrapper over the existing tst_add_debt so auto-resolved gaps use
# the agent's normal debt format. Agents with non-standard _add_debt
# signatures (cqr, re) override this below in their canonical _common.sh.
tst_add_debt_auto() {
  tst_add_debt "$@"
}

# ── Unified getters (interactive + auto) ─────────────────────────────────────
# tst_get <KEY> <prompt> [default]
tst_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(tst_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if tst_is_auto; then
    if [ -z "$default" ]; then
      tst_add_debt_auto "Auto-resolve" "Missing answer: $key" \
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
  val=$(tst_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

# tst_get_yn <KEY> <prompt> [default_yes_or_no]
tst_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(tst_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if tst_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    tst_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  tst_ask_yn "$prompt"
}

# tst_get_choice <KEY> <prompt> <opt1> <opt2> ...
# Auto mode: match resolved value (exact or prefix) against options; if no
# match, first option is used and a debt is logged.
tst_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(tst_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if tst_is_auto; then
      tst_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' does not match any known option" \
        "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if tst_is_auto; then
    tst_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode" \
      "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  tst_ask_choice "$prompt" "${options[@]}"
}

# ── Extract-file writer ──────────────────────────────────────────────────────
# tst_write_extract <output_path> <KEY1=VAL1> <KEY2=VAL2> ...
# Writes a machine-readable companion file alongside the markdown output so
# downstream agents can read structured answers without re-parsing markdown.
tst_write_extract() {
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
_tst_ask_orig()        { true; }   # placeholder, replaced below
_tst_ask_yn_orig()     { true; }
_tst_ask_choice_orig() { true; }
# Capture originals once, then replace with auto-aware wrappers.
if ! declare -f _tst_ask_orig_real >/dev/null 2>&1 && declare -f tst_ask >/dev/null 2>&1; then
  eval "_tst_ask_orig_real()        $(declare -f tst_ask | sed '1d')"
  eval "_tst_ask_yn_orig_real()     $(declare -f tst_ask_yn | sed '1d')"
  eval "_tst_ask_choice_orig_real() $(declare -f tst_ask_choice | sed '1d')"

  tst_ask() {
    if tst_is_auto; then printf ''; return 0; fi
    _tst_ask_orig_real "$@"
  }
  tst_ask_yn() {
    if tst_is_auto; then printf 'no'; return 0; fi
    _tst_ask_yn_orig_real "$@"
  }
  tst_ask_choice() {
    if tst_is_auto; then
      # Auto mode: return the first option
      local prompt="$1"; shift
      printf '%s' "${1:-}"
      return 0
    fi
    _tst_ask_choice_orig_real "$@"
  }
fi


# Auto-aware tst_confirm_save
if declare -f tst_confirm_save >/dev/null 2>&1; then
  eval "_tst_confirm_save_orig_real() $(declare -f tst_confirm_save | sed '1d')"
  tst_confirm_save() {
    if tst_is_auto; then
      # In auto mode, auto-confirm (skip redo loops).
      printf 'yes'
      return 0
    fi
    _tst_confirm_save_orig_real "$@"
  }
fi
