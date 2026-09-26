#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${LEGAL_AI_BASE_URL:-https://odd-mouse-c1e0.ghgfcrcgrf57566.workers.dev}"
APP_VERSION="${APP_VERSION:-1.0.0}"
QUESTION="${TEST_QUESTION:-ما شروط صحة العقد؟}"

echo "Health: $BASE_URL/health"
curl --fail --silent --show-error --location --max-time 30 "$BASE_URL/health"
echo

echo "Legal assistant smoke test: $BASE_URL/api/chat"
response="$(curl --fail --silent --show-error --location --max-time 60 \
  -X POST "$BASE_URL/api/chat" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H "X-App-Version: $APP_VERSION" \
  --data "$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"language":"ar","history":[]},ensure_ascii=False))' "$QUESTION")")"

printf '%s\n' "$response"

python3 - "$response" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])
if not isinstance(payload.get("answer"), str) or not payload["answer"].strip():
    raise SystemExit("Smoke test failed: missing answer")
if not isinstance(payload.get("sources"), list):
    raise SystemExit("Smoke test failed: missing sources list")
print("Smoke test passed.")
PY
