#!/bin/bash
# =============================================================================
# _common.sh — Shared helpers embedded inside the Product Owner skills.
#
# SOURCING (from a sibling script in the same scripts/ folder):
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/_common.sh"
#
# Features:
#   - Bash 3.2+ compatible (works on macOS default shell)
#   - Respects $PO_OUTPUT_DIR, falls back to ./po-output
#   - Consistent PODEBT numbering across all skills (reads existing count)
#   - Shared ask / ask_yn / ask_choice / add_debt helpers
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
PO_RED='\033[0;31m'; PO_GREEN='\033[0;32m'; PO_YELLOW='\033[1;33m'
PO_BLUE='\033[0;34m'; PO_CYAN='\033[0;36m'; PO_MAGENTA='\033[1;35m'
PO_BOLD='\033[1m'; PO_DIM='\033[2m'; PO_NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
# OUTPUT_DIR may be overridden via PO_OUTPUT_DIR env var; defaults to $PWD/po-output.
PO_OUTPUT_DIR="${PO_OUTPUT_DIR:-$(pwd)/po-output}"
PO_DEBT_FILE="$PO_OUTPUT_DIR/06-po-debts.md"
mkdir -p "$PO_OUTPUT_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────

# to_lower: Bash 3.2-compatible lowercase conversion (avoids ${var,,}).
to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# po_ask <prompt>: prints prompt, reads a single line, echoes the trimmed answer.
po_ask() {
  local prompt="$1" answer
  printf '%b▶ %s%b\n' "$PO_YELLOW" "$prompt" "$PO_NC" >&2
  IFS= read -r answer
  # Trim leading/trailing whitespace without bashisms.
  answer="$(printf '%s' "$answer" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$answer"
}

# po_ask_yn <prompt>: echoes "yes" or "no". Loops until user gives y/n.
po_ask_yn() {
  local prompt="$1" raw norm
  while true; do
    printf '%b▶ %s (y/n): %b\n' "$PO_YELLOW" "$prompt" "$PO_NC" >&2
    IFS= read -r raw
    norm="$(to_lower "$raw")"
    case "$norm" in
      y|yes) printf '%s' "yes"; return 0 ;;
      n|no)  printf '%s' "no";  return 0 ;;
      *)     printf '%b  Please type y or n.%b\n' "$PO_RED" "$PO_NC" >&2 ;;
    esac
  done
}

# po_ask_choice <prompt> <option1> <option2> ...: echoes the chosen option string.
po_ask_choice() {
  local prompt="$1"; shift
  local options=("$@")
  local i choice total="${#options[@]}"

  printf '%b▶ %s%b\n' "$PO_YELLOW" "$prompt" "$PO_NC" >&2
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
    printf '%b  Please enter a number between 1 and %d.%b\n' "$PO_RED" "$total" "$PO_NC" >&2
  done
}

# po_confirm_save <prompt>: y/n, returns 0 if user said y (save), 1 if n (redo).
po_confirm_save() {
  local answer
  answer=$(po_ask_yn "$1")
  [ "$answer" = "yes" ]
}

# po_current_debt_count: echoes the current number of PODEBT-NN entries in the
# shared debt file. Used to give new debts a continuous ID across skills.
po_current_debt_count() {
  if [ -f "$PO_DEBT_FILE" ]; then
    local n
    n=$(grep -c '^## PODEBT-' "$PO_DEBT_FILE" 2>/dev/null || printf '0')
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
    printf '%d' "$n"
  else
    printf '0'
  fi
}

# po_add_debt <area> <title> <description> <impact>
# Appends a new debt with the next sequential ID to the shared debt file.
# Default Priority = 🟡 Important, Owner = TBD, Status = Open, Target = TBD.
po_add_debt() {
  local area="$1" title="$2" desc="$3" impact="$4"
  local current next id
  current=$(po_current_debt_count)
  next=$((current + 1))
  id=$(printf '%02d' "$next")

  {
    printf '\n'
    printf '## PODEBT-%s: %s\n' "$id" "$title"
    printf '**Area:** %s\n' "$area"
    printf '**Description:** %s\n' "$desc"
    printf '**Impact:** %s\n' "$impact"
    printf '**Owner:** TBD\n'
    printf '**Priority:** 🟡 Important\n'
    printf '**Target Date:** TBD\n'
    printf '**Status:** Open\n'
    printf '\n'
  } >> "$PO_DEBT_FILE"
}

# po_banner <line1>: prints a boxed banner.
po_banner() {
  printf '\n'
  printf '%b╔══════════════════════════════════════════════════════════╗%b\n' "$PO_MAGENTA$PO_BOLD" "$PO_NC"
  printf '%b║  %-56s║%b\n' "$PO_MAGENTA$PO_BOLD" "$1" "$PO_NC"
  printf '%b╚══════════════════════════════════════════════════════════╝%b\n' "$PO_MAGENTA$PO_BOLD" "$PO_NC"
  printf '\n'
}

# po_success_rule <text>: green horizontal rule.
po_success_rule() {
  printf '\n'
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$PO_GREEN$PO_BOLD" "$PO_NC"
  printf '%b  %s%b\n' "$PO_GREEN$PO_BOLD" "$1" "$PO_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$PO_GREEN$PO_BOLD" "$PO_NC"
  printf '\n'
}

# po_dim <text>: prints in dim grey.
po_dim() { printf '%b%s%b\n' "$PO_DIM" "$1" "$PO_NC"; }

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1
#
# Adds a dual-mode (interactive + non-interactive/auto) layer on top of the
# existing po_ask / _ask_yn / _ask_choice / _add_debt helpers. Scripts
# that want auto support call po_get / _get_yn / _get_choice with a
# stable KEY and pick up values from (in priority order):
#
#   1. an environment variable named $KEY
#   2. the --answers <file> (KEY=VALUE pairs)
#   3. any configured upstream extract files
#   4. the documented default
#   5. interactive prompt — only when not in auto mode
#
# Activation: pass --auto on the CLI (via po_parse_flags "$@") or set
# PO_AUTO=1 in the environment. See IMPROVEMENT-PLAN.md for the full
# contract.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
: "${PO_AUTO:=0}"; export PO_AUTO
: "${PO_ANSWERS:=}"; export PO_ANSWERS

# Upstream-extract search paths. Agents that read upstream output should
# append to this array from their phase scripts, e.g.:
#   CQR_UPSTREAM_EXTRACTS+=("$DEV_OUTPUT_DIR/02-coding-plan.extract")
if [ -z "${PO_UPSTREAM_EXTRACTS+x}" ]; then
  PO_UPSTREAM_EXTRACTS=()
fi

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts should call:  po_parse_flags "$@"
# Recognised: --auto, --answers <file>, --answers=<file>. Unknown flags are
# ignored so the helper composes with scripts that have their own arg parsing.
po_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)        PO_AUTO=1; export PO_AUTO; shift ;;
      --answers)     PO_ANSWERS="${2:-}"; export PO_ANSWERS; shift 2 ;;
      --answers=*)   PO_ANSWERS="${1#--answers=}"; export PO_ANSWERS; shift ;;
      *)             shift ;;
    esac
  done
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
po_is_auto() {
  case "${PO_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Extract-file reader ──────────────────────────────────────────────────────
# Reads KEY=VALUE pairs (one per line, `#` comments allowed) from the given
# file. Echoes the value for the requested key, or empty.
po_read_extract() {
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
# po_resolve <KEY> [default]
# Priority: env var → answers file → upstream extracts → default. Echoes the
# resolved value, or empty if none and no default.
po_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  # 1) Env var named exactly $key
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) Answers file
  if [ -n "${PO_ANSWERS:-}" ] && [ -f "${PO_ANSWERS}" ]; then
    val=$(po_read_extract "${PO_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  # 3) Upstream extracts (first match wins)
  local f
  for f in ${PO_UPSTREAM_EXTRACTS[@]+"${PO_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(po_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  # 4) Default
  printf '%s' "$default"
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# po_add_debt_auto <area> <title> <description> <impact>
# Thin wrapper over the existing po_add_debt so auto-resolved gaps use
# the agent's normal debt format. Agents with non-standard _add_debt
# signatures (cqr, re) override this below in their canonical _common.sh.
po_add_debt_auto() {
  po_add_debt "$@"
}

# ── Unified getters (interactive + auto) ─────────────────────────────────────
# po_get <KEY> <prompt> [default]
po_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(po_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if po_is_auto; then
    if [ -z "$default" ]; then
      po_add_debt_auto "Auto-resolve" "Missing answer: $key" \
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
  val=$(po_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

# po_get_yn <KEY> <prompt> [default_yes_or_no]
po_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(po_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if po_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    po_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  po_ask_yn "$prompt"
}

# po_get_choice <KEY> <prompt> <opt1> <opt2> ...
# Auto mode: match resolved value (exact or prefix) against options; if no
# match, first option is used and a debt is logged.
po_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(po_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if po_is_auto; then
      po_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' does not match any known option" \
        "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if po_is_auto; then
    po_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode" \
      "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  po_ask_choice "$prompt" "${options[@]}"
}

# ── Extract-file writer ──────────────────────────────────────────────────────
# po_write_extract <output_path> <KEY1=VAL1> <KEY2=VAL2> ...
# Writes a machine-readable companion file alongside the markdown output so
# downstream agents can read structured answers without re-parsing markdown.
po_write_extract() {
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
_po_ask_orig()        { true; }   # placeholder, replaced below
_po_ask_yn_orig()     { true; }
_po_ask_choice_orig() { true; }
# Capture originals once, then replace with auto-aware wrappers.
if ! declare -f _po_ask_orig_real >/dev/null 2>&1 && declare -f po_ask >/dev/null 2>&1; then
  eval "_po_ask_orig_real()        $(declare -f po_ask | sed '1d')"
  eval "_po_ask_yn_orig_real()     $(declare -f po_ask_yn | sed '1d')"
  eval "_po_ask_choice_orig_real() $(declare -f po_ask_choice | sed '1d')"

  po_ask() {
    if po_is_auto; then printf ''; return 0; fi
    _po_ask_orig_real "$@"
  }
  po_ask_yn() {
    if po_is_auto; then printf 'no'; return 0; fi
    _po_ask_yn_orig_real "$@"
  }
  po_ask_choice() {
    if po_is_auto; then
      # Auto mode: return the first option
      local prompt="$1"; shift
      printf '%s' "${1:-}"
      return 0
    fi
    _po_ask_choice_orig_real "$@"
  }
fi


# Auto-aware po_confirm_save
if declare -f po_confirm_save >/dev/null 2>&1; then
  eval "_po_confirm_save_orig_real() $(declare -f po_confirm_save | sed '1d')"
  po_confirm_save() {
    if po_is_auto; then
      # In auto mode, auto-confirm (skip redo loops).
      printf 'yes'
      return 0
    fi
    _po_confirm_save_orig_real "$@"
  }
fi
