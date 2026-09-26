#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

WORKER_URL="${LEGAL_AI_BASE_URL:-https://odd-mouse-c1e0.ghgfcrcgrf57566.workers.dev}"
DB_NAME="yemen_laws_db"
VECTOR_INDEX="yemen-laws-articles"
DB_FILE="../../yemen_laws_app/assets/db/app_database.db"
EXPORT_SCRIPT="../../yemen_laws_app/tools/export_rag_data.py"
GENERATED_DIR="$ROOT_DIR/data/generated"
SEED_FILE="$GENERATED_DIR/seed.sql"

echo "== Yemen Laws Legal AI v4.0 Cloudflare setup =="
echo "Worker: $WORKER_URL"
echo

command -v node >/dev/null || { echo "Node.js is required."; exit 1; }
command -v npm >/dev/null || { echo "npm is required."; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required."; exit 1; }

echo "1/8 Installing backend tooling..."
npm install

echo "2/8 Checking Cloudflare authentication..."
npx wrangler whoami

echo "3/8 Ensuring Vectorize index exists..."
if npx wrangler vectorize list 2>/dev/null | grep -q "$VECTOR_INDEX"; then
  echo "Vectorize index already exists: $VECTOR_INDEX"
else
  npx wrangler vectorize create "$VECTOR_INDEX" --dimensions=1024 --metric=cosine
fi

echo "4/8 Applying D1 schema..."
npx wrangler d1 execute "$DB_NAME" --remote --file=./schema.sql

echo "5/8 Exporting the canonical legal corpus..."
if [[ ! -f "$DB_FILE" ]]; then
  echo "Missing SQLite database: $DB_FILE" >&2
  exit 1
fi
if [[ ! -f "$EXPORT_SCRIPT" ]]; then
  echo "Missing exporter: $EXPORT_SCRIPT" >&2
  exit 1
fi
mkdir -p "$GENERATED_DIR"
python3 "$EXPORT_SCRIPT" --db "$DB_FILE" --out "$GENERATED_DIR"
npx wrangler d1 execute "$DB_NAME" --remote --file="$SEED_FILE"

echo "6/8 Configuring Cloudflare Worker secrets..."
read -r -s -p "GEMINI_API_KEY: " GEMINI_API_KEY
echo
if [[ -z "$GEMINI_API_KEY" ]]; then
  echo "GEMINI_API_KEY cannot be empty." >&2
  exit 1
fi
printf '%s' "$GEMINI_API_KEY" | npx wrangler secret put GEMINI_API_KEY
unset GEMINI_API_KEY

read -r -s -p "REINDEX_TOKEN: " REINDEX_TOKEN
echo
if [[ -z "$REINDEX_TOKEN" ]]; then
  echo "REINDEX_TOKEN cannot be empty." >&2
  exit 1
fi
printf '%s' "$REINDEX_TOKEN" | npx wrangler secret put REINDEX_TOKEN

echo "7/8 Deploying Worker..."
npx wrangler deploy

echo "8/8 Verifying production endpoints..."
curl --fail --silent --show-error --location --max-time 30 "$WORKER_URL/health"
echo

echo "Running semantic reindex..."
LEGAL_AI_BASE_URL="$WORKER_URL" REINDEX_TOKEN="$REINDEX_TOKEN" \
  bash "$ROOT_DIR/scripts/reindex.sh"

echo "Running API smoke test..."
LEGAL_AI_BASE_URL="$WORKER_URL" APP_VERSION="1.0.0" \
  bash "$ROOT_DIR/scripts/test-endpoints.sh"

unset REINDEX_TOKEN
echo
echo "v4.0 Cloudflare setup completed successfully."
