#!/bin/bash
# =============================================================================
# _common.sh — Shared helpers embedded inside this UX skill.
#
# SOURCING (from a sibling script in the same scripts/ folder):
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/_common.sh"
#
# Features:
#   - Bash 3.2+ compatible (works on macOS default shell)
#   - Respects $UX_OUTPUT_DIR, falls back to ./ux-output
#   - Continuous UXDEBT numbering across all UX skills
#   - Shared ux_ask / ux_ask_yn / ux_ask_choice / ux_add_debt helpers
# =============================================================================

# ── Bash version guard ────────────────────────────────────────────────────────
if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
  echo "ERROR: Bash 3.2 or later is required." >&2
  echo "       Current: ${BASH_VERSION:-unknown}" >&2
  exit 1
fi

# ── Colours ──────────────────────────────────────────────────────────────────
UX_RED='\033[0;31m'; UX_GREEN='\033[0;32m'; UX_YELLOW='\033[1;33m'
UX_BLUE='\033[0;34m'; UX_CYAN='\033[0;36m'; UX_MAGENTA='\033[0;35m'
UX_BOLD='\033[1m'; UX_DIM='\033[2m'; UX_NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
UX_OUTPUT_DIR="${UX_OUTPUT_DIR:-$(pwd)/ux-output}"
UX_BA_INPUT_DIR="${UX_BA_INPUT_DIR:-$(pwd)/ba-output}"
UX_DEBT_FILE="$UX_OUTPUT_DIR/05-ux-debts.md"
mkdir -p "$UX_OUTPUT_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────

# to_lower: Bash 3.2-compatible lowercase conversion.
to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# slugify: lowercase, replace non-alphanum with hyphens, collapse.
ux_slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]/-/g' -e 's/-\{1,\}/-/g' -e 's/^-//' -e 's/-$//'
}

ux_ask() {
  local prompt="$1" answer
  printf '%b▶ %s%b\n' "$UX_YELLOW" "$prompt" "$UX_NC" >&2
  IFS= read -r answer
  answer="$(printf '%s' "$answer" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$answer"
}

ux_ask_yn() {
  local prompt="$1" raw norm
  while true; do
    printf '%b▶ %s (y/n): %b\n' "$UX_YELLOW" "$prompt" "$UX_NC" >&2
    IFS= read -r raw
    norm="$(to_lower "$raw")"
    case "$norm" in
      y|yes) printf '%s' "yes"; return 0 ;;
      n|no)  printf '%s' "no";  return 0 ;;
      *)     printf '%b  Please type y or n.%b\n' "$UX_RED" "$UX_NC" >&2 ;;
    esac
  done
}

ux_ask_choice() {
  local prompt="$1"; shift
  local options=("$@")
  local i choice total="${#options[@]}"
  printf '%b▶ %s%b\n' "$UX_YELLOW" "$prompt" "$UX_NC" >&2
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
    printf '%b  Please enter a number between 1 and %d.%b\n' "$UX_RED" "$total" "$UX_NC" >&2
  done
}

ux_confirm_save() {
  local answer
  answer=$(ux_ask_yn "$1")
  [ "$answer" = "yes" ]
}

ux_current_debt_count() {
  if [ -f "$UX_DEBT_FILE" ]; then
    local n
    n=$(grep -c '^## UXDEBT-' "$UX_DEBT_FILE" 2>/dev/null || printf '0')
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
    printf '%d' "$n"
  else
    printf '0'
  fi
}

# ux_add_debt <area> <title> <description> <impact>
ux_add_debt() {
  local area="$1" title="$2" desc="$3" impact="$4"
  local current next id
  current=$(ux_current_debt_count)
  next=$((current + 1))
  id=$(printf '%02d' "$next")

  {
    printf '\n'
    printf '## UXDEBT-%s: %s\n' "$id" "$title"
    printf '**Area:** %s\n' "$area"
    printf '**Description:** %s\n' "$desc"
    printf '**Impact:** %s\n' "$impact"
    printf '**Owner:** TBD\n'
    printf '**Priority:** 🟡 Important\n'
    printf '**Target Date:** TBD\n'
    printf '**Linked:** TBD\n'
    printf '**Status:** Open\n'
    printf '\n'
  } >> "$UX_DEBT_FILE"
}

ux_banner() {
  printf '\n'
  printf '%b╔══════════════════════════════════════════════════════════╗%b\n' "$UX_MAGENTA$UX_BOLD" "$UX_NC"
  printf '%b║  %-56s║%b\n' "$UX_MAGENTA$UX_BOLD" "$1" "$UX_NC"
  printf '%b╚══════════════════════════════════════════════════════════╝%b\n' "$UX_MAGENTA$UX_BOLD" "$UX_NC"
  printf '\n'
}

ux_success_rule() {
  printf '\n'
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$UX_GREEN$UX_BOLD" "$UX_NC"
  printf '%b  %s%b\n' "$UX_GREEN$UX_BOLD" "$1" "$UX_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$UX_GREEN$UX_BOLD" "$UX_NC"
  printf '\n'
}

ux_dim() { printf '%b%s%b\n' "$UX_DIM" "$1" "$UX_NC"; }

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1
#
# Adds a dual-mode (interactive + non-interactive/auto) layer on top of the
# existing ux_ask / _ask_yn / _ask_choice / _add_debt helpers. Scripts
# that want auto support call ux_get / _get_yn / _get_choice with a
# stable KEY and pick up values from (in priority order):
#
#   1. an environment variable named $KEY
#   2. the --answers <file> (KEY=VALUE pairs)
#   3. any configured upstream extract files
#   4. the documented default
#   5. interactive prompt — only when not in auto mode
#
# Activation: pass --auto on the CLI (via ux_parse_flags "$@") or set
# UX_AUTO=1 in the environment. See IMPROVEMENT-PLAN.md for the full
# contract.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
: "${UX_AUTO:=0}"; export UX_AUTO
: "${UX_ANSWERS:=}"; export UX_ANSWERS

# Upstream-extract search paths. Agents that read upstream output should
# append to this array from their phase scripts, e.g.:
#   CQR_UPSTREAM_EXTRACTS+=("$DEV_OUTPUT_DIR/02-coding-plan.extract")
if [ -z "${UX_UPSTREAM_EXTRACTS+x}" ]; then
  UX_UPSTREAM_EXTRACTS=()
fi

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts should call:  ux_parse_flags "$@"
# Recognised: --auto, --answers <file>, --answers=<file>. Unknown flags are
# ignored so the helper composes with scripts that have their own arg parsing.
ux_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)        UX_AUTO=1; export UX_AUTO; shift ;;
      --answers)     UX_ANSWERS="${2:-}"; export UX_ANSWERS; shift 2 ;;
      --answers=*)   UX_ANSWERS="${1#--answers=}"; export UX_ANSWERS; shift ;;
      *)             shift ;;
    esac
  done
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
ux_is_auto() {
  case "${UX_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Extract-file reader ──────────────────────────────────────────────────────
# Reads KEY=VALUE pairs (one per line, `#` comments allowed) from the given
# file. Echoes the value for the requested key, or empty.
ux_read_extract() {
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
# ux_resolve <KEY> [default]
# Priority: env var → answers file → upstream extracts → default. Echoes the
# resolved value, or empty if none and no default.
ux_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  # 1) Env var named exactly $key
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) Answers file
  if [ -n "${UX_ANSWERS:-}" ] && [ -f "${UX_ANSWERS}" ]; then
    val=$(ux_read_extract "${UX_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  # 3) Upstream extracts (first match wins)
  local f
  for f in ${UX_UPSTREAM_EXTRACTS[@]+"${UX_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(ux_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  # 4) Default
  printf '%s' "$default"
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# ux_add_debt_auto <area> <title> <description> <impact>
# Thin wrapper over the existing ux_add_debt so auto-resolved gaps use
# the agent's normal debt format. Agents with non-standard _add_debt
# signatures (cqr, re) override this below in their canonical _common.sh.
ux_add_debt_auto() {
  ux_add_debt "$@"
}

# ── Unified getters (interactive + auto) ─────────────────────────────────────
# ux_get <KEY> <prompt> [default]
ux_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(ux_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if ux_is_auto; then
    if [ -z "$default" ]; then
      ux_add_debt_auto "Auto-resolve" "Missing answer: $key" \
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
  val=$(ux_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

# ux_get_yn <KEY> <prompt> [default_yes_or_no]
ux_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(ux_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if ux_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    ux_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  ux_ask_yn "$prompt"
}

# ux_get_choice <KEY> <prompt> <opt1> <opt2> ...
# Auto mode: match resolved value (exact or prefix) against options; if no
# match, first option is used and a debt is logged.
ux_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(ux_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if ux_is_auto; then
      ux_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' does not match any known option" \
        "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if ux_is_auto; then
    ux_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode" \
      "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  ux_ask_choice "$prompt" "${options[@]}"
}

# ── Extract-file writer ──────────────────────────────────────────────────────
# ux_write_extract <output_path> <KEY1=VAL1> <KEY2=VAL2> ...
# Writes a machine-readable companion file alongside the markdown output so
# downstream agents can read structured answers without re-parsing markdown.
ux_write_extract() {
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
_ux_ask_orig()        { true; }   # placeholder, replaced below
_ux_ask_yn_orig()     { true; }
_ux_ask_choice_orig() { true; }
# Capture originals once, then replace with auto-aware wrappers.
if ! declare -f _ux_ask_orig_real >/dev/null 2>&1 && declare -f ux_ask >/dev/null 2>&1; then
  eval "_ux_ask_orig_real()        $(declare -f ux_ask | sed '1d')"
  eval "_ux_ask_yn_orig_real()     $(declare -f ux_ask_yn | sed '1d')"
  eval "_ux_ask_choice_orig_real() $(declare -f ux_ask_choice | sed '1d')"

  ux_ask() {
    if ux_is_auto; then printf ''; return 0; fi
    _ux_ask_orig_real "$@"
  }
  ux_ask_yn() {
    if ux_is_auto; then printf 'no'; return 0; fi
    _ux_ask_yn_orig_real "$@"
  }
  ux_ask_choice() {
    if ux_is_auto; then
      # Auto mode: return the first option
      local prompt="$1"; shift
      printf '%s' "${1:-}"
      return 0
    fi
    _ux_ask_choice_orig_real "$@"
  }
fi


# Auto-aware ux_confirm_save
if declare -f ux_confirm_save >/dev/null 2>&1; then
  eval "_ux_confirm_save_orig_real() $(declare -f ux_confirm_save | sed '1d')"
  ux_confirm_save() {
    if ux_is_auto; then
      # In auto mode, auto-confirm (skip redo loops).
      printf 'yes'
      return 0
    fi
    _ux_confirm_save_orig_real "$@"
  }
fi
