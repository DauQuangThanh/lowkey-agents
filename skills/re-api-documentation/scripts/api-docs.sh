#!/bin/bash
# Phase 3: API & Interface Documentation
# Greps for REST / GraphQL / gRPC route definitions in the codebase and
# compiles a best-effort catalogue.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

if declare -f re_parse_flags >/dev/null 2>&1; then
  re_parse_flags "$@"
fi

re_init_debt_file
OUTPUT_FILE="$RE_OUTPUT_DIR/03-api-documentation.md"
EXTRACT_FILE="$RE_OUTPUT_DIR/03-api-documentation.extract"

SOURCE_ROOT=$(re_get SOURCE_ROOT "Source root" ".")
if ! re_validate_path "$SOURCE_ROOT"; then
  re_error "Cannot analyse APIs: SOURCE_ROOT invalid"
  exit 1
fi

re_info "Phase 3: Scanning $SOURCE_ROOT for API endpoints"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# ── REST route patterns across common frameworks ─────────────────────────────
# Each grep is narrow enough to avoid most false positives while still
# matching the most common idioms. Exclude generated / vendor paths.
exclude_args=(
  --exclude-dir=node_modules --exclude-dir=.git
  --exclude-dir=dist --exclude-dir=build --exclude-dir=.venv
  --exclude-dir=vendor --exclude-dir=target
)

# Express / Fastify / Koa style: app.get('/path', ...), router.post('/path', ...)
grep -rnE "^[[:space:]]*(app|router|api|server)\.(get|post|put|patch|delete|head|options)\(" \
  "${exclude_args[@]}" "$SOURCE_ROOT" 2>/dev/null > "$tmp" || true

# Flask / FastAPI style: @app.route('/path'), @app.get('/path'), @router.post(...)
grep -rnE "^[[:space:]]*@(app|router|api|blueprint|bp)\.(route|get|post|put|patch|delete)\(" \
  "${exclude_args[@]}" "$SOURCE_ROOT" 2>/dev/null >> "$tmp" || true

# Spring / Java style: @GetMapping, @PostMapping, @RequestMapping
grep -rnE "^[[:space:]]*@(Get|Post|Put|Patch|Delete|Request)Mapping\(" \
  "${exclude_args[@]}" "$SOURCE_ROOT" 2>/dev/null >> "$tmp" || true

# Rails style: get '/path', post '/path', match '/path'
grep -rnE "^[[:space:]]*(get|post|put|patch|delete|match)[[:space:]]+['\"]" \
  "${exclude_args[@]}" --include="*.rb" "$SOURCE_ROOT" 2>/dev/null >> "$tmp" || true

# Django urls.py: path('url', view), re_path('url', view)
grep -rnE "^[[:space:]]*(path|re_path|url)\(" \
  "${exclude_args[@]}" --include="urls.py" "$SOURCE_ROOT" 2>/dev/null >> "$tmp" || true

rest_count=$(wc -l < "$tmp" | tr -d ' ')

# ── GraphQL schema / resolver detection ──────────────────────────────────────
gql_count=0
if find "$SOURCE_ROOT" -maxdepth 6 -type f \( -name "*.graphql" -o -name "*.gql" \) 2>/dev/null | grep -q .; then
  gql_count=$(find "$SOURCE_ROOT" -maxdepth 6 -type f \( -name "*.graphql" -o -name "*.gql" \) 2>/dev/null | wc -l | tr -d ' ')
fi
# Also detect inline SDL in JS/TS files (common in Apollo / urql setups)
gql_inline=$(grep -rlnE "type[[:space:]]+(Query|Mutation|Subscription)[[:space:]]*\{" \
  "${exclude_args[@]}" --include="*.js" --include="*.ts" "$SOURCE_ROOT" 2>/dev/null | wc -l | tr -d ' ')

# ── gRPC .proto files ────────────────────────────────────────────────────────
proto_count=0
if find "$SOURCE_ROOT" -maxdepth 6 -type f -name "*.proto" 2>/dev/null | grep -q .; then
  proto_count=$(find "$SOURCE_ROOT" -maxdepth 6 -type f -name "*.proto" 2>/dev/null | wc -l | tr -d ' ')
fi

# ── Client-side storage APIs (localStorage, IndexedDB, sessionStorage) ──────
# Worth calling out for browser-only apps — often the "data layer" has no
# server API at all.
storage_hits=$(grep -rlE "localStorage\.|sessionStorage\.|indexedDB\." \
  "${exclude_args[@]}" --include="*.js" --include="*.ts" --include="*.html" \
  "$SOURCE_ROOT" 2>/dev/null | wc -l | tr -d ' ')

# ── Write output ─────────────────────────────────────────────────────────────
{
  echo "# Phase 3: API & Interface Documentation"
  echo ""
  echo "**Generated:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Source root:** \`$SOURCE_ROOT\`"
  echo ""
  echo "## Summary"
  echo ""
  echo "| Interface type | Count |"
  echo "|---|---|"
  echo "| REST route definitions | $rest_count |"
  echo "| GraphQL schema files   | $gql_count |"
  echo "| GraphQL inline SDL     | $gql_inline |"
  echo "| gRPC \`.proto\` files     | $proto_count |"
  echo "| Client-side storage uses | $storage_hits |"
  echo ""
  if [ "$rest_count" -gt 0 ]; then
    echo "## REST Endpoints (first 50)"
    echo ""
    echo '```text'
    head -50 "$tmp"
    echo '```'
    echo ""
    if [ "$rest_count" -gt 50 ]; then
      echo "_Showing 50 of $rest_count matches. Run the script's grep manually to see all._"
      echo ""
    fi
  fi
  if [ "$gql_count" -gt 0 ]; then
    echo "## GraphQL Schemas"
    echo ""
    find "$SOURCE_ROOT" -maxdepth 6 -type f \( -name "*.graphql" -o -name "*.gql" \) 2>/dev/null | while read -r f; do
      printf -- '- `%s`\n' "${f#$SOURCE_ROOT/}"
    done
    echo ""
  fi
  if [ "$proto_count" -gt 0 ]; then
    echo "## gRPC Definitions"
    echo ""
    find "$SOURCE_ROOT" -maxdepth 6 -type f -name "*.proto" 2>/dev/null | while read -r f; do
      printf -- '- `%s`\n' "${f#$SOURCE_ROOT/}"
    done
    echo ""
  fi
  if [ "$rest_count" -eq 0 ] && [ "$gql_count" -eq 0 ] && [ "$gql_inline" -eq 0 ] && [ "$proto_count" -eq 0 ]; then
    echo "## No Server APIs Found"
    echo ""
    if [ "$storage_hits" -gt 0 ]; then
      echo "The codebase has no detectable server-side API surface."
      echo "However, $storage_hits file(s) use browser storage APIs"
      echo "(\`localStorage\` / \`sessionStorage\` / \`indexedDB\`) — this is likely a"
      echo "client-only application whose \"API\" is the browser storage contract."
    else
      echo "No server-side API surface nor client storage usage detected."
      echo "The project may be a library, a static site, or an asset bundle."
    fi
    echo ""
  fi
} > "$OUTPUT_FILE"

{
  echo "# Auto-generated extract — KEY=VALUE per line."
  echo "# Generated: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "REST_ROUTE_COUNT=$rest_count"
  echo "GRAPHQL_SCHEMA_COUNT=$gql_count"
  echo "GRAPHQL_INLINE_COUNT=$gql_inline"
  echo "GRPC_PROTO_COUNT=$proto_count"
  echo "CLIENT_STORAGE_FILES=$storage_hits"
} > "$EXTRACT_FILE"

if [ "$rest_count" -eq 0 ] && [ "$gql_count" -eq 0 ] && [ "$gql_inline" -eq 0 ] && [ "$proto_count" -eq 0 ] && [ "$storage_hits" -eq 0 ]; then
  re_add_debt_auto "API Surface" "No API patterns detected" \
    "No REST routes, GraphQL SDL, .proto files, or client storage uses found in $SOURCE_ROOT" \
    "If this project exposes an API, the detection patterns don't match it; add custom grep to this phase"
fi

re_success "Phase 3 complete — $OUTPUT_FILE"
echo ""
echo "Output: $OUTPUT_FILE"
