#!/bin/bash
#
# lowkey-agents uninstaller (Bash 3.2+, macOS/Linux)
# Removes 13 agents and 79 skills from 25+ AI coding platforms
#
# Usage:
#   ./uninstall.sh                          # Interactive mode
#   ./uninstall.sh --target /path/to/proj   # Non-interactive
#   ./uninstall.sh --help                   # Show help
#   ./uninstall.sh --force --target /path   # Skip confirmations
#

set -u

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Script directory and source paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC="${SCRIPT_DIR}/agents"
SKILLS_SRC="${SCRIPT_DIR}/skills"

# Flags
TARGET_PATH=""
FORCE_MODE=0
HELP_MODE=0

# Output counters
AGENTS_REMOVED=0
AGENTS_NOTFOUND=0
SKILLS_REMOVED=0
SKILLS_NOTFOUND=0

# Platform data array: "config_dir:display_name:agents_subdir"
# Priority order for detection: most common first
readonly PLATFORMS=(
  ".claude:Claude Code:agents"
  ".cursor:Cursor:agents"
  ".windsurf:Windsurf:agents"
  ".github:GitHub Copilot (IDE):agents"
  ".copilot:GitHub Copilot CLI:agents"
  ".cline:Cline:agents"
  ".roo:Roo Code:agents"
  ".opencode:opencode:agents"
  ".codex:Codex CLI:agents"
  ".gemini:Gemini CLI:agents"
  ".amp:Amp:agents"
  ".augment:Augment Code:agents"
  ".agent:Antigravity:workflows"
  ".bob:IBM Bob:agents"
  ".codebuddy:CodeBuddy:agents"
  ".forge:Forge:agents"
  ".junie:Junie:agents"
  ".kilocode:Kilo Code:agents"
  ".kiro:Kiro:agents"
  ".omp:Pi Agent:agents"
  ".qoder:Qoder:agents"
  ".qwen:Qwen Code:agents"
  ".tabnine:Tabnine:agents"
  ".trae:Trae:agents"
  ".vibe:Mistral Vibe:agents"
)

print_banner() {
    printf "\n${BOLD}${CYAN}"
    printf "╔════════════════════════════════════════════════════════╗\n"
    printf "║         LOWKEY-AGENTS UNINSTALLER                      ║\n"
    printf "║   Remove 14 Agents + 79 Skills from 25+ AI Platforms   ║\n"
    printf "║   Developed by Dau Quang Thanh                         ║\n"
    printf "║   Version 2.0 — Production Ready                       ║\n"
    printf "╚════════════════════════════════════════════════════════╝\n"
    printf "${NC}\n"
}

print_help() {
    cat << 'EOF'
Usage: ./uninstall.sh [OPTIONS]

OPTIONS:
  --target <path>     Target project path (non-interactive)
  --force             Skip all confirmation prompts
  --help              Show this help message

EXAMPLES:
  Interactive mode:
    ./uninstall.sh

  Non-interactive with target path:
    ./uninstall.sh --target ~/my-project

  Force removal without prompts:
    ./uninstall.sh --force --target ~/my-project

NOTE:
  This script only removes lowkey-agents files that match names
  in the source. It never deletes the IDE config directory itself
  (e.g., .claude/, .windsurf/, etc.)

EOF
}

print_success() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}✗${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

print_info() {
    printf "${BLUE}ℹ${NC} %s\n" "$1"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)
                TARGET_PATH="$2"
                shift 2
                ;;
            --force)
                FORCE_MODE=1
                shift
                ;;
            --help)
                HELP_MODE=1
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Validate that source directories exist
validate_source_dirs() {
    if [[ ! -d "$AGENTS_SRC" ]]; then
        print_error "Agents directory not found: $AGENTS_SRC"
        exit 1
    fi

    if [[ ! -d "$SKILLS_SRC" ]]; then
        print_error "Skills directory not found: $SKILLS_SRC"
        exit 1
    fi
}

# Prompt user for target path
get_target_path() {
    if [[ -z "$TARGET_PATH" ]]; then
        printf "\n${BOLD}Target Project Path${NC}\n"
        printf "Enter the path to your target project (or press Enter for current directory):\n"
        read -p "> " user_target
        TARGET_PATH="${user_target:-.}"
    fi

    # Expand ~ to home directory
    TARGET_PATH="${TARGET_PATH/#\~/$HOME}"

    # Check if path exists
    if [[ ! -d "$TARGET_PATH" ]]; then
        print_error "Path does not exist: $TARGET_PATH"
        exit 1
    fi

    print_success "Target path: $TARGET_PATH"
}

# Find IDE directories in target
find_ide_dirs() {
    local target="$1"
    local found_dirs=()
    local platform_entry
    local config_dir

    # Check in priority order defined by PLATFORMS array
    for platform_entry in "${PLATFORMS[@]}"; do
        config_dir="${platform_entry%%:*}"
        if [[ -d "$target/$config_dir" ]]; then
            found_dirs+=("$config_dir")
        fi
    done

    echo "${found_dirs[@]}"
}

# Get agents subdirectory for a given config directory
get_agents_subdir() {
    local config_dir="$1"
    local platform_entry

    for platform_entry in "${PLATFORMS[@]}"; do
        if [[ "${platform_entry%%:*}" == "$config_dir" ]]; then
            echo "${platform_entry##*:}"
            return
        fi
    done

    # Default to "agents" if not found
    echo "agents"
}

# Show what will be removed
show_removal_summary() {
    local target="$1"
    shift
    local ide_dirs=("$@")

    printf "\n${BOLD}Removal Summary${NC}\n"
    printf "${DIM}─────────────────────────────────────${NC}\n"
    print_info "Target project: $target"
    printf "\n${BOLD}IDE frameworks found:${NC}\n"
    for dir in "${ide_dirs[@]}"; do
        printf "  • $dir/\n"
    done

    printf "\n${BOLD}Files that will be removed:${NC}\n"
    printf "  ${CYAN}Agents:${NC}\n"
    find "$AGENTS_SRC" -maxdepth 1 -type f -name "*.md" -exec basename {} \; | \
        sed 's/\.md$//' | sort | while read agent; do
        printf "    • $agent\n"
    done

    printf "\n  ${CYAN}Skills:${NC}\n"
    find "$SKILLS_SRC" -maxdepth 1 -type d -mindepth 1 -exec basename {} \; | \
        sort | while read skill; do
        printf "    • $skill/\n"
    done
    printf "\n"
}

# Confirm with user before removal
confirm_removal() {
    if [[ $FORCE_MODE -eq 1 ]]; then
        return 0
    fi

    printf "${YELLOW}Proceed with removal?${NC} This action cannot be undone. (y/n) "
    read -r confirm
    case "$confirm" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Remove agents from all found IDE directories
remove_agents() {
    local target="$1"
    shift
    local ide_dirs=("$@")

    for ide_dir in "${ide_dirs[@]}"; do
        local agents_subdir=$(get_agents_subdir "$ide_dir")
        local agents_path="$target/$ide_dir/$agents_subdir"

        if [[ ! -d "$agents_path" ]]; then
            continue
        fi

        for agent_file in "$AGENTS_SRC"/*.md; do
            local filename=$(basename "$agent_file")
            local target_file="$agents_path/$filename"

            if [[ -f "$target_file" ]]; then
                rm "$target_file"
                print_success "Removed agent: $filename (from $ide_dir/)"
                ((AGENTS_REMOVED++))
            else
                ((AGENTS_NOTFOUND++))
            fi
        done
    done
}

# Remove skills from all found IDE directories
remove_skills() {
    local target="$1"
    shift
    local ide_dirs=("$@")

    for ide_dir in "${ide_dirs[@]}"; do
        local skills_path="$target/$ide_dir/skills"

        if [[ ! -d "$skills_path" ]]; then
            continue
        fi

        for skill_dir in "$SKILLS_SRC"/*/; do
            local skill_name=$(basename "$skill_dir")
            local target_skill="$skills_path/$skill_name"

            if [[ -d "$target_skill" ]]; then
                rm -rf "$target_skill"
                print_success "Removed skill: $skill_name (from $ide_dir/)"
                ((SKILLS_REMOVED++))
            else
                ((SKILLS_NOTFOUND++))
            fi
        done
    done
}

# Show removal completion summary
show_completion() {
    local target="$1"

    printf "\n${BOLD}${GREEN}Removal Complete!${NC}\n"
    printf "${DIM}─────────────────────────────────────${NC}\n"
    printf "  Agents removed: ${GREEN}$AGENTS_REMOVED${NC}\n"
    if [[ $AGENTS_NOTFOUND -gt 0 ]]; then
        printf "  Agents not found: ${DIM}$AGENTS_NOTFOUND${NC}\n"
    fi
    printf "  Skills removed: ${GREEN}$SKILLS_REMOVED${NC}\n"
    if [[ $SKILLS_NOTFOUND -gt 0 ]]; then
        printf "  Skills not found: ${DIM}$SKILLS_NOTFOUND${NC}\n"
    fi
    printf "\n${BOLD}Removal from:${NC} $target/\n"
    printf "\n${DIM}Next steps:${NC}\n"
    printf "  • IDE configuration directories (.claude/, .windsurf/, etc) were left in place\n"
    printf "  • You can safely delete them manually if needed\n"
    printf "  • To reinstall, run ./install.sh\n\n"
}

# Main flow
main() {
    parse_args "$@"

    if [[ $HELP_MODE -eq 1 ]]; then
        print_help
        exit 0
    fi

    print_banner
    validate_source_dirs

    get_target_path

    # Find all IDE directories in target
    ide_dirs_str=$(find_ide_dirs "$TARGET_PATH")
    ide_dirs=($ide_dirs_str)

    if [[ ${#ide_dirs[@]} -eq 0 ]]; then
        print_warning "No IDE framework directories found in $TARGET_PATH"
        print_info "Checked for: .claude/, .cursor/, .windsurf/, .github/, .copilot/, .cline/, .roo/, .opencode/, .codex/, .gemini/, .amp/, .augment/, .agent/, .bob/, .codebuddy/, .forge/, .junie/, .kilocode/, .kiro/, .omp/, .qoder/, .qwen/, .tabnine/, .trae/, .vibe/"
        exit 0
    fi

    show_removal_summary "$TARGET_PATH" "${ide_dirs[@]}"

    if ! confirm_removal; then
        print_warning "Removal cancelled"
        exit 0
    fi

    printf "\n${BOLD}Removing...${NC}\n\n"

    remove_agents "$TARGET_PATH" "${ide_dirs[@]}"
    printf "\n"
    remove_skills "$TARGET_PATH" "${ide_dirs[@]}"

    show_completion "$TARGET_PATH"
}

main "$@"
