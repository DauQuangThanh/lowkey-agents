#!/bin/bash

# Bash 3.2+ compatible utility functions for OPS skills
# Source this file in skill scripts: source _common.sh

# Version guard
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires Bash 3.2 or later." >&2
    exit 1
fi

# Colors (compatible with dark terminals)
OPS_RED='\033[1;31m'
OPS_GREEN='\033[1;32m'
OPS_YELLOW='\033[1;33m'
OPS_BLUE='\033[1;34m'
OPS_CYAN='\033[1;36m'
OPS_MAGENTA='\033[1;35m'
OPS_BOLD='\033[1;37m'
OPS_DIM='\033[2m'
OPS_NC='\033[0m'

# Paths
OPS_OUTPUT_DIR="${OPS_OUTPUT_DIR:-./ ops-output}"
OPS_DEBT_FILE="${OPS_DEBT_FILE:=${OPS_OUTPUT_DIR}/07-ops-debts.md}"

# Create output directory if it doesn't exist
mkdir -p "$OPS_OUTPUT_DIR"

# Utility: Convert string to lowercase
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Utility: Ask a question and get response
ops_ask() {
    local prompt="$1"
    local response
    echo -ne "${OPS_BLUE}${prompt}${OPS_NC} " >&2
    read -r response
    echo "$response"
}

# Utility: Ask yes/no question
ops_ask_yn() {
    local prompt="$1"
    local response
    while true; do
        echo -ne "${OPS_BLUE}${prompt} [y/n]:${OPS_NC} " >&2
        read -r response
        case "$(to_lower "$response")" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Utility: Ask multiple choice question
ops_ask_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice

    echo -e "${OPS_BLUE}${prompt}${OPS_NC}" >&2
    for i in "${!options[@]}"; do
        echo "  $((i + 1)). ${options[$i]}"
    done

    while true; do
        echo -ne "${OPS_BLUE}Enter choice (1-${#options[@]}):${OPS_NC} " >&2
        read -r choice
        if [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            echo "${options[$((choice - 1))]}"
            return 0
        else
            echo "Invalid choice. Please try again."
        fi
    done
}

# Utility: Confirm before saving
ops_confirm_save() {
    local filepath="$1"
    if [ -f "$filepath" ]; then
        echo -e "${OPS_YELLOW}File already exists: ${filepath}${OPS_NC}"
        if ! ops_ask_yn "Overwrite?"; then
            echo "Skipped."
            return 1
        fi
    fi
    return 0
}

# Utility: Count existing debt items
ops_current_debt_count() {
    if [ ! -f "$OPS_DEBT_FILE" ]; then
        echo 0
        return
    fi
    grep -c "^## OPSDEBT-" "$OPS_DEBT_FILE" 2>/dev/null || echo 0
}

# Utility: Add debt item
ops_add_debt() {
    local title="$1"
    local description="$2"
    local severity="${3:-medium}"  # low, medium, high, critical
    local owner="${4:-unassigned}"

    if [ ! -f "$OPS_DEBT_FILE" ]; then
        mkdir -p "$(dirname "$OPS_DEBT_FILE")"
        echo "# OPS Debt Tracker" > "$OPS_DEBT_FILE"
        echo "" >> "$OPS_DEBT_FILE"
        echo "Debt items that reduce operational efficiency or increase risk." >> "$OPS_DEBT_FILE"
        echo "" >> "$OPS_DEBT_FILE"
    fi

    local count=$(($(ops_current_debt_count) + 1))
    local debt_id=$(printf "OPSDEBT-%02d" "$count")

    {
        echo ""
        echo "## $debt_id: $title"
        echo ""
        echo "**Severity**: $severity"
        echo "**Owner**: $owner"
        echo "**Created**: $(date -u '+%Y-%m-%d')"
        echo ""
        echo "$description"
        echo ""
    } >> "$OPS_DEBT_FILE"

    echo "${OPS_YELLOW}Added: ${debt_id}${OPS_NC}"
}

# Utility: Print banner
ops_banner() {
    local text="$1"
    echo ""
    echo -e "${OPS_BOLD}════════════════════════════════════════════════════════════${OPS_NC}"
    echo -e "${OPS_BOLD}${text}${OPS_NC}"
    echo -e "${OPS_BOLD}════════════════════════════════════════════════════════════${OPS_NC}"
    echo ""
}

# Utility: Print success rule
ops_success_rule() {
    local text="$1"
    echo ""
    echo -e "${OPS_GREEN}✓ ${text}${OPS_NC}"
    echo ""
}

# Utility: Print dim text
ops_dim() {
    local text="$1"
    echo -e "${OPS_DIM}${text}${OPS_NC}"
}

# Utility: Print colored section
ops_section() {
    local title="$1"
    echo ""
    echo -e "${OPS_CYAN}### ${title}${OPS_NC}"
    echo ""
}

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1
#
# Adds a dual-mode (interactive + non-interactive/auto) layer on top of the
# existing ops_ask / _ask_yn / _ask_choice / _add_debt helpers. Scripts
# that want auto support call ops_get / _get_yn / _get_choice with a
# stable KEY and pick up values from (in priority order):
#
#   1. an environment variable named $KEY
#   2. the --answers <file> (KEY=VALUE pairs)
#   3. any configured upstream extract files
#   4. the documented default
#   5. interactive prompt — only when not in auto mode
#
# Activation: pass --auto on the CLI (via ops_parse_flags "$@") or set
# OPS_AUTO=1 in the environment. See IMPROVEMENT-PLAN.md for the full
# contract.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
: "${OPS_AUTO:=0}"; export OPS_AUTO
: "${OPS_ANSWERS:=}"; export OPS_ANSWERS

# Upstream-extract search paths. Agents that read upstream output should
# append to this array from their phase scripts, e.g.:
#   CQR_UPSTREAM_EXTRACTS+=("$DEV_OUTPUT_DIR/02-coding-plan.extract")
if [ -z "${OPS_UPSTREAM_EXTRACTS+x}" ]; then
  OPS_UPSTREAM_EXTRACTS=()
fi

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts should call:  ops_parse_flags "$@"
# Recognised: --auto, --answers <file>, --answers=<file>. Unknown flags are
# ignored so the helper composes with scripts that have their own arg parsing.
ops_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)        OPS_AUTO=1; export OPS_AUTO; shift ;;
      --answers)     OPS_ANSWERS="${2:-}"; export OPS_ANSWERS; shift 2 ;;
      --answers=*)   OPS_ANSWERS="${1#--answers=}"; export OPS_ANSWERS; shift ;;
      *)             shift ;;
    esac
  done
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
ops_is_auto() {
  case "${OPS_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Extract-file reader ──────────────────────────────────────────────────────
# Reads KEY=VALUE pairs (one per line, `#` comments allowed) from the given
# file. Echoes the value for the requested key, or empty.
ops_read_extract() {
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
# ops_resolve <KEY> [default]
# Priority: env var → answers file → upstream extracts → default. Echoes the
# resolved value, or empty if none and no default.
ops_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  # 1) Env var named exactly $key
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) Answers file
  if [ -n "${OPS_ANSWERS:-}" ] && [ -f "${OPS_ANSWERS}" ]; then
    val=$(ops_read_extract "${OPS_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  # 3) Upstream extracts (first match wins)
  local f
  for f in ${OPS_UPSTREAM_EXTRACTS[@]+"${OPS_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(ops_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  # 4) Default
  printf '%s' "$default"
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# ops_add_debt_auto <area> <title> <description> <impact>
# Thin wrapper over the existing ops_add_debt so auto-resolved gaps use
# the agent's normal debt format. Agents with non-standard _add_debt
# signatures (cqr, re) override this below in their canonical _common.sh.
ops_add_debt_auto() {
  ops_add_debt "$@"
}

# ── Unified getters (interactive + auto) ─────────────────────────────────────
# ops_get <KEY> <prompt> [default]
ops_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(ops_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if ops_is_auto; then
    if [ -z "$default" ]; then
      ops_add_debt_auto "Auto-resolve" "Missing answer: $key" \
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
  val=$(ops_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

# ops_get_yn <KEY> <prompt> [default_yes_or_no]
ops_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(ops_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if ops_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    ops_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  ops_ask_yn "$prompt"
}

# ops_get_choice <KEY> <prompt> <opt1> <opt2> ...
# Auto mode: match resolved value (exact or prefix) against options; if no
# match, first option is used and a debt is logged.
ops_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(ops_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if ops_is_auto; then
      ops_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' does not match any known option" \
        "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if ops_is_auto; then
    ops_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode" \
      "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  ops_ask_choice "$prompt" "${options[@]}"
}

# ── Extract-file writer ──────────────────────────────────────────────────────
# ops_write_extract <output_path> <KEY1=VAL1> <KEY2=VAL2> ...
# Writes a machine-readable companion file alongside the markdown output so
# downstream agents can read structured answers without re-parsing markdown.
ops_write_extract() {
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
_ops_ask_orig()        { true; }   # placeholder, replaced below
_ops_ask_yn_orig()     { true; }
_ops_ask_choice_orig() { true; }
# Capture originals once, then replace with auto-aware wrappers.
if ! declare -f _ops_ask_orig_real >/dev/null 2>&1 && declare -f ops_ask >/dev/null 2>&1; then
  eval "_ops_ask_orig_real()        $(declare -f ops_ask | sed '1d')"
  eval "_ops_ask_yn_orig_real()     $(declare -f ops_ask_yn | sed '1d')"
  eval "_ops_ask_choice_orig_real() $(declare -f ops_ask_choice | sed '1d')"

  ops_ask() {
    if ops_is_auto; then printf ''; return 0; fi
    _ops_ask_orig_real "$@"
  }
  ops_ask_yn() {
    if ops_is_auto; then printf 'no'; return 0; fi
    _ops_ask_yn_orig_real "$@"
  }
  ops_ask_choice() {
    if ops_is_auto; then
      # Auto mode: return the first option
      local prompt="$1"; shift
      printf '%s' "${1:-}"
      return 0
    fi
    _ops_ask_choice_orig_real "$@"
  }
fi


# Auto-aware ops_confirm_save
if declare -f ops_confirm_save >/dev/null 2>&1; then
  eval "_ops_confirm_save_orig_real() $(declare -f ops_confirm_save | sed '1d')"
  ops_confirm_save() {
    if ops_is_auto; then
      # In auto mode, auto-confirm (skip redo loops).
      printf 'yes'
      return 0
    fi
    _ops_confirm_save_orig_real "$@"
  }
fi
