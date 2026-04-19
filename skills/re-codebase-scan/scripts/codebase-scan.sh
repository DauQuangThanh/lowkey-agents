#!/bin/bash
# Phase 1: Codebase Discovery & Inventory
# Scans directory structure and file types to build an inventory

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

# Step 3: accept --auto / --answers flags
re_parse_flags "$@"


# ============================================================================
# Phase 1 Main Execution
# ============================================================================

re_banner "PHASE 1: CODEBASE DISCOVERY & INVENTORY"

# Initialize output directory and debt file
re_init_debt_file
re_info "Output directory: $RE_OUTPUT_DIR"

# Step 1: Get source code root path
re_info "Gathering information about your codebase..."
SOURCE_ROOT=$(re_get SOURCE_ROOT "What is the root path of the source code?" ".")

if ! re_validate_path "$SOURCE_ROOT"; then
    re_error "Cannot access source code root"
    exit 1
fi

re_success "Source code root: $SOURCE_ROOT"

# Step 2: Ask about primary languages
LANGUAGES=$(re_get LANGUAGES "What are the primary programming languages used?" "JavaScript, Python, Java")
re_success "Primary languages: $LANGUAGES"

# Step 3: Ask about project type
PROJECT_TYPES=("Web Application" "REST API" "Mobile App" "Desktop Application" "Library" "Microservices" "Other")
PROJECT_TYPE=$(re_ask_choice "What is the project type?" "${PROJECT_TYPES[@]}")
re_success "Project type: $PROJECT_TYPE"

# Step 4: Ask about build system
BUILD_SYSTEMS=("npm/yarn" "pip" "Maven" "Gradle" "Cargo" ".NET" "Make" "Other")
BUILD_SYSTEM=$(re_ask_choice "What build system is used?" "${BUILD_SYSTEMS[@]}")
re_success "Build system: $BUILD_SYSTEM"

# Step 5: Ask about repository structure
REPO_STRUCTURE=$(re_ask "Describe the repository structure (monorepo/multi-repo/nested/standard)" "standard")
re_success "Repository structure: $REPO_STRUCTURE"

# Step 6: Ask about known entry points
ENTRY_POINTS=$(re_ask "What are the known entry points? (e.g., main.js, src/App.tsx, etc.)" "")
re_success "Entry points: ${ENTRY_POINTS:-Not specified}"

# Step 7: Ask about existing documentation
HAS_DOCS=$(re_ask_yn "Does existing documentation exist?" "n")
DOC_LOCATIONS=""
if [ "$HAS_DOCS" = "yes" ]; then
    DOC_LOCATIONS=$(re_ask "Where is existing documentation located?" "docs/")
    re_success "Documentation locations: $DOC_LOCATIONS"
fi

# Step 8: Ask about areas to focus/skip
FOCUS_AREAS=$(re_ask "Areas to focus on or skip? (enter 'none' to skip)" "none")
re_success "Focus areas: $FOCUS_AREAS"

# ============================================================================
# Automated Analysis
# ============================================================================

re_info "Starting automated analysis..."

# Create output file
OUTPUT_FILE=$(re_create_file "01-codebase-inventory.md" "Codebase Inventory")

# Count files by extension
re_info "Analyzing file distribution..."
re_append_file "$OUTPUT_FILE" "## File Statistics\n"

# Detect files by extension.
# Parallel indexed arrays (not associative) for bash 3.2 compatibility on macOS.
file_counts_keys=()
file_counts_vals=()
extensions=("js" "ts" "jsx" "tsx" "py" "java" "go" "rs" "cpp" "c" "h" "cs" "rb" "php")

for ext in "${extensions[@]}"; do
    count=$(re_count_files_by_ext "$SOURCE_ROOT" "$ext")
    if [ "$count" -gt 0 ]; then
        file_counts_keys+=("$ext")
        file_counts_vals+=("$count")
    fi
done

# Calculate total LOC
re_info "Counting lines of code..."
TOTAL_LOC=$(re_count_loc "$SOURCE_ROOT")
TOTAL_LOC="${TOTAL_LOC:-0}"

TOTAL_FILES=$(find "$SOURCE_ROOT" -type f -not -path '*/\.*' 2>/dev/null | wc -l)

re_append_file "$OUTPUT_FILE" "- **Total Files**: $TOTAL_FILES\n"
re_append_file "$OUTPUT_FILE" "- **Total Lines of Code**: $(printf "%'d" $TOTAL_LOC)\n"
re_append_file "$OUTPUT_FILE" "- **Primary Language**: $LANGUAGES\n"
re_append_file "$OUTPUT_FILE" "\n"

# File type breakdown
re_append_file "$OUTPUT_FILE" "## Language Breakdown\n\n"
re_append_file "$OUTPUT_FILE" "| Language | Files | % | Est. LOC |\n"
re_append_file "$OUTPUT_FILE" "|----------|-------|---|----------|\n"

for idx in "${!file_counts_keys[@]+"${!file_counts_keys[@]}"}"; do
    ext="${file_counts_keys[$idx]}"
    count="${file_counts_vals[$idx]}"
    percent=$((count * 100 / TOTAL_FILES))
    # Rough LOC estimate (avg 30 LOC per file)
    estimated_loc=$((count * 30))

    lang_name=""
    case "$ext" in
        js|jsx) lang_name="JavaScript" ;;
        ts|tsx) lang_name="TypeScript" ;;
        py) lang_name="Python" ;;
        java) lang_name="Java" ;;
        go) lang_name="Go" ;;
        rs) lang_name="Rust" ;;
        cpp|cc) lang_name="C++" ;;
        c) lang_name="C" ;;
        cs) lang_name="C#" ;;
        rb) lang_name="Ruby" ;;
        php) lang_name="PHP" ;;
        h) lang_name="Header Files" ;;
        *) lang_name="$ext" ;;
    esac

    if [ -n "$lang_name" ]; then
        re_append_file "$OUTPUT_FILE" "| $lang_name | $count | ${percent}% | ~${estimated_loc} |\n"
    fi
done

re_append_file "$OUTPUT_FILE" "\n"

# Directory structure
re_info "Mapping directory structure..."
re_append_file "$OUTPUT_FILE" "## Directory Structure\n\n"
re_append_file "$OUTPUT_FILE" "\`\`\`\n"
if command -v tree &>/dev/null; then
    re_append_file "$OUTPUT_FILE" "$(tree -L 2 -I 'node_modules|.git|vendor|.venv|dist|build' "$SOURCE_ROOT" 2>/dev/null | head -30)\n"
else
    # Fallback: use find
    find "$SOURCE_ROOT" -maxdepth 2 -type d -not -path '*/\.*' | sort | head -30 | sed 's|[^/]*/| |g' >> "$OUTPUT_FILE"
fi
re_append_file "$OUTPUT_FILE" "\`\`\`\n\n"

# Configuration files
re_info "Finding configuration files..."
re_append_file "$OUTPUT_FILE" "## Configuration Files Detected\n\n"

CONFIG_FILES=$(re_find_config_files "$SOURCE_ROOT")
if [ -z "$CONFIG_FILES" ]; then
    re_append_file "$OUTPUT_FILE" "No configuration files found.\n\n"
else
    echo "$CONFIG_FILES" | while read -r config_file; do
        if [ -f "$config_file" ]; then
            basename_config=$(basename "$config_file")
            rel_path=$(echo "$config_file" | sed "s|${SOURCE_ROOT}/||")
            re_append_file "$OUTPUT_FILE" "- \`$rel_path\`\n"
        fi
    done
fi
re_append_file "$OUTPUT_FILE" "\n"

# Framework detection
re_info "Detecting frameworks and libraries..."
re_append_file "$OUTPUT_FILE" "## Frameworks & Libraries Detected\n\n"

# Check for package.json (Node.js)
if [ -f "$SOURCE_ROOT/package.json" ]; then
    re_append_file "$OUTPUT_FILE" "### Node.js Ecosystem\n"
    if command -v jq &>/dev/null; then
        re_append_file "$OUTPUT_FILE" "$(head -20 "$SOURCE_ROOT/package.json")\n\n"
    else
        re_append_file "$OUTPUT_FILE" "- \`package.json\` found (npm/yarn project)\n\n"
    fi
fi

# Check for requirements.txt (Python)
if [ -f "$SOURCE_ROOT/requirements.txt" ]; then
    re_append_file "$OUTPUT_FILE" "### Python Ecosystem\n"
    re_append_file "$OUTPUT_FILE" "- \`requirements.txt\` found (pip project)\n"
    re_append_file "$OUTPUT_FILE" "$(head -10 "$SOURCE_ROOT/requirements.txt")\n\n"
fi

# Check for pom.xml (Maven)
if [ -f "$SOURCE_ROOT/pom.xml" ]; then
    re_append_file "$OUTPUT_FILE" "### Java Ecosystem (Maven)\n"
    re_append_file "$OUTPUT_FILE" "- \`pom.xml\` found (Maven project)\n\n"
fi

# Check for Dockerfile
if [ -f "$SOURCE_ROOT/Dockerfile" ]; then
    re_append_file "$OUTPUT_FILE" "### Docker\n"
    re_append_file "$OUTPUT_FILE" "- \`Dockerfile\` found (containerized application)\n\n"
fi

# Check for docker-compose
if [ -f "$SOURCE_ROOT/docker-compose.yml" ] || [ -f "$SOURCE_ROOT/docker-compose.yaml" ]; then
    re_append_file "$OUTPUT_FILE" "- \`docker-compose.yml\` found (multi-container orchestration)\n\n"
fi

# Entry points summary
re_append_file "$OUTPUT_FILE" "## Entry Points\n\n"
if [ -n "$ENTRY_POINTS" ]; then
    re_append_file "$OUTPUT_FILE" "$ENTRY_POINTS\n\n"
else
    # Try to detect common entry points
    re_append_file "$OUTPUT_FILE" "### Detected Entry Point Candidates\n\n"

    [ -f "$SOURCE_ROOT/src/index.js" ] && re_append_file "$OUTPUT_FILE" "- \`src/index.js\`\n"
    [ -f "$SOURCE_ROOT/src/main.js" ] && re_append_file "$OUTPUT_FILE" "- \`src/main.js\`\n"
    [ -f "$SOURCE_ROOT/src/App.tsx" ] && re_append_file "$OUTPUT_FILE" "- \`src/App.tsx\`\n"
    [ -f "$SOURCE_ROOT/server.js" ] && re_append_file "$OUTPUT_FILE" "- \`server.js\`\n"
    [ -f "$SOURCE_ROOT/main.py" ] && re_append_file "$OUTPUT_FILE" "- \`main.py\`\n"
    [ -f "$SOURCE_ROOT/src/main/java" ] && re_append_file "$OUTPUT_FILE" "- \`src/main/java\`\n"

    re_append_file "$OUTPUT_FILE" "\n"
fi

# Documentation summary
re_append_file "$OUTPUT_FILE" "## Known Documentation\n\n"
if [ "$HAS_DOCS" = "yes" ] && [ -n "$DOC_LOCATIONS" ]; then
    re_append_file "$OUTPUT_FILE" "Documentation found at: \`$DOC_LOCATIONS\`\n\n"

    # List markdown files in docs
    if [ -d "${SOURCE_ROOT}/${DOC_LOCATIONS}" ]; then
        re_append_file "$OUTPUT_FILE" "### Documentation Files\n\n"
        find "${SOURCE_ROOT}/${DOC_LOCATIONS}" -name "*.md" 2>/dev/null | head -10 | while read -r doc; do
            doc_basename=$(basename "$doc")
            re_append_file "$OUTPUT_FILE" "- \`$doc_basename\`\n"
        done
        re_append_file "$OUTPUT_FILE" "\n"
    fi
else
    re_append_file "$OUTPUT_FILE" "No existing documentation found.\n\n"
fi

# Focus areas
re_append_file "$OUTPUT_FILE" "## Focus Areas\n\n"
if [ "$FOCUS_AREAS" != "none" ] && [ -n "$FOCUS_AREAS" ]; then
    re_append_file "$OUTPUT_FILE" "- $FOCUS_AREAS\n\n"
else
    re_append_file "$OUTPUT_FILE" "- Full codebase analysis (no specific areas skipped)\n\n"
fi

# Statistics summary
re_append_file "$OUTPUT_FILE" "## Summary Statistics\n\n"
re_append_file "$OUTPUT_FILE" "| Metric | Value |\n"
re_append_file "$OUTPUT_FILE" "|--------|-------|\n"
re_append_file "$OUTPUT_FILE" "| Total Files | $TOTAL_FILES |\n"
re_append_file "$OUTPUT_FILE" "| Total LOC | $TOTAL_LOC |\n"
re_append_file "$OUTPUT_FILE" "| Project Type | $PROJECT_TYPE |\n"
re_append_file "$OUTPUT_FILE" "| Build System | $BUILD_SYSTEM |\n"
re_append_file "$OUTPUT_FILE" "| Repository Structure | $REPO_STRUCTURE |\n"

# ── Write companion extract so phase 6 can aggregate without re-parsing md ──
{
  echo "# Auto-generated extract — KEY=VALUE per line."
  echo "# Generated: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "SOURCE_ROOT=$SOURCE_ROOT"
  echo "LANGUAGES=$LANGUAGES"
  echo "PRIMARY_LANGUAGE=$LANGUAGES"
  echo "TOTAL_FILES=$TOTAL_FILES"
  echo "TOTAL_LOC=$TOTAL_LOC"
  echo "PROJECT_TYPE=$PROJECT_TYPE"
  echo "BUILD_SYSTEM=$BUILD_SYSTEM"
  echo "REPO_STRUCTURE=$REPO_STRUCTURE"
} > "${OUTPUT_FILE%.md}.extract"

# ============================================================================
# Phase Complete
# ============================================================================

re_success_rule
re_success "Phase 1 complete! Codebase inventory saved to: $OUTPUT_FILE"
re_info "Ready for Phase 2: Architecture Extraction"

exit 0
