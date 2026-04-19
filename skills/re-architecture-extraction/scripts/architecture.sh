#!/bin/bash
# Phase 2: Architecture Reverse Engineering
# Detects tech stack, layer structure, frameworks, and deployment artifacts
# from the source tree.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

# --auto / --answers support (parser lives in re-codebase-scan's _common.sh)
if declare -f re_parse_flags >/dev/null 2>&1; then
  re_parse_flags "$@"
fi

re_init_debt_file
OUTPUT_FILE="$RE_OUTPUT_DIR/02-architecture.md"
EXTRACT_FILE="$RE_OUTPUT_DIR/02-architecture.extract"

# Anchor SOURCE_ROOT via the same resolution chain as phase 1.
SOURCE_ROOT=$(re_get SOURCE_ROOT "Source root" ".")
if ! re_validate_path "$SOURCE_ROOT"; then
  re_error "Cannot analyse architecture: SOURCE_ROOT invalid"
  exit 1
fi

re_info "Phase 2: Extracting architecture from $SOURCE_ROOT"

# ── Framework / tech stack detection ─────────────────────────────────────────
# Report each framework we can detect from config files. Kept deliberately
# shallow — RE is a snapshot, not an audit.
frameworks=()
detect_file() {
  # detect_file <glob> <label>
  if [ -n "$(find "$SOURCE_ROOT" -maxdepth 3 -type f -name "$1" 2>/dev/null | head -1)" ]; then
    frameworks+=("$2")
  fi
}
detect_file "package.json"        "Node.js / npm project"
detect_file "tsconfig.json"       "TypeScript"
detect_file "pyproject.toml"      "Python (PEP 621)"
detect_file "requirements.txt"    "Python (pip)"
detect_file "Pipfile"             "Python (pipenv)"
detect_file "poetry.lock"         "Python (poetry)"
detect_file "go.mod"              "Go modules"
detect_file "Cargo.toml"          "Rust (cargo)"
detect_file "pom.xml"             "Java (Maven)"
detect_file "build.gradle"        "Java/Kotlin (Gradle)"
detect_file "build.gradle.kts"    "Kotlin (Gradle)"
detect_file "Gemfile"             "Ruby (Bundler)"
detect_file "composer.json"       "PHP (Composer)"
detect_file "mix.exs"             "Elixir (mix)"
detect_file ".csproj"             ".NET project"
detect_file "Dockerfile"          "Docker"
detect_file "docker-compose.yml"  "Docker Compose"
detect_file "docker-compose.yaml" "Docker Compose"
detect_file ".github/workflows"   "GitHub Actions"

# Framework-level detection by grepping package.json — best-effort only.
if [ -f "$SOURCE_ROOT/package.json" ]; then
  pj="$SOURCE_ROOT/package.json"
  grep -q '"react"'       "$pj" 2>/dev/null && frameworks+=("React")
  grep -q '"vue"'         "$pj" 2>/dev/null && frameworks+=("Vue")
  grep -q '"@angular/'    "$pj" 2>/dev/null && frameworks+=("Angular")
  grep -q '"next"'        "$pj" 2>/dev/null && frameworks+=("Next.js")
  grep -q '"express"'     "$pj" 2>/dev/null && frameworks+=("Express")
  grep -q '"fastify"'     "$pj" 2>/dev/null && frameworks+=("Fastify")
  grep -q '"nestjs\|@nestjs/' "$pj" 2>/dev/null && frameworks+=("NestJS")
fi
if [ -f "$SOURCE_ROOT/requirements.txt" ] || [ -f "$SOURCE_ROOT/pyproject.toml" ]; then
  py_manifest=$(find "$SOURCE_ROOT" -maxdepth 2 \( -name "requirements.txt" -o -name "pyproject.toml" \) -type f 2>/dev/null | head -5)
  if [ -n "$py_manifest" ]; then
    echo "$py_manifest" | while read -r m; do
      grep -iq "^django\|\"django\"" "$m" 2>/dev/null && echo "Django"
      grep -iq "^flask\|\"flask\"" "$m" 2>/dev/null && echo "Flask"
      grep -iq "^fastapi\|\"fastapi\"" "$m" 2>/dev/null && echo "FastAPI"
    done > /tmp/re_py_fw.$$
    while IFS= read -r fw; do
      [ -n "$fw" ] && frameworks+=("$fw")
    done < /tmp/re_py_fw.$$
    rm -f /tmp/re_py_fw.$$
  fi
fi

# ── Layer / package structure ────────────────────────────────────────────────
# Heuristic: look for well-known directory names that indicate a layered
# architecture. Absence isn't evidence of bad design — it's a snapshot.
layers=()
for d in controllers services models views routes api handlers middleware \
         repositories domain entities components pages utils lib core \
         infra infrastructure config tests test __tests__ spec; do
  if find "$SOURCE_ROOT" -maxdepth 4 -type d -name "$d" 2>/dev/null | grep -q .; then
    layers+=("$d")
  fi
done

# ── Deployment artifacts ─────────────────────────────────────────────────────
deployment=()
[ -f "$SOURCE_ROOT/Dockerfile" ]             && deployment+=("Dockerfile")
[ -f "$SOURCE_ROOT/docker-compose.yml" ]     && deployment+=("docker-compose.yml")
[ -f "$SOURCE_ROOT/docker-compose.yaml" ]    && deployment+=("docker-compose.yaml")
[ -d "$SOURCE_ROOT/.github/workflows" ]      && deployment+=("GitHub Actions workflows")
[ -d "$SOURCE_ROOT/.circleci" ]              && deployment+=(".circleci")
[ -d "$SOURCE_ROOT/.gitlab-ci.yml" ]         && deployment+=(".gitlab-ci.yml")
[ -f "$SOURCE_ROOT/Jenkinsfile" ]            && deployment+=("Jenkinsfile")
[ -d "$SOURCE_ROOT/k8s" ] || [ -d "$SOURCE_ROOT/kubernetes" ] && deployment+=("Kubernetes manifests")
[ -n "$(find "$SOURCE_ROOT" -maxdepth 3 -name "*.tf" 2>/dev/null | head -1)" ] && deployment+=("Terraform")

# ── Write output ─────────────────────────────────────────────────────────────
{
  echo "# Phase 2: Architecture Extraction"
  echo ""
  echo "**Generated:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Source root:** \`$SOURCE_ROOT\`"
  echo ""
  echo "## Detected Frameworks & Tech Stack"
  echo ""
  if [ "${#frameworks[@]}" -gt 0 ]; then
    for f in "${frameworks[@]+"${frameworks[@]}"}"; do
      echo "- $f"
    done
  else
    echo "_No known framework markers detected (static files / raw source only)._"
  fi
  echo ""
  echo "## Layer Structure"
  echo ""
  if [ "${#layers[@]}" -gt 0 ]; then
    echo "Directories matching common architectural layers:"
    echo ""
    for l in "${layers[@]+"${layers[@]}"}"; do
      echo "- \`$l/\`"
    done
  else
    echo "_No conventional layer directories found. The project likely has a flat or custom structure._"
  fi
  echo ""
  echo "## Deployment Artefacts"
  echo ""
  if [ "${#deployment[@]}" -gt 0 ]; then
    for d in "${deployment[@]+"${deployment[@]}"}"; do
      echo "- $d"
    done
  else
    echo "_No deployment manifests found. Project may rely on external CI or static hosting._"
  fi
  echo ""
  echo "## Notes"
  echo ""
  echo "Detection is marker-based and best-effort. Entries are proof of presence, not of good design."
  echo "See \`07-re-debts.md\` for anything that could not be determined."
  echo ""
} > "$OUTPUT_FILE"

# Flatten arrays for extract
fw_str=$(IFS=,; echo "${frameworks[*]+"${frameworks[*]}"}")
layer_str=$(IFS=,; echo "${layers[*]+"${layers[*]}"}")
deploy_str=$(IFS=,; echo "${deployment[*]+"${deployment[*]}"}")
{
  echo "# Auto-generated extract — KEY=VALUE per line."
  echo "# Generated: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "FRAMEWORKS=$fw_str"
  echo "LAYERS=$layer_str"
  echo "DEPLOYMENT=$deploy_str"
} > "$EXTRACT_FILE"

if [ "${#frameworks[@]}" -eq 0 ] && [ "${#layers[@]}" -eq 0 ]; then
  re_add_debt_auto "Architecture" "No architectural markers detected" \
    "Neither framework manifests nor layer directories were found in $SOURCE_ROOT" \
    "Architecture cannot be inferred from the tree; manual review needed"
fi

re_success "Phase 2 complete — $OUTPUT_FILE"
echo ""
echo "Output: $OUTPUT_FILE"
