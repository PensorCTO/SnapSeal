#!/usr/bin/env bash
# Task 1 anon RPC safety probes. Loads .env.local; prints response shapes only.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${FACTLOCKCAM_ENV_FILE:-$ROOT_DIR/.env.local}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${SUPABASE_URL:?SUPABASE_URL required}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY required}"

API="${SUPABASE_URL%/}/rest/v1/rpc"

echo "=== get_public_proof_attestation (empty hash) ==="
curl -sS -X POST "$API/get_public_proof_attestation" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"p_asset_hash": ""}'

echo ""
echo "=== get_public_proof_attestation (unknown hash) ==="
curl -sS -X POST "$API/get_public_proof_attestation" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"p_asset_hash": "deadbeef00000000000000000000000000000000000000000000000000000000"}'

echo ""
echo "=== report_courier_package (invalid package — expect error, no owner_id) ==="
curl -sS -X POST "$API/report_courier_package" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"p_package_id": "00000000-0000-0000-0000-000000000000", "p_reason": "spam"}'

echo ""
