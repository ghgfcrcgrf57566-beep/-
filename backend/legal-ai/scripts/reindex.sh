#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${LEGAL_AI_BASE_URL:-https://odd-mouse-c1e0.ghgfcrcgrf57566.workers.dev}"
: "${REINDEX_TOKEN:?Set REINDEX_TOKEN in the environment before running reindex.sh}"

after=0
while true; do
  echo "Reindexing articles after id=$after..."
  response="$(curl --fail --silent --show-error --location --max-time 120 \
    -X POST "$BASE_URL/admin/reindex?after=$after&limit=40" \
    -H "Authorization: Bearer $REINDEX_TOKEN" \
    -H 'Accept: application/json')"

  printf '%s\n' "$response"

  read -r done next_after processed < <(
    python3 - "$response" <<'PY'
import json
import sys
p=json.loads(sys.argv[1])
if p.get("error"):
    raise SystemExit(p["error"])
print(str(bool(p.get("done"))).lower(), int(p.get("next_after", 0)), int(p.get("processed", 0)))
PY
  )

  if [[ "$processed" -eq 0 || "$done" == "true" ]]; then
    echo "Reindex complete."
    break
  fi

  if [[ "$next_after" -le "$after" ]]; then
    echo "Reindex stopped: next_after did not advance." >&2
    exit 1
  fi

  after="$next_after"
done
