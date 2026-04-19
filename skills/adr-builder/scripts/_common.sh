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
#   - Respects $ARCH_OUTPUT_DIR, falls back to ./arch-output
#   - Continuous TDEBT / RISK / ADR numbering across all architect skills
#   - Shared arch_ask / arch_ask_yn / arch_ask_choice / arch_add_tdebt helpers
# =============================================================================

# ── Bash version guard ────────────────────────────────────────────────────────
if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
  echo "ERROR: Bash 3.2 or later is required." >&2
  echo "       Current: ${BASH_VERSION:-unknown}" >&2
  exit 1
fi

# ── Colours ──────────────────────────────────────────────────────────────────
ARCH_RED='\033[0;31m'; ARCH_GREEN='\033[0;32m'; ARCH_YELLOW='\033[1;33m'
ARCH_BLUE='\033[0;34m'; ARCH_CYAN='\033[0;36m'; ARCH_MAGENTA='\033[0;35m'
ARCH_BOLD='\033[1m'; ARCH_DIM='\033[2m'; ARCH_NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
ARCH_OUTPUT_DIR="${ARCH_OUTPUT_DIR:-$(pwd)/arch-output}"
ARCH_BA_INPUT_DIR="${ARCH_BA_INPUT_DIR:-$(pwd)/ba-output}"
ARCH_TDEBT_FILE="$ARCH_OUTPUT_DIR/05-technical-debts.md"
ARCH_ADR_DIR="$ARCH_OUTPUT_DIR/adr"
ARCH_DIAGRAMS_DIR="$ARCH_OUTPUT_DIR/diagrams"
mkdir -p "$ARCH_OUTPUT_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────

# to_lower: Bash 3.2-compatible lowercase conversion.
to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# slugify: lowercase, replace non-alphanum with hyphens, collapse.
arch_slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]/-/g' -e 's/-\{1,\}/-/g' -e 's/^-//' -e 's/-$//'
}

arch_ask() {
  local prompt="$1" answer
  printf '%b▶ %s%b\n' "$ARCH_YELLOW" "$prompt" "$ARCH_NC" >&2
  IFS= read -r answer
  answer="$(printf '%s' "$answer" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$answer"
}

arch_ask_yn() {
  local prompt="$1" raw norm
  while true; do
    printf '%b▶ %s (y/n): %b\n' "$ARCH_YELLOW" "$prompt" "$ARCH_NC" >&2
    IFS= read -r raw
    norm="$(to_lower "$raw")"
    case "$norm" in
      y|yes) printf '%s' "yes"; return 0 ;;
      n|no)  printf '%s' "no";  return 0 ;;
      *)     printf '%b  Please type y or n.%b\n' "$ARCH_RED" "$ARCH_NC" >&2 ;;
    esac
  done
}

arch_ask_choice() {
  local prompt="$1"; shift
  local options=("$@")
  local i choice total="${#options[@]}"
  printf '%b▶ %s%b\n' "$ARCH_YELLOW" "$prompt" "$ARCH_NC" >&2
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
    printf '%b  Please enter a number between 1 and %d.%b\n' "$ARCH_RED" "$total" "$ARCH_NC" >&2
  done
}

arch_confirm_save() {
  local answer
  answer=$(arch_ask_yn "$1")
  [ "$answer" = "yes" ]
}

arch_current_tdebt_count() {
  if [ -f "$ARCH_TDEBT_FILE" ]; then
    local n
    n=$(grep -c '^## TDEBT-' "$ARCH_TDEBT_FILE" 2>/dev/null || printf '0')
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
    printf '%d' "$n"
  else
    printf '0'
  fi
}

arch_current_risk_count() {
  if [ -f "$ARCH_TDEBT_FILE" ]; then
    local n
    n=$(grep -c '^## RISK-' "$ARCH_TDEBT_FILE" 2>/dev/null || printf '0')
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
    printf '%d' "$n"
  else
    printf '0'
  fi
}

arch_current_adr_count() {
  mkdir -p "$ARCH_ADR_DIR" 2>/dev/null || true
  if [ -d "$ARCH_ADR_DIR" ]; then
    local n
    n=$(ls -1 "$ARCH_ADR_DIR" 2>/dev/null | grep -c '^ADR-[0-9][0-9][0-9][0-9]-' 2>/dev/null || printf '0')
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
    printf '%d' "$n"
  else
    printf '0'
  fi
}

arch_next_adr_id() {
  local current next
  current=$(arch_current_adr_count)
  next=$((current + 1))
  printf 'ADR-%04d' "$next"
}

# arch_add_tdebt <area> <title> <description> <impact>
arch_add_tdebt() {
  local area="$1" title="$2" desc="$3" impact="$4"
  local current next id
  current=$(arch_current_tdebt_count)
  next=$((current + 1))
  id=$(printf '%02d' "$next")

  {
    printf '\n'
    printf '## TDEBT-%s: %s\n' "$id" "$title"
    printf '**Area:** %s\n' "$area"
    printf '**Description:** %s\n' "$desc"
    printf '**Impact:** %s\n' "$impact"
    printf '**Owner:** TBD\n'
    printf '**Priority:** 🟡 Important\n'
    printf '**Target Date:** TBD\n'
    printf '**Linked:** TBD\n'
    printf '**Status:** Open\n'
    printf '\n'
  } >> "$ARCH_TDEBT_FILE"
}

arch_banner() {
  printf '\n'
  printf '%b╔══════════════════════════════════════════════════════════╗%b\n' "$ARCH_MAGENTA$ARCH_BOLD" "$ARCH_NC"
  printf '%b║  %-56s║%b\n' "$ARCH_MAGENTA$ARCH_BOLD" "$1" "$ARCH_NC"
  printf '%b╚══════════════════════════════════════════════════════════╝%b\n' "$ARCH_MAGENTA$ARCH_BOLD" "$ARCH_NC"
  printf '\n'
}

arch_success_rule() {
  printf '\n'
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$ARCH_GREEN$ARCH_BOLD" "$ARCH_NC"
  printf '%b  %s%b\n' "$ARCH_GREEN$ARCH_BOLD" "$1" "$ARCH_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$ARCH_GREEN$ARCH_BOLD" "$ARCH_NC"
  printf '\n'
}

arch_dim() { printf '%b%s%b\n' "$ARCH_DIM" "$1" "$ARCH_NC"; }

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1
#
# Adds a dual-mode (interactive + non-interactive/auto) layer on top of the
# existing arch_ask / _ask_yn / _ask_choice / _add_debt helpers. Scripts
# that want auto support call arch_get / _get_yn / _get_choice with a
# stable KEY and pick up values from (in priority order):
#
#   1. an environment variable named $KEY
#   2. the --answers <file> (KEY=VALUE pairs)
#   3. any configured upstream extract files
#   4. the documented default
#   5. interactive prompt — only when not in auto mode
#
# Activation: pass --auto on the CLI (via arch_parse_flags "$@") or set
# ARCH_AUTO=1 in the environment. See IMPROVEMENT-PLAN.md for the full
# contract.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
: "${ARCH_AUTO:=0}"; export ARCH_AUTO
: "${ARCH_ANSWERS:=}"; export ARCH_ANSWERS

# Upstream-extract search paths. Agents that read upstream output should
# append to this array from their phase scripts, e.g.:
#   CQR_UPSTREAM_EXTRACTS+=("$DEV_OUTPUT_DIR/02-coding-plan.extract")
if [ -z "${ARCH_UPSTREAM_EXTRACTS+x}" ]; then
  ARCH_UPSTREAM_EXTRACTS=()
fi

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts should call:  arch_parse_flags "$@"
# Recognised: --auto, --answers <file>, --answers=<file>. Unknown flags are
# ignored so the helper composes with scripts that have their own arg parsing.
arch_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)        ARCH_AUTO=1; export ARCH_AUTO; shift ;;
      --answers)     ARCH_ANSWERS="${2:-}"; export ARCH_ANSWERS; shift 2 ;;
      --answers=*)   ARCH_ANSWERS="${1#--answers=}"; export ARCH_ANSWERS; shift ;;
      *)             shift ;;
    esac
  done
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
arch_is_auto() {
  case "${ARCH_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Extract-file reader ──────────────────────────────────────────────────────
# Reads KEY=VALUE pairs (one per line, `#` comments allowed) from the given
# file. Echoes the value for the requested key, or empty.
arch_read_extract() {
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
# arch_resolve <KEY> [default]
# Priority: env var → answers file → upstream extracts → default. Echoes the
# resolved value, or empty if none and no default.
arch_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  # 1) Env var named exactly $key
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) Answers file
  if [ -n "${ARCH_ANSWERS:-}" ] && [ -f "${ARCH_ANSWERS}" ]; then
    val=$(arch_read_extract "${ARCH_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  # 3) Upstream extracts (first match wins)
  local f
  for f in ${ARCH_UPSTREAM_EXTRACTS[@]+"${ARCH_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(arch_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  # 4) Default
  printf '%s' "$default"
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# arch_add_debt_auto <area> <title> <description> <impact>
# Thin wrapper over the existing arch_add_debt so auto-resolved gaps use
# the agent's normal debt format. Agents with non-standard _add_debt
# signatures (cqr, re) override this below in their canonical _common.sh.
arch_add_debt_auto() {
  arch_add_debt "$@"
}

# ── Unified getters (interactive + auto) ─────────────────────────────────────
# arch_get <KEY> <prompt> [default]
arch_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(arch_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if arch_is_auto; then
    if [ -z "$default" ]; then
      arch_add_debt_auto "Auto-resolve" "Missing answer: $key" \
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
  val=$(arch_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

# arch_get_yn <KEY> <prompt> [default_yes_or_no]
arch_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(arch_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if arch_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    arch_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  arch_ask_yn "$prompt"
}

# arch_get_choice <KEY> <prompt> <opt1> <opt2> ...
# Auto mode: match resolved value (exact or prefix) against options; if no
# match, first option is used and a debt is logged.
arch_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(arch_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if arch_is_auto; then
      arch_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' does not match any known option" \
        "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if arch_is_auto; then
    arch_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode" \
      "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  arch_ask_choice "$prompt" "${options[@]}"
}

# ── Extract-file writer ──────────────────────────────────────────────────────
# arch_write_extract <output_path> <KEY1=VAL1> <KEY2=VAL2> ...
# Writes a machine-readable companion file alongside the markdown output so
# downstream agents can read structured answers without re-parsing markdown.
arch_write_extract() {
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
_arch_ask_orig()        { true; }   # placeholder, replaced below
_arch_ask_yn_orig()     { true; }
_arch_ask_choice_orig() { true; }
# Capture originals once, then replace with auto-aware wrappers.
if ! declare -f _arch_ask_orig_real >/dev/null 2>&1 && declare -f arch_ask >/dev/null 2>&1; then
  eval "_arch_ask_orig_real()        $(declare -f arch_ask | sed '1d')"
  eval "_arch_ask_yn_orig_real()     $(declare -f arch_ask_yn | sed '1d')"
  eval "_arch_ask_choice_orig_real() $(declare -f arch_ask_choice | sed '1d')"

  arch_ask() {
    if arch_is_auto; then printf ''; return 0; fi
    _arch_ask_orig_real "$@"
  }
  arch_ask_yn() {
    if arch_is_auto; then printf 'no'; return 0; fi
    _arch_ask_yn_orig_real "$@"
  }
  arch_ask_choice() {
    if arch_is_auto; then
      # Auto mode: return the first option
      local prompt="$1"; shift
      printf '%s' "${1:-}"
      return 0
    fi
    _arch_ask_choice_orig_real "$@"
  }
fi


# Auto-aware arch_confirm_save
if declare -f arch_confirm_save >/dev/null 2>&1; then
  eval "_arch_confirm_save_orig_real() $(declare -f arch_confirm_save | sed '1d')"
  arch_confirm_save() {
    if arch_is_auto; then
      # In auto mode, auto-confirm (skip redo loops).
      printf 'yes'
      return 0
    fi
    _arch_confirm_save_orig_real "$@"
  }
fi
