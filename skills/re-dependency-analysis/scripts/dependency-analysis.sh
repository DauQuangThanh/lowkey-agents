#!/bin/bash
# Phase 5: Dependency & Integration Map
# Parses common package manifests to list direct dependencies.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

if declare -f re_parse_flags >/dev/null 2>&1; then
  re_parse_flags "$@"
fi

re_init_debt_file
OUTPUT_FILE="$RE_OUTPUT_DIR/05-dependency-map.md"
EXTRACT_FILE="$RE_OUTPUT_DIR/05-dependency-map.extract"

SOURCE_ROOT=$(re_get SOURCE_ROOT "Source root" ".")
if ! re_validate_path "$SOURCE_ROOT"; then
  re_error "Cannot analyse dependencies: SOURCE_ROOT invalid"
  exit 1
fi

re_info "Phase 5: Cataloguing dependencies in $SOURCE_ROOT"

manifests_found=()
direct_total=0
dev_total=0

{
  echo "# Phase 5: Dependency & Integration Map"
  echo ""
  echo "**Generated:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Source root:** \`$SOURCE_ROOT\`"
  echo ""

  # ── Node.js: package.json ─────────────────────────────────────────────────
  if [ -f "$SOURCE_ROOT/package.json" ]; then
    manifests_found+=("package.json")
    pj="$SOURCE_ROOT/package.json"
    # Crude line-based parse — avoids a jq dependency. Good enough for a
    # snapshot of direct deps; transitive graph is out of scope.
    deps=$(awk '/"dependencies"[[:space:]]*:[[:space:]]*\{/,/^[[:space:]]*\}/' "$pj" 2>/dev/null \
          | grep -oE '"[^"]+"[[:space:]]*:[[:space:]]*"[^"]+"' | head -200)
    dev_deps=$(awk '/"devDependencies"[[:space:]]*:[[:space:]]*\{/,/^[[:space:]]*\}/' "$pj" 2>/dev/null \
              | grep -oE '"[^"]+"[[:space:]]*:[[:space:]]*"[^"]+"' | head -200)
    n_deps=$(echo "$deps" | grep -c ':' || echo 0)
    n_dev=$(echo "$dev_deps" | grep -c ':' || echo 0)
    direct_total=$((direct_total + n_deps))
    dev_total=$((dev_total + n_dev))

    echo "## Node.js (\`package.json\`)"
    echo ""
    echo "- Runtime dependencies: $n_deps"
    echo "- Dev dependencies: $n_dev"
    echo ""
    if [ "$n_deps" -gt 0 ]; then
      echo "### Runtime"
      echo ""
      echo '```json'
      echo "$deps"
      echo '```'
      echo ""
    fi
    if [ "$n_dev" -gt 0 ]; then
      echo "### Dev"
      echo ""
      echo '```json'
      echo "$dev_deps"
      echo '```'
      echo ""
    fi
  fi

  # ── Python: requirements.txt / pyproject.toml ──────────────────────────────
  if [ -f "$SOURCE_ROOT/requirements.txt" ]; then
    manifests_found+=("requirements.txt")
    n=$(grep -cE "^[a-zA-Z0-9_.-]+" "$SOURCE_ROOT/requirements.txt" 2>/dev/null || echo 0)
    direct_total=$((direct_total + n))
    echo "## Python (\`requirements.txt\`)"
    echo ""
    echo "- Direct dependencies: $n"
    echo ""
    echo '```text'
    head -50 "$SOURCE_ROOT/requirements.txt"
    echo '```'
    echo ""
  fi
  if [ -f "$SOURCE_ROOT/pyproject.toml" ]; then
    manifests_found+=("pyproject.toml")
    echo "## Python (\`pyproject.toml\`)"
    echo ""
    echo '```toml'
    head -80 "$SOURCE_ROOT/pyproject.toml"
    echo '```'
    echo ""
  fi

  # ── Go modules ─────────────────────────────────────────────────────────────
  if [ -f "$SOURCE_ROOT/go.mod" ]; then
    manifests_found+=("go.mod")
    n=$(grep -c "^[[:space:]]*[a-z].*v[0-9]" "$SOURCE_ROOT/go.mod" 2>/dev/null || echo 0)
    direct_total=$((direct_total + n))
    echo "## Go (\`go.mod\`)"
    echo ""
    echo '```go'
    head -50 "$SOURCE_ROOT/go.mod"
    echo '```'
    echo ""
  fi

  # ── Rust / Cargo ──────────────────────────────────────────────────────────
  if [ -f "$SOURCE_ROOT/Cargo.toml" ]; then
    manifests_found+=("Cargo.toml")
    echo "## Rust (\`Cargo.toml\`)"
    echo ""
    echo '```toml'
    head -80 "$SOURCE_ROOT/Cargo.toml"
    echo '```'
    echo ""
  fi

  # ── Java: pom.xml ─────────────────────────────────────────────────────────
  if [ -f "$SOURCE_ROOT/pom.xml" ]; then
    manifests_found+=("pom.xml")
    n=$(grep -c "<dependency>" "$SOURCE_ROOT/pom.xml" 2>/dev/null || echo 0)
    direct_total=$((direct_total + n))
    echo "## Java (\`pom.xml\`)"
    echo ""
    echo "- Declared dependencies: $n"
    echo ""
  fi

  # ── Ruby: Gemfile ─────────────────────────────────────────────────────────
  if [ -f "$SOURCE_ROOT/Gemfile" ]; then
    manifests_found+=("Gemfile")
    n=$(grep -c "^[[:space:]]*gem [\"']" "$SOURCE_ROOT/Gemfile" 2>/dev/null || echo 0)
    direct_total=$((direct_total + n))
    echo "## Ruby (\`Gemfile\`)"
    echo ""
    echo "- Direct gems: $n"
    echo ""
  fi

  # ── Summary ───────────────────────────────────────────────────────────────
  echo "## Summary"
  echo ""
  echo "- Manifests found: ${#manifests_found[@]}"
  echo "- Total direct dependencies (across all manifests): $direct_total"
  echo "- Total dev dependencies: $dev_total"
  echo ""
  if [ "${#manifests_found[@]}" -eq 0 ]; then
    echo "_No package manifests found. The project may have zero external dependencies_"
    echo "_(common for static HTML/CSS/JS apps) or use an unusual build system._"
    echo ""
  fi
  echo "## Notes"
  echo ""
  echo "Only direct (declared) dependencies are counted. Transitive/full dependency"
  echo "graph, outdated-package analysis, and vulnerability scanning are out of scope for"
  echo "this phase — use dedicated tools (\`npm audit\`, \`pip-audit\`, \`cargo audit\`, etc.)."
  echo ""
} > "$OUTPUT_FILE"

manifest_str=$(IFS=,; echo "${manifests_found[*]+"${manifests_found[*]}"}")
{
  echo "# Auto-generated extract — KEY=VALUE per line."
  echo "# Generated: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "MANIFESTS=$manifest_str"
  echo "DIRECT_DEPS=$direct_total"
  echo "DEV_DEPS=$dev_total"
} > "$EXTRACT_FILE"

if [ "${#manifests_found[@]}" -eq 0 ]; then
  re_add_debt_auto "Dependencies" "No package manifest detected" \
    "Neither package.json, requirements.txt, go.mod, pom.xml, Cargo.toml nor Gemfile found in $SOURCE_ROOT" \
    "Project may be dependency-free; confirm manually"
fi

re_success "Phase 5 complete — $OUTPUT_FILE"
echo ""
echo "Output: $OUTPUT_FILE"
