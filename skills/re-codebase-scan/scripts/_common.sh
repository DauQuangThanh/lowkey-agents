#!/bin/bash
# Reverse Engineering Common Functions for Bash 3.2+
# Used by all RE scripts for consistency, colors, and utilities

# Version check: bash 3.2+
if [ -z "$BASH_VERSION" ] || [ "${BASH_VERSINFO[0]}" -lt 3 ] || ([ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]); then
    echo "Error: This script requires Bash 3.2 or later" >&2
    exit 1
fi

# ============================================================================
# Environment Setup
# ============================================================================

# Output directory for reverse engineering artifacts
export RE_OUTPUT_DIR="${RE_OUTPUT_DIR:-.\/re-output}"

# File to track RE Debts (undocumented areas)
export RE_DEBT_FILE="${RE_OUTPUT_DIR}/07-re-debts.md"

# ============================================================================
# Color Definitions
# ============================================================================

# ANSI color codes
RE_BANNER_COLOR="\033[1;36m"      # Bright cyan
RE_SUCCESS_COLOR="\033[0;32m"     # Green
RE_ERROR_COLOR="\033[0;31m"       # Red
RE_WARNING_COLOR="\033[0;33m"     # Yellow
RE_INFO_COLOR="\033[0;34m"        # Blue
RE_DIM_COLOR="\033[2m"            # Dim/gray
RE_BOLD_COLOR="\033[1m"           # Bold
RE_RESET_COLOR="\033[0m"          # Reset

# ============================================================================
# Utility Functions
# ============================================================================

# Convert string to lowercase
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Convert string to uppercase
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Check if string is yes-like (y, yes, true, 1)
is_yes() {
    local input
    input=$(to_lower "$1")
    [[ "$input" == "y" ]] || [[ "$input" == "yes" ]] || [[ "$input" == "true" ]] || [[ "$input" == "1" ]]
}

# Check if string is no-like (n, no, false, 0)
is_no() {
    local input
    input=$(to_lower "$1")
    [[ "$input" == "n" ]] || [[ "$input" == "no" ]] || [[ "$input" == "false" ]] || [[ "$input" == "0" ]]
}

# ============================================================================
# Interactive Input Functions
# ============================================================================

# Ask a text question and wait for input
re_ask() {
    local prompt="$1"
    local default="$2"
    local input

    if [ -n "$default" ]; then
        echo -ne "${RE_INFO_COLOR}${prompt}${RE_RESET_COLOR} [${default}]: " >&2
    else
        echo -ne "${RE_INFO_COLOR}${prompt}${RE_RESET_COLOR}: " >&2
    fi

    read -r input

    # Return default if input is empty
    if [ -z "$input" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$input"
    fi
}

# Ask a yes/no question
re_ask_yn() {
    local prompt="$1"
    local default="${2:-n}"
    local input

    while true; do
        echo -ne "${RE_INFO_COLOR}${prompt}${RE_RESET_COLOR} [${default}]: " >&2
        read -r input

        # Use default if empty
        input="${input:-$default}"

        if is_yes "$input"; then
            echo "yes"
            return 0
        elif is_no "$input"; then
            echo "no"
            return 0
        else
            echo "${RE_ERROR_COLOR}Please answer 'y' or 'n'${RE_RESET_COLOR}" >&2
        fi
    done
}

# Ask for a choice from a list
re_ask_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice
    local i

    echo -e "${RE_INFO_COLOR}${prompt}${RE_RESET_COLOR}" >&2
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done

    while true; do
        echo -ne "${RE_INFO_COLOR}Select (1-${#options[@]}): ${RE_RESET_COLOR}" >&2
        read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            echo "${options[$((choice-1))]}"
            return 0
        else
            echo "${RE_ERROR_COLOR}Invalid choice. Please enter a number between 1 and ${#options[@]}.${RE_RESET_COLOR}" >&2
        fi
    done
}

# Confirm before saving (ask user if they want to save)
re_confirm_save() {
    local filename="$1"
    local response

    response=$(re_ask_yn "Save to ${filename}?" "y")
    [ "$response" = "yes" ]
}

# ============================================================================
# Debt Management Functions
# ============================================================================

# Initialize the debt file if it doesn't exist
re_init_debt_file() {
    if [ ! -d "$RE_OUTPUT_DIR" ]; then
        mkdir -p "$RE_OUTPUT_DIR"
    fi

    if [ ! -f "$RE_DEBT_FILE" ]; then
        cat > "$RE_DEBT_FILE" << 'EOF'
# Reverse Engineering Debts

This file tracks areas of the codebase that were difficult to document or require further investigation.
Each debt is assigned a unique ID (REDEBT-NN) and categorized by type.

## Legend
- **Undocumented Module**: Code with no comments, docstrings, or clear purpose
- **Unclear Logic**: Complex code that lacks explanation
- **Magic Number**: Hardcoded values without context
- **Dead Code**: Unused functions, imports, or modules
- **Missing Tests**: Code without corresponding unit tests
- **Deployment Gap**: Unclear how code is deployed in production
- **Integration Mystery**: External service integrations without clear contracts
- **Performance Unknown**: Code that may have performance impact but is undocumented

---

EOF
    fi
}

# Get the current debt count
re_current_debt_count() {
    local n=0
    if [ -f "$RE_DEBT_FILE" ]; then
        n=$(grep -c "^## REDEBT-" "$RE_DEBT_FILE" 2>/dev/null)
        n=$(printf '%s' "$n" | head -1 | tr -dc '0-9')
        [ -z "$n" ] && n=0
    fi
    printf '%s' "$n"
}

# Add a new debt entry
re_add_debt() {
    local title="$1"
    local file_path="$2"
    local line_range="$3"
    local debt_type="$4"
    local evidence="$5"
    local impact="${6:-Medium}"
    local recommendation="$7"

    re_init_debt_file

    local debt_num=$(($(re_current_debt_count) + 1))
    local debt_id=$(printf "REDEBT-%02d" "$debt_num")

    cat >> "$RE_DEBT_FILE" << EOF

## ${debt_id}: ${title}

- **File**: ${file_path} (line ${line_range})
- **Type**: ${debt_type}
- **Evidence**: ${evidence}
- **Impact**: ${impact}
- **Recommendation**: ${recommendation}

EOF

    echo "${RE_SUCCESS_COLOR}Added ${debt_id}${RE_RESET_COLOR}"
}

# ============================================================================
# Output Functions
# ============================================================================

# Print a banner (section header)
re_banner() {
    local text="$1"
    echo -e "\n${RE_BANNER_COLOR}╔════════════════════════════════════════════════════════════════════╗${RE_RESET_COLOR}"
    echo -e "${RE_BANNER_COLOR}║ $(printf '%-64s' "$text") ║${RE_RESET_COLOR}"
    echo -e "${RE_BANNER_COLOR}╚════════════════════════════════════════════════════════════════════╝${RE_RESET_COLOR}\n"
}

# Print a success rule (completion indicator)
re_success_rule() {
    echo -e "${RE_SUCCESS_COLOR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RE_RESET_COLOR}"
}

# Print dim text (for notes)
re_dim() {
    echo -e "${RE_DIM_COLOR}$1${RE_RESET_COLOR}"
}

# Print success message
re_success() {
    echo -e "${RE_SUCCESS_COLOR}✓ $1${RE_RESET_COLOR}"
}

# Print error message
re_error() {
    echo -e "${RE_ERROR_COLOR}✗ $1${RE_RESET_COLOR}" >&2
}

# Print warning message
re_warning() {
    echo -e "${RE_WARNING_COLOR}⚠ $1${RE_RESET_COLOR}"
}

# Print info message
re_info() {
    echo -e "${RE_INFO_COLOR}ℹ $1${RE_RESET_COLOR}"
}

# Print key-value pair
re_kv() {
    local key="$1"
    local value="$2"
    printf "%s%-30s%s: %s\n" "${RE_BOLD_COLOR}" "$key" "${RE_RESET_COLOR}" "$value"
}

# ============================================================================
# File Operations
# ============================================================================

# Safely create output file with header
re_create_file() {
    local filename="$1"
    local title="$2"

    re_init_debt_file

    local filepath="${RE_OUTPUT_DIR}/${filename}"
    cat > "$filepath" << EOF
# ${title}

Generated by technical-analyst reverse engineering agent.
Date: $(date '+%Y-%m-%d %H:%M:%S')

---

EOF

    echo "$filepath"
}

# Append to output file
re_append_file() {
    local filepath="$1"
    local content="$2"

    echo -e "$content" >> "$filepath"
}

# ============================================================================
# Codebase Analysis Functions
# ============================================================================

# Count files by extension
re_count_files_by_ext() {
    local root_dir="$1"
    local ext="$2"

    find "$root_dir" -type f -name "*.${ext}" 2>/dev/null | wc -l
}

# Count total lines of code
re_count_loc() {
    local root_dir="$1"

    find "$root_dir" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" \) 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}'
}

# Find configuration files
re_find_config_files() {
    local root_dir="$1"

    find "$root_dir" -type f \( -name "package.json" -o -name "pom.xml" -o -name "build.gradle" -o -name "requirements.txt" -o -name "Cargo.toml" -o -name "go.mod" -o -name ".csproj" -o -name "Makefile" -o -name "docker-compose.yml" -o -name "Dockerfile" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null
}

# Detect primary programming language
re_detect_primary_language() {
    local root_dir="$1"
    local -a langs
    local -a counts

    # Count files for common languages
    langs=("JavaScript" "Python" "Java" "Go" "Rust" "C++" "TypeScript")
    local exts=("js" "py" "java" "go" "rs" "cpp" "ts")

    local max_count=0
    local primary_lang="Unknown"

    for i in "${!langs[@]}"; do
        local count=$(re_count_files_by_ext "$root_dir" "${exts[$i]}")
        if [ "$count" -gt "$max_count" ]; then
            max_count=$count
            primary_lang="${langs[$i]}"
        fi
    done

    echo "$primary_lang"
}

# List directory tree (2 levels deep)
re_show_tree() {
    local root_dir="$1"
    local max_depth="${2:-2}"

    if command -v tree &>/dev/null; then
        tree -L "$max_depth" -I 'node_modules|.git|vendor|.venv' "$root_dir"
    else
        # Fallback: use find
        find "$root_dir" -maxdepth "$max_depth" -type d -not -path '*/\.*' | sort | sed 's|[^/]*/| |g'
    fi
}

# ============================================================================
# Validation Functions
# ============================================================================

# Check if path is valid and readable
re_validate_path() {
    local path="$1"

    if [ ! -d "$path" ]; then
        re_error "Path does not exist: $path"
        return 1
    fi

    if [ ! -r "$path" ]; then
        re_error "Path is not readable: $path"
        return 1
    fi

    return 0
}

# Check if file exists and is readable
re_validate_file() {
    local filepath="$1"

    if [ ! -f "$filepath" ]; then
        re_error "File does not exist: $filepath"
        return 1
    fi

    if [ ! -r "$filepath" ]; then
        re_error "File is not readable: $filepath"
        return 1
    fi

    return 0
}

# ============================================================================
# JSON/YAML Parsing (Simple)
# ============================================================================

# Extract JSON value by key (simple grep-based, not full parser)
re_json_get() {
    local json_file="$1"
    local key="$2"

    grep "\"${key}\"" "$json_file" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)".*/\1/'
}

# Extract dependencies from package.json
re_get_npm_deps() {
    local package_json="$1"

    if [ -f "$package_json" ]; then
        grep -A 100 '"dependencies"' "$package_json" | grep '":' | head -20
    fi
}

# ============================================================================
# Error Handling
# ============================================================================

# Trap and log errors
re_log_error() {
    local line_num="$1"
    local error_msg="$2"

    re_error "Error at line ${line_num}: ${error_msg}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error at line ${line_num}: ${error_msg}" >> "${RE_OUTPUT_DIR}/ERRORS.log"
}

# ============================================================================
# Export functions for use in subshells
# ============================================================================

export -f to_lower
export -f to_upper
export -f is_yes
export -f is_no
export -f re_ask
export -f re_ask_yn
export -f re_ask_choice
export -f re_confirm_save
export -f re_init_debt_file
export -f re_current_debt_count
export -f re_add_debt
export -f re_banner
export -f re_success_rule
export -f re_dim
export -f re_success
export -f re_error
export -f re_warning
export -f re_info
export -f re_kv
export -f re_create_file
export -f re_append_file
export -f re_count_files_by_ext
export -f re_count_loc
export -f re_find_config_files
export -f re_detect_primary_language
export -f re_show_tree
export -f re_validate_path
export -f re_validate_file
export -f re_json_get
export -f re_get_npm_deps
export -f re_log_error

# ═════════════════════════════════════════════════════════════════════════════
# AUTO-MODE HELPERS — added by IMPROVEMENT-PLAN.md Step 1
#
# Adds a dual-mode (interactive + non-interactive/auto) layer on top of the
# existing re_ask / _ask_yn / _ask_choice / _add_debt helpers. Scripts
# that want auto support call re_get / _get_yn / _get_choice with a
# stable KEY and pick up values from (in priority order):
#
#   1. an environment variable named $KEY
#   2. the --answers <file> (KEY=VALUE pairs)
#   3. any configured upstream extract files
#   4. the documented default
#   5. interactive prompt — only when not in auto mode
#
# Activation: pass --auto on the CLI (via re_parse_flags "$@") or set
# RE_AUTO=1 in the environment. See IMPROVEMENT-PLAN.md for the full
# contract.
# ═════════════════════════════════════════════════════════════════════════════

# ── Auto-mode state ──────────────────────────────────────────────────────────
: "${RE_AUTO:=0}"; export RE_AUTO
: "${RE_ANSWERS:=}"; export RE_ANSWERS

# Upstream-extract search paths. Agents that read upstream output should
# append to this array from their phase scripts, e.g.:
#   CQR_UPSTREAM_EXTRACTS+=("$DEV_OUTPUT_DIR/02-coding-plan.extract")
if [ -z "${RE_UPSTREAM_EXTRACTS+x}" ]; then
  RE_UPSTREAM_EXTRACTS=()
fi

# ── CLI flag parser ──────────────────────────────────────────────────────────
# Phase scripts should call:  re_parse_flags "$@"
# Recognised: --auto, --answers <file>, --answers=<file>. Unknown flags are
# ignored so the helper composes with scripts that have their own arg parsing.
re_parse_flags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto)        RE_AUTO=1; export RE_AUTO; shift ;;
      --answers)     RE_ANSWERS="${2:-}"; export RE_ANSWERS; shift 2 ;;
      --answers=*)   RE_ANSWERS="${1#--answers=}"; export RE_ANSWERS; shift ;;
      *)             shift ;;
    esac
  done
}

# ── Auto-mode predicate ──────────────────────────────────────────────────────
re_is_auto() {
  case "${RE_AUTO:-0}" in
    1|true|TRUE|True|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Extract-file reader ──────────────────────────────────────────────────────
# Reads KEY=VALUE pairs (one per line, `#` comments allowed) from the given
# file. Echoes the value for the requested key, or empty.
re_read_extract() {
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
# re_resolve <KEY> [default]
# Priority: env var → answers file → upstream extracts → default. Echoes the
# resolved value, or empty if none and no default.
re_resolve() {
  local key="$1" default="${2:-}"
  local val=""
  # 1) Env var named exactly $key
  eval "val=\"\${$key:-}\""
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  # 2) Answers file
  if [ -n "${RE_ANSWERS:-}" ] && [ -f "${RE_ANSWERS}" ]; then
    val=$(re_read_extract "${RE_ANSWERS}" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  fi
  # 3) Upstream extracts (first match wins)
  local f
  for f in ${RE_UPSTREAM_EXTRACTS[@]+"${RE_UPSTREAM_EXTRACTS[@]}"}; do
    [ -z "$f" ] && continue
    val=$(re_read_extract "$f" "$key")
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  done
  # 4) Default
  printf '%s' "$default"
}

# ── Auto-mode debt logger ────────────────────────────────────────────────────
# re_add_debt_auto <area> <title> <description> <impact>
# Maps the standard 4-arg (area/title/description/impact) shape onto RE's
# native re_add_debt(title, file_path, line_range, debt_type, evidence,
# impact, recommendation) signature with sensible defaults for unattended runs.
re_add_debt_auto() {
  local area="$1" title="$2" description="$3" impact="$4"
  re_add_debt "[${area}] ${title}" "auto-resolve" "N/A" "Auto-resolve" \
    "${description}" "${impact}" "Review and resolve manually"
}

# ── Unified getters (interactive + auto) ─────────────────────────────────────
# re_get <KEY> <prompt> [default]
re_get() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(re_resolve "$key" "$default")
  if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
  if re_is_auto; then
    if [ -z "$default" ]; then
      re_add_debt_auto "Auto-resolve" "Missing answer: $key" \
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
  val=$(re_ask "$prompt")
  [ -z "$val" ] && val="$default"
  printf '%s' "$val"
}

# re_get_yn <KEY> <prompt> [default_yes_or_no]
re_get_yn() {
  local key="$1" prompt="$2" default="${3:-}"
  local val
  val=$(re_resolve "$key" "$default")
  case "$(to_lower "$val")" in
    y|yes|true|1)  printf 'yes'; return 0 ;;
    n|no|false|0)  printf 'no';  return 0 ;;
  esac
  if re_is_auto; then
    case "$(to_lower "$default")" in
      y|yes|true|1) printf 'yes'; return 0 ;;
      n|no|false|0) printf 'no';  return 0 ;;
    esac
    re_add_debt_auto "Auto-resolve" "Missing y/n: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode, and no default is documented" \
      "Defaulting to 'no'"
    printf 'no'
    return 0
  fi
  re_ask_yn "$prompt"
}

# re_get_choice <KEY> <prompt> <opt1> <opt2> ...
# Auto mode: match resolved value (exact or prefix) against options; if no
# match, first option is used and a debt is logged.
re_get_choice() {
  local key="$1" prompt="$2"; shift 2
  local options=("$@")
  local val opt
  val=$(re_resolve "$key" "")
  if [ -n "$val" ]; then
    for opt in "${options[@]}"; do
      if [ "$opt" = "$val" ]; then printf '%s' "$opt"; return 0; fi
    done
    for opt in "${options[@]}"; do
      case "$opt" in "$val"*) printf '%s' "$opt"; return 0 ;; esac
    done
    if re_is_auto; then
      re_add_debt_auto "Auto-resolve" "Unmatched choice for $key" \
        "Resolved value '$val' does not match any known option" \
        "Defaulting to first option: ${options[0]}"
      printf '%s' "${options[0]}"
      return 0
    fi
  fi
  if re_is_auto; then
    re_add_debt_auto "Auto-resolve" "Missing choice: $key" \
      "Could not resolve '$key' from env/answers/upstream in auto mode" \
      "Defaulting to first option: ${options[0]}"
    printf '%s' "${options[0]}"
    return 0
  fi
  re_ask_choice "$prompt" "${options[@]}"
}

# ── Extract-file writer ──────────────────────────────────────────────────────
# re_write_extract <output_path> <KEY1=VAL1> <KEY2=VAL2> ...
# Writes a machine-readable companion file alongside the markdown output so
# downstream agents can read structured answers without re-parsing markdown.
re_write_extract() {
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
_re_ask_orig()        { true; }   # placeholder, replaced below
_re_ask_yn_orig()     { true; }
_re_ask_choice_orig() { true; }
# Capture originals once, then replace with auto-aware wrappers.
if ! declare -f _re_ask_orig_real >/dev/null 2>&1 && declare -f re_ask >/dev/null 2>&1; then
  eval "_re_ask_orig_real()        $(declare -f re_ask | sed '1d')"
  eval "_re_ask_yn_orig_real()     $(declare -f re_ask_yn | sed '1d')"
  eval "_re_ask_choice_orig_real() $(declare -f re_ask_choice | sed '1d')"

  re_ask() {
    if re_is_auto; then printf ''; return 0; fi
    _re_ask_orig_real "$@"
  }
  re_ask_yn() {
    if re_is_auto; then printf 'no'; return 0; fi
    _re_ask_yn_orig_real "$@"
  }
  re_ask_choice() {
    if re_is_auto; then
      # Auto mode: return the first option
      local prompt="$1"; shift
      printf '%s' "${1:-}"
      return 0
    fi
    _re_ask_choice_orig_real "$@"
  }
fi


# Auto-aware re_confirm_save
if declare -f re_confirm_save >/dev/null 2>&1; then
  eval "_re_confirm_save_orig_real() $(declare -f re_confirm_save | sed '1d')"
  re_confirm_save() {
    if re_is_auto; then
      # In auto mode, auto-confirm (skip redo loops).
      printf 'yes'
      return 0
    fi
    _re_confirm_save_orig_real "$@"
  }
fi
