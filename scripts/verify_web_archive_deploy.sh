#!/usr/bin/env bash
# Post-deploy smoke checks for the archive subdomain Flutter Web courier SPA.
set -euo pipefail

BASE_URL="${1:-https://archive.factlockcam.com}"
COURIER_URL="$BASE_URL/courier?pkg=test"

echo "==> Checking courier SPA entry: $COURIER_URL"
status_line="$(curl -sSI "$COURIER_URL" | head -1 || true)"
echo "$status_line"

if echo "$status_line" | grep -qE '522|530'; then
  echo "FAIL: Cloudflare origin error ($status_line)." >&2
  echo "  522 = Pages project has no active deployment (run ./scripts/deploy_web_archive_cf.sh)." >&2
  echo "  530 = Custom domain DNS exists but is not bound to the Pages project." >&2
  exit 1
fi

if ! echo "$status_line" | grep -qE '200|301|302|308'; then
  echo "FAIL: Expected 200 or redirect from Edge host (got: $status_line)" >&2
  exit 1
fi

echo "==> Checking TLS and index.html shell"
body="$(curl -sSL "$COURIER_URL" | head -c 4096 || true)"
if ! echo "$body" | grep -qi 'flutter'; then
  echo "WARN: Response body may not be Flutter index.html — verify SPA rewrites." >&2
else
  echo "OK: Flutter bootstrap detected in HTML shell."
fi

echo ""
echo "Manual checks:"
echo "  1. Open $COURIER_URL in browser — unlock UI loads (missing pkg error OK)"
echo "  2. No mixed-content console errors to Supabase HTTPS"
echo "  3. iOS Send Proof links use $BASE_URL/courier?pkg=..."
