#!/bin/bash
#
# lowkey-agents installer (Bash 3.2+, macOS/Linux)
# Installs 13 agents and 79 skills to 25+ AI coding platforms
#
# Usage:
#   ./install.sh                          # Interactive mode
#   ./install.sh --target /path/to/proj   # Non-interactive
#   ./install.sh --help                   # Show help
#   ./install.sh --force --target /path   # Skip confirmations
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
AGENT_COUNT=0
SKILL_COUNT=0

# Flags
TARGET_PATH=""
FORCE_MODE=0
HELP_MODE=0

# Installation results (set by copy_* functions)
AGENTS_INSTALLED=0
AGENTS_SKIPPED=0
SKILLS_INSTALLED=0
SKILLS_SKIPPED=0
TOTAL_AGENTS_INSTALLED=0
TOTAL_AGENTS_SKIPPED=0
TOTAL_SKILLS_INSTALLED=0
TOTAL_SKILLS_SKIPPED=0

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

# Colors and formatting functions
print_banner() {
    printf "\n${BOLD}${CYAN}"
    printf "╔════════════════════════════════════════════════════════╗\n"
    printf "║           LOWKEY-AGENTS INSTALLER                      ║\n"
    printf "║   14 Agents + 79 Skills for 25+ AI Coding Platforms    ║\n"
    printf "║   Developed by Dau Quang Thanh                         ║\n"
    printf "║   Version 2.0 — Production Ready                       ║\n"
    printf "╚════════════════════════════════════════════════════════╝\n"
    printf "${NC}\n"
}

print_help() {
    cat << 'EOF'
Usage: ./install.sh [OPTIONS]

OPTIONS:
  --target <path>     Target project path (non-interactive)
  --force             Skip all confirmation prompts
  --help              Show this help message

EXAMPLES:
  Interactive mode:
    ./install.sh

  Non-interactive with target path:
    ./install.sh --target ~/my-project

  Force installation without prompts:
    ./install.sh --force --target ~/my-project

SUPPORTED PLATFORMS (25 total):
  - Amp (.amp/)
  - Antigravity (.agent/)
  - Augment Code (.augment/)
  - Claude Code (.claude/) - most common
  - Cline (.cline/)
  - CodeBuddy (.codebuddy/)
  - Codex CLI (.codex/)
  - Cursor (.cursor/)
  - Forge (.forge/)
  - Gemini CLI (.gemini/)
  - GitHub Copilot (IDE) (.github/)
  - GitHub Copilot CLI (.copilot/)
  - IBM Bob (.bob/)
  - Junie (.junie/)
  - Kilo Code (.kilocode/)
  - Kiro (.kiro/)
  - Mistral Vibe (.vibe/)
  - opencode (.opencode/)
  - Pi Agent (.omp/)
  - Qoder (.qoder/)
  - Qwen Code (.qwen/)
  - Roo Code (.roo/)
  - Tabnine (.tabnine/)
  - Trae (.trae/)
  - Windsurf (.windsurf/)

If none detected, you'll be prompted to choose or default to .claude/

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

    AGENT_COUNT=$(find "$AGENTS_SRC" -maxdepth 1 -type f -name "*.md" | wc -l)
    SKILL_COUNT=$(find "$SKILLS_SRC" -maxdepth 1 -type d -mindepth 1 | wc -l)

    print_success "Found $AGENT_COUNT agents and $SKILL_COUNT skills in source"
}

# Prompt user for target path if not provided
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

# Detect all IDE/framework directories in target project
find_ide_dirs() {
    local target="$1"
    local found_dirs=()
    local platform_entry
    local config_dir

    # Check all platforms defined by PLATFORMS array
    for platform_entry in "${PLATFORMS[@]}"; do
        config_dir="${platform_entry%%:*}"
        if [[ -d "$target/$config_dir" ]]; then
            found_dirs+=("$config_dir")
        fi
    done

    echo "${found_dirs[@]}"
}

# Ask user which IDE/framework to use
choose_ide_dir() {
    if [[ $FORCE_MODE -eq 1 ]]; then
        echo ".claude"
        return
    fi

    printf "\n${BOLD}No IDE framework directory detected${NC}\n"
    printf "Which framework would you like to use?\n\n"
    printf "  ${CYAN}Popular Platforms:${NC}\n"
    printf "  ${CYAN}1${NC}) .claude/     (Claude Code - recommended)\n"
    printf "  ${CYAN}2${NC}) .cursor/     (Cursor)\n"
    printf "  ${CYAN}3${NC}) .windsurf/   (Windsurf)\n"
    printf "  ${CYAN}4${NC}) .github/     (GitHub Copilot IDE)\n"
    printf "  ${CYAN}5${NC}) .copilot/    (GitHub Copilot CLI)\n"
    printf "  ${CYAN}6${NC}) .cline/      (Cline)\n"
    printf "  ${CYAN}7${NC}) .roo/        (Roo Code)\n"
    printf "  ${CYAN}8${NC}) .opencode/   (opencode)\n\n"
    printf "  ${CYAN}More Platforms:${NC}\n"
    printf "  ${CYAN}9${NC}) .codex/      (Codex CLI)\n"
    printf "  ${CYAN}10${NC}) .gemini/     (Gemini CLI)\n"
    printf "  ${CYAN}11${NC}) .amp/        (Amp)\n"
    printf "  ${CYAN}12${NC}) .augment/    (Augment Code)\n"
    printf "  ${CYAN}13${NC}) .agent/      (Antigravity)\n"
    printf "  ${CYAN}14${NC}) .bob/        (IBM Bob)\n"
    printf "  ${CYAN}15${NC}) .codebuddy/  (CodeBuddy)\n"
    printf "  ${CYAN}16${NC}) .forge/      (Forge)\n"
    printf "  ${CYAN}17${NC}) .junie/      (Junie)\n"
    printf "  ${CYAN}18${NC}) .kilocode/   (Kilo Code)\n"
    printf "  ${CYAN}19${NC}) .kiro/       (Kiro)\n"
    printf "  ${CYAN}20${NC}) .omp/        (Pi Agent)\n"
    printf "  ${CYAN}21${NC}) .qoder/      (Qoder)\n"
    printf "  ${CYAN}22${NC}) .qwen/       (Qwen Code)\n"
    printf "  ${CYAN}23${NC}) .tabnine/    (Tabnine)\n"
    printf "  ${CYAN}24${NC}) .trae/       (Trae)\n"
    printf "  ${CYAN}25${NC}) .vibe/       (Mistral Vibe)\n\n"

    read -p "Choose (1-25, default=1): " choice
    choice="${choice:-1}"

    # Map choice to platform entry
    local idx=$((choice - 1))
    if [[ $idx -ge 0 ]] && [[ $idx -lt ${#PLATFORMS[@]} ]]; then
        local platform_entry="${PLATFORMS[$idx]}"
        echo "${platform_entry%%:*}"
    else
        echo ".claude"
    fi
}

# Show installation summary
show_summary() {
    local target="$1"
    shift
    local ide_dirs=("$@")

    printf "\n${BOLD}Installation Summary${NC}\n"
    printf "${DIM}─────────────────────────────────────${NC}\n"
    print_info "Target project: $target"

    printf "\n${BOLD}Target IDE frameworks (${#ide_dirs[@]}):${NC}\n"
    for ide_dir in "${ide_dirs[@]}"; do
        local display_name=$(get_display_name "$ide_dir")
        local agents_subdir=$(get_agents_subdir "$ide_dir")
        printf "  • ${CYAN}$display_name${NC} ($ide_dir/) → $ide_dir/$agents_subdir/ + $ide_dir/skills/\n"
    done

    printf "\n${BOLD}What will be installed to each:${NC}\n"
    printf "  ${CYAN}Agents:${NC} $AGENT_COUNT files\n"

    # List agents
    find "$AGENTS_SRC" -maxdepth 1 -type f -name "*.md" -exec basename {} \; | \
        sed 's/\.md$//' | sort | while read agent; do
        printf "    • $agent\n"
    done

    printf "\n  ${CYAN}Skills:${NC} $SKILL_COUNT directories\n"
    printf "    (All skill directories with SKILL.md and scripts/)\n"
    printf "\n"
}

# Confirm with user before installation
confirm_installation() {
    if [[ $FORCE_MODE -eq 1 ]]; then
        return 0
    fi

    printf "${YELLOW}Proceed with installation?${NC} (y/n) "
    read -r confirm
    case "$confirm" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Ask about overwriting a file
ask_overwrite() {
    local filename="$1"
    local all_mode="$2"

    if [[ $FORCE_MODE -eq 1 ]] || [[ "$all_mode" == "all" ]]; then
        echo "all"
        return
    fi

    printf "${YELLOW}%s already exists. Overwrite?${NC} (y/n/all) " "$filename" >&2
    read -r response </dev/tty
    echo "$response"
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

# Copy agents to target
copy_agents() {
    local target="$1"
    local ide_dir="$2"
    local agents_subdir=$(get_agents_subdir "$ide_dir")
    local target_agents="$target/$ide_dir/$agents_subdir"
    local all_overwrite="no"
    local agents_installed=0
    local agents_skipped=0

    mkdir -p "$target_agents" 2>/dev/null

    for agent_file in "$AGENTS_SRC"/*.md; do
        local filename=$(basename "$agent_file")
        local target_file="$target_agents/$filename"

        if [[ -f "$target_file" ]]; then
            local response=$(ask_overwrite "$filename" "$all_overwrite")
            case "$response" in
                all)
                    all_overwrite="all"
                    cp "$agent_file" "$target_file" 2>/dev/null
                    print_success "Installed agent: ${filename%.md}"
                    ((agents_installed++))
                    ;;
                [yY][eE][sS]|[yY])
                    cp "$agent_file" "$target_file" 2>/dev/null
                    print_success "Installed agent: ${filename%.md}"
                    ((agents_installed++))
                    ;;
                *)
                    print_warning "Skipped agent: ${filename%.md}"
                    ((agents_skipped++))
                    ;;
            esac
        else
            cp "$agent_file" "$target_file" 2>/dev/null
            print_success "Installed agent: ${filename%.md}"
            ((agents_installed++))
        fi
    done

    # Store results in globals for main() to access
    AGENTS_INSTALLED=$agents_installed
    AGENTS_SKIPPED=$agents_skipped
}

# Copy skills to target
copy_skills() {
    local target="$1"
    local ide_dir="$2"
    local target_skills="$target/$ide_dir/skills"
    local all_overwrite="no"
    local skills_installed=0
    local skills_skipped=0

    mkdir -p "$target_skills" 2>/dev/null

    for skill_dir in "$SKILLS_SRC"/*/; do
        local skill_name=$(basename "$skill_dir")
        local target_skill="$target_skills/$skill_name"

        if [[ -d "$target_skill" ]]; then
            local response=$(ask_overwrite "$skill_name/" "$all_overwrite")
            case "$response" in
                all)
                    all_overwrite="all"
                    rm -rf "$target_skill" 2>/dev/null
                    cp -r "$skill_dir" "$target_skill" 2>/dev/null
                    print_success "Installed skill: $skill_name"
                    ((skills_installed++))
                    ;;
                [yY][eE][sS]|[yY])
                    rm -rf "$target_skill" 2>/dev/null
                    cp -r "$skill_dir" "$target_skill" 2>/dev/null
                    print_success "Installed skill: $skill_name"
                    ((skills_installed++))
                    ;;
                *)
                    print_warning "Skipped skill: $skill_name"
                    ((skills_skipped++))
                    ;;
            esac
        else
            cp -r "$skill_dir" "$target_skill" 2>/dev/null
            print_success "Installed skill: $skill_name"
            ((skills_installed++))
        fi
    done

    # Store results in globals for main() to access
    SKILLS_INSTALLED=$skills_installed
    SKILLS_SKIPPED=$skills_skipped
}

# Get display name for IDE config directory
get_display_name() {
    local config_dir="$1"
    local platform_entry

    for platform_entry in "${PLATFORMS[@]}"; do
        if [[ "${platform_entry%%:*}" == "$config_dir" ]]; then
            local display_name="${platform_entry#*:}"
            echo "${display_name%%:*}"
            return
        fi
    done

    echo "$config_dir"
}

# Show installation completion summary
show_completion() {
    local agents_installed="$1"
    local agents_skipped="$2"
    local skills_installed="$3"
    local skills_skipped="$4"
    local target="$5"
    shift 5
    local ide_dirs=("$@")

    printf "\n${BOLD}${GREEN}Installation Complete!${NC}\n"
    printf "${DIM}─────────────────────────────────────${NC}\n"
    printf "  Agents installed: ${GREEN}$agents_installed${NC}\n"
    if [[ $agents_skipped -gt 0 ]]; then
        printf "  Agents skipped: ${YELLOW}$agents_skipped${NC}\n"
    fi
    printf "  Skills installed: ${GREEN}$skills_installed${NC}\n"
    if [[ $skills_skipped -gt 0 ]]; then
        printf "  Skills skipped: ${YELLOW}$skills_skipped${NC}\n"
    fi
    printf "\n${BOLD}Installed to:${NC}\n"
    for ide_dir in "${ide_dirs[@]}"; do
        local display_name=$(get_display_name "$ide_dir")
        printf "  • $target/$ide_dir/ ($display_name)\n"
    done
    printf "\n${DIM}Next steps:${NC}\n"
    printf "  1. Review installed agents and skills in each IDE directory\n"
    printf "  2. Start with the business-analyst or architect agent\n"
    printf "  3. See AGENT-TEAM-EXECUTION-ORDER.md for workflow\n\n"
}

# Offer to cd into the target folder after installation
prompt_change_directory() {
    local target="$1"
    local abs_target
    abs_target="$(cd "$target" && pwd)"

    # Skip if already there
    if [[ "$(pwd)" == "$abs_target" ]]; then
        return
    fi

    if [[ $FORCE_MODE -eq 1 ]]; then
        printf "${DIM}To change directory, run:${NC}\n"
        printf "  ${CYAN}cd %s${NC}\n\n" "$abs_target"
        return
    fi

    printf "${YELLOW}Change directory to target folder?${NC} (y/n) "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            print_info "Opening a new shell in: $abs_target"
            print_info "(Type 'exit' to return to your previous shell)"
            cd "$abs_target" && exec "${SHELL:-/bin/bash}"
            ;;
        *)
            printf "${DIM}To change directory manually, run:${NC}\n"
            printf "  ${CYAN}cd %s${NC}\n\n" "$abs_target"
            ;;
    esac
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

    # Detect all IDE directories in target
    local ide_dirs_str=$(find_ide_dirs "$TARGET_PATH")
    local ide_dirs=($ide_dirs_str)

    if [[ ${#ide_dirs[@]} -eq 0 ]]; then
        # No IDE directories found — let user choose one to create
        local chosen=$(choose_ide_dir)
        ide_dirs=("$chosen")
        print_info "Will create $chosen/ directory"
    else
        printf "\n${BOLD}Detected IDE frameworks:${NC}\n"
        for dir in "${ide_dirs[@]}"; do
            local display_name=$(get_display_name "$dir")
            print_success "  $display_name ($dir/)"
        done
    fi

    show_summary "$TARGET_PATH" "${ide_dirs[@]}"

    if ! confirm_installation; then
        print_warning "Installation cancelled"
        exit 0
    fi

    printf "\n${BOLD}Installing...${NC}\n"

    for ide_dir in "${ide_dirs[@]}"; do
        local display_name=$(get_display_name "$ide_dir")
        printf "\n${BOLD}${CYAN}── $display_name ($ide_dir/) ──${NC}\n\n"

        # Reset per-IDE counters
        AGENTS_INSTALLED=0
        AGENTS_SKIPPED=0
        SKILLS_INSTALLED=0
        SKILLS_SKIPPED=0

        copy_agents "$TARGET_PATH" "$ide_dir"
        printf "\n"
        copy_skills "$TARGET_PATH" "$ide_dir"

        TOTAL_AGENTS_INSTALLED=$((TOTAL_AGENTS_INSTALLED + AGENTS_INSTALLED))
        TOTAL_AGENTS_SKIPPED=$((TOTAL_AGENTS_SKIPPED + AGENTS_SKIPPED))
        TOTAL_SKILLS_INSTALLED=$((TOTAL_SKILLS_INSTALLED + SKILLS_INSTALLED))
        TOTAL_SKILLS_SKIPPED=$((TOTAL_SKILLS_SKIPPED + SKILLS_SKIPPED))
    done

    show_completion "$TOTAL_AGENTS_INSTALLED" "$TOTAL_AGENTS_SKIPPED" "$TOTAL_SKILLS_INSTALLED" "$TOTAL_SKILLS_SKIPPED" "$TARGET_PATH" "${ide_dirs[@]}"

    prompt_change_directory "$TARGET_PATH"
}

main "$@"
