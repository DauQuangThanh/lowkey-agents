#!/bin/bash
# Phase 4: Data Model Extraction
# Detects database engines, ORMs, entity definitions, and client-side
# storage schemas from the codebase.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPT_DIR/_common.sh"

if declare -f re_parse_flags >/dev/null 2>&1; then
  re_parse_flags "$@"
fi

re_init_debt_file
OUTPUT_FILE="$RE_OUTPUT_DIR/04-data-model.md"
EXTRACT_FILE="$RE_OUTPUT_DIR/04-data-model.extract"

SOURCE_ROOT=$(re_get SOURCE_ROOT "Source root" ".")
if ! re_validate_path "$SOURCE_ROOT"; then
  re_error "Cannot analyse data model: SOURCE_ROOT invalid"
  exit 1
fi

re_info "Phase 4: Extracting data model from $SOURCE_ROOT"

exclude_args=(
  --exclude-dir=node_modules --exclude-dir=.git
  --exclude-dir=dist --exclude-dir=build --exclude-dir=.venv
  --exclude-dir=vendor --exclude-dir=target
)

# ── Database engines (from config strings / connection URIs) ─────────────────
databases=()
probe_db() {
  # probe_db <regex> <label>
  if grep -rqE "$1" "${exclude_args[@]}" "$SOURCE_ROOT" 2>/dev/null; then
    databases+=("$2")
  fi
}
probe_db "postgres(ql)?://|psycopg2|pg\.Pool|PostgreSQL" "PostgreSQL"
probe_db "mysql://|mysql2|mysql\.createConnection"        "MySQL"
probe_db "sqlite3?://|sqlite3\.|better-sqlite3"           "SQLite"
probe_db "mongodb(\\+srv)?://|mongoose\.|MongoClient"     "MongoDB"
probe_db "redis://|createClient\\(.*redis|Redis\\("       "Redis"
probe_db "cassandra://|cassandra-driver"                  "Cassandra"
probe_db "dynamodb|DynamoDB"                              "DynamoDB"

# ── ORMs / data-access libraries ─────────────────────────────────────────────
orms=()
probe_orm() {
  if grep -rqE "$1" "${exclude_args[@]}" "$SOURCE_ROOT" 2>/dev/null; then
    orms+=("$2")
  fi
}
probe_orm "from sqlalchemy|import sqlalchemy"       "SQLAlchemy (Python)"
probe_orm "from django\.db|models\.Model"           "Django ORM"
probe_orm "\"sequelize\"|require\\(['\"]sequelize"  "Sequelize (Node)"
probe_orm "\"mongoose\"|require\\(['\"]mongoose"    "Mongoose (Node)"
probe_orm "\"typeorm\"|@Entity\\("                  "TypeORM"
probe_orm "PrismaClient|prisma\\.[a-z]"             "Prisma"
probe_orm "\"@mikro-orm/"                            "MikroORM"
probe_orm "ActiveRecord::Base"                       "Rails ActiveRecord"
probe_orm "gorm\\.DB|gorm\\.Open"                   "GORM (Go)"
probe_orm "diesel::"                                 "Diesel (Rust)"
probe_orm "@Entity|@Table\\(name"                    "JPA/Hibernate"

# ── Entity / model definitions ───────────────────────────────────────────────
# Count files that look like model/entity definitions based on path.
model_files=()
while IFS= read -r f; do
  [ -n "$f" ] && model_files+=("$f")
done < <(find "$SOURCE_ROOT" -type f \
  \( -path "*/models/*" -o -path "*/model/*" -o -path "*/entities/*" -o -path "*/entity/*" -o -path "*/schemas/*" -o -path "*/schema/*" \) \
  \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.rb" -o -name "*.go" -o -name "*.java" -o -name "*.kt" -o -name "*.rs" \) \
  2>/dev/null | head -100)

# ── Migration directories ────────────────────────────────────────────────────
migrations=()
for d in migrations db/migrate prisma/migrations alembic; do
  if find "$SOURCE_ROOT" -maxdepth 4 -type d -name "$d" 2>/dev/null | grep -q .; then
    migrations+=("$d")
  fi
done

# ── Client-side storage schema detection ─────────────────────────────────────
# If the project uses localStorage/sessionStorage, try to identify the keys
# and (best-effort) the shape of what's being stored.
storage_keys_tmp=$(mktemp)
# Match any setItem/getItem/removeItem call, whether the key is a literal
# or a variable — we care about the call site, not whether the argument
# happens to be a string literal.
grep -rhnE "(localStorage|sessionStorage)\.(setItem|getItem|removeItem)\(" \
  "${exclude_args[@]}" --include="*.js" --include="*.ts" --include="*.html" \
  "$SOURCE_ROOT" 2>/dev/null > "$storage_keys_tmp" || true

storage_const_tmp=$(mktemp)
# STORAGE_KEY-style constants — looser pattern that matches the common idiom
# of a top-level UPPER_SNAKE constant holding a literal storage key.
grep -rhnE "^[[:space:]]*(const|let|var)[[:space:]]+[A-Z_]+[[:space:]]*=[[:space:]]*['\"]" \
  "${exclude_args[@]}" --include="*.js" --include="*.ts" \
  "$SOURCE_ROOT" 2>/dev/null | grep -iE "key|storage" > "$storage_const_tmp" || true

# ── Write output ─────────────────────────────────────────────────────────────
{
  echo "# Phase 4: Data Model Extraction"
  echo ""
  echo "**Generated:** $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "**Source root:** \`$SOURCE_ROOT\`"
  echo ""
  echo "## Detected Databases"
  echo ""
  if [ "${#databases[@]}" -gt 0 ]; then
    for d in "${databases[@]+"${databases[@]}"}"; do
      echo "- $d"
    done
  else
    echo "_No database connection markers found._"
  fi
  echo ""
  echo "## Detected ORMs / Data-Access Libraries"
  echo ""
  if [ "${#orms[@]}" -gt 0 ]; then
    for o in "${orms[@]+"${orms[@]}"}"; do
      echo "- $o"
    done
  else
    echo "_No ORM markers found._"
  fi
  echo ""
  echo "## Model / Entity Files (up to 100 shown)"
  echo ""
  if [ "${#model_files[@]}" -gt 0 ]; then
    for m in "${model_files[@]+"${model_files[@]}"}"; do
      printf -- '- `%s`\n' "${m#$SOURCE_ROOT/}"
    done
  else
    echo "_No files found under conventional model/entity/schema directories._"
  fi
  echo ""
  echo "## Migration Directories"
  echo ""
  if [ "${#migrations[@]}" -gt 0 ]; then
    for m in "${migrations[@]+"${migrations[@]}"}"; do
      echo "- \`$m/\`"
    done
  else
    echo "_No migration directory found._"
  fi
  echo ""
  if [ -s "$storage_keys_tmp" ] || [ -s "$storage_const_tmp" ]; then
    echo "## Client-Side Storage Schema"
    echo ""
    echo "This project uses browser storage APIs. Key definitions and accesses found:"
    echo ""
    echo '```text'
    cat "$storage_const_tmp" "$storage_keys_tmp" | head -30
    echo '```'
    echo ""
  fi
  echo "## Notes"
  echo ""
  echo "Detection is text-based. If a DB is accessed via an abstraction layer that hides"
  echo "connection strings, it may not appear above — see \`07-re-debts.md\`."
  echo ""
} > "$OUTPUT_FILE"

db_str=$(IFS=,; echo "${databases[*]+"${databases[*]}"}")
orm_str=$(IFS=,; echo "${orms[*]+"${orms[*]}"}")
{
  echo "# Auto-generated extract — KEY=VALUE per line."
  echo "# Generated: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "DATABASES=$db_str"
  echo "ORMS=$orm_str"
  echo "MODEL_FILE_COUNT=${#model_files[@]}"
  echo "MIGRATION_DIRS=$(IFS=,; echo "${migrations[*]+"${migrations[*]}"}")"
  echo "CLIENT_STORAGE_KEY_REFS=$(wc -l < "$storage_keys_tmp" | tr -d ' ')"
} > "$EXTRACT_FILE"

if [ "${#databases[@]}" -eq 0 ] && [ "${#orms[@]}" -eq 0 ] && [ ! -s "$storage_keys_tmp" ]; then
  re_add_debt_auto "Data Model" "No data layer detected" \
    "No database, ORM, or client-storage markers found in $SOURCE_ROOT" \
    "The project may be stateless; confirm manually"
fi

rm -f "$storage_keys_tmp" "$storage_const_tmp"

re_success "Phase 4 complete — $OUTPUT_FILE"
echo ""
echo "Output: $OUTPUT_FILE"
