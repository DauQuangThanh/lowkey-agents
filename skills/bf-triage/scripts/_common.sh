#!/bin/bash
# =============================================================================
# _common.sh — Shared helpers for the bug-fixer (BF) skill family.
#
# The bug-fixer's canonical _common.sh lives here (bf-triage); other bf-*
# skills source it via a thin shim.
#
# Features:
#   - Bash 3.2+ (macOS default) compatible
#   - Respects $BF_OUTPUT_DIR, falls back to ./bf-output
#   - Continuous BFDEBT-NN numbering
#   - Same auto-mode contract as every other agent in this project
# =============================================================================

if [ -z "${BASH_VERSINFO[0]:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
  echo "ERROR: Bash 3.2 or later is required." >&2
  exit 1
fi

# ── Colours ──────────────────────────────────────────────────────────────────
BF_RED='\033[0;31m'; BF_GREEN='\033[0;32m'; BF_YELLOW='\033[1;33m'
BF_BLUE='\033[0;34m'; BF_CYAN='\033[0;36m'; BF_ORANGE='\033[38;5;208m'
BF_BOLD='\033[1m'; BF_DIM='\033[2m'; BF_NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
BF_OUTPUT_DIR="${BF_OUTPUT_DIR:-$(pwd)/bf-output}"
BF_DEBT_FILE="$BF_OUTPUT_DIR/07-bf-debts.md"
mkdir -p "$BF_OUTPUT_DIR"

# ── Core helpers ──────────────────────────────────────────────────────────────
to_lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

bf_ask() {
  local prompt="$1" answer
  printf '%b▶ %s%b\n' "$BF_YELLOW" "$prompt" "$BF_NC" >&2
  IFS= read -r answer
  answer="$(printf '%s' "$answer" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  printf '%s' "$answer"
}

bf_ask_yn() {
  local prompt="$1" raw norm
  while true; do
    printf '%b▶ %s (y/n): %b\n' "$BF_YELLOW" "$prompt" "$BF_NC" >&2
    IFS= read -r raw
    norm="$(to_lower "$raw")"
    case "$norm" in
      y|yes) printf '%s' "yes"; return 0 ;;
      n|no)  printf '%s' "no";  return 0 ;;
      *)     printf '%b  Please type y or n.%b\n' "$BF_RED" "$BF_NC" >&2 ;;
    esac
  done
}

bf_ask_choice() {
  local prompt="$1"; shift
  local options=("$@")
  local i choice total="${#options[@]}"
  printf '%b▶ %s%b\n' "$BF_YELLOW" "$prompt" "$BF_NC" >&2
  for ((i=0; i<total; i++)); do
    printf '  %d) %s\n' "$((i+1))" "${options[$i]}" >&2
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
    printf '%b  Please enter a number between 1 and %d.%b\n' "$BF_RED" "$total" "$BF_NC" >&2
  done
}

bf_confirm_save() {
  local answer
  answer=$(bf_ask_yn "$1")
  [ "$answer" = "yes" ]
}

bf_current_debt_count() {
  if [ -f "$BF_DEBT_FILE" ]; then
    local n
    n=$(grep -c '^## BFDEBT-' "$BF_DEBT_FILE" 2>/dev/null || printf '0')
    n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
    [ -z "$n" ] && n=0
    printf '%d' "$n"
  else
    printf '0'
  fi
}

bf_add_debt() {
  local area="$1" title="$2" desc="$3" impact="$4"
  local current next id
  current=$(bf_current_debt_count)
  next=$((current + 1))
  id=$(printf '%02d' "$next")
  {
    printf '\n'
    printf '## BFDEBT-%s: %s\n' "$id" "$title"
    printf '**Area:** %s\n' "$area"
    printf '**Description:** %s\n' "$desc"
    printf '**Impact:** %s\n' "$impact"
    printf '**Owner:** TBD\n'
    printf '**Priority:** 🟡 Important\n'
    printf '**Target Date:** TBD\n'
    printf '**Status:** Open\n'
    printf '\n'
  } >> "$BF_DEBT_FILE"
}

bf_banner() {
  printf '\n'
  printf '%b╔══════════════════════════════════════════════════════════╗%b\n' "$BF_ORANGE$BF_BOLD" "$BF_NC"
  printf '%b║  %-56s║%b\n' "$BF_ORANGE$BF_BOLD" "$1" "$BF_NC"
  printf '%b╚══════════════════════════════════════════════════════════╝%b\n' "$BF_ORANGE$BF_BOLD" "$BF_NC"
  printf '\n'
}

bf_success_rule() {
  printf '\n'
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$BF_GREEN$BF_BOLD" "$BF_NC"
  [ -n "${1:-}" ] && printf '%b  %s%b\n' "$BF_GREEN$BF_BOLD" "$1" "$BF_NC"
  printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' "$BF_GREEN$BF_BOLD" "$BF_NC"
  printf '\n'
}

bf_dim() { printf '%b%s%b\n' "$BF_DIM" "$1" "$BF_NC"; }

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — identical contract to the rest of the project.
# ═════════════════════════════════════════════════════════════════════════════

: "${BF_AUTO:=0}"; export BF_AUTO
: "${BF_ANSWERS:=}"; export BF_ANSWERS
: "${BF_DRY_RUN:=0}"; export BF_DRY_RUN
: "${BF_BRANCH:=}"; export BF_BRANCH

if [ -z "${BF_UPSTREAM_EXTRACTS+x}" ]; then
  _BF_TEST_OUT="${TEST_OUTPUT_DIR:-$(pwd)/test-output}"
  _BF_CQR_OUT="${CQR_OUTPUT_DIR:-$(pwd)/cqr-output}"
  _BF_CSR_OUT="${CSR_OUTPUT_DIR:-$(pwd)/csr-output}"
  BF_UPSTREAM_EXTRACTS=(
    "$_BF_TEST_OUT/bugs.extract"
    "$_BF_CQR_OUT/05-cq-debts.md"
    "$_BF_CSR_OUT/CSR-FINAL.md"
  )
fi

bf_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)         BF_AUTO=1; export BF_AUTO; shift ;;
      --answers)      BF_ANSWERS="${2:-}"; export BF_ANSWERS; shift 2 ;;
      --answers=*)    BF_ANSWERS="${1#--answers=}"; export BF_ANSWERS; shift ;;
      --branch)       BF_BRANCH="${2:-}"; export BF_BRANCH; shift 2 ;;
      --branch=*)     BF_BRANCH="${1#--branch=}"; export BF_BRANCH; shift ;;
      --dry-run)      BF_DRY_RUN=1; export BF_DRY_RUN; shift ;;
      *)              shift ;;
    esac
  done
}

bf_is_auto() {
  case "${BF_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

bf_is_dry_run() {
  case "${BF_DRY_RUN:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

bf_read_extract() {
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

bf_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if [ -n "${BF_ANSWERS:-}" ] && [ -f "${BF_ANSWERS}" ]; then
    val=$(bf_read_extract "${BF_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  local f
  for f in ${BF_UPSTREAM_EXTRACTS[@]+"${BF_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(bf_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  printf '%s' "$default"
}

bf_add_debt_auto() { bf_add_debt "$@"; }

bf_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(bf_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if bf_is_auto; then
    if [ -z "$default" ]; then
      bf_add_debt_auto "Auto-resolve" "Missing answer: $key" \
        "Could not resolve '$key' from env/answers/upstream in auto mode, no default documented" \
        "Downstream field blank"
    fi
    printf '%s' "$default"
    return 0
  fi
  [ -n "$default" ] && printf '  (default: %s — press Enter to accept)\n' "$default" >&2
  val=$(bf_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

bf_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(bf_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if bf_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    bf_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, no default documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  bf_ask_yn "$prompt"
}

bf_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(bf_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if bf_is_auto; then
      bf_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' not in option list" "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if bf_is_auto; then
    bf_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' in auto mode" "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  bf_ask_choice "$prompt" "${options[@]}"
}

bf_write_extract() {
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

# Auto-short-circuit wrappers (match project-wide convention)
if declare -f bf_ask >/dev/null 2>&1; then
  eval "_bf_ask_orig_real()        $(declare -f bf_ask        | sed '1d')"
  eval "_bf_ask_yn_orig_real()     $(declare -f bf_ask_yn     | sed '1d')"
  eval "_bf_ask_choice_orig_real() $(declare -f bf_ask_choice | sed '1d')"

  bf_ask() {
    if bf_is_auto; then printf ''; return 0; fi
    _bf_ask_orig_real "$@"
  }
  bf_ask_yn() {
    if bf_is_auto; then printf 'no'; return 0; fi
    _bf_ask_yn_orig_real "$@"
  }
  bf_ask_choice() {
    if bf_is_auto; then
      shift
      printf '%s' "${1:-}"
      return 0
    fi
    _bf_ask_choice_orig_real "$@"
  }
fi

if declare -f bf_confirm_save >/dev/null 2>&1; then
  eval "_bf_confirm_save_orig_real() $(declare -f bf_confirm_save | sed '1d')"
  bf_confirm_save() {
    if bf_is_auto; then printf 'yes'; return 0; fi
    _bf_confirm_save_orig_real "$@"
  }
fi

export BF_OUTPUT_DIR BF_DEBT_FILE BF_BRANCH BF_DRY_RUN
export BF_RED BF_GREEN BF_YELLOW BF_BLUE BF_CYAN BF_ORANGE BF_BOLD BF_DIM BF_NC
