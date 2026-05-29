#!/usr/bin/env bash
# Build Flutter Web release bundle for archive.factlockcam.com courier unlock SPA.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/factlockcam_app"
DEFINES="$APP_DIR/dart_defines.json"

echo "==> Syncing dart defines from .env.local"
"$ROOT_DIR/scripts/sync_flutter_dart_defines.sh"

if [[ ! -f "$DEFINES" ]]; then
  echo "Missing $DEFINES after sync. Set SUPABASE_URL and SUPABASE_ANON_KEY in .env.local." >&2
  exit 1
fi

echo "==> Building Flutter Web release (no PWA service worker)"
(
  cd "$APP_DIR"
  flutter build web \
    --release \
    --pwa-strategy=none \
    --dart-define-from-file="$DEFINES"
)

# Cloudflare Pages reads _redirects from the deploy root; Flutter does not copy it automatically.
if [[ -f "$APP_DIR/web/_redirects" ]]; then
  cp "$APP_DIR/web/_redirects" "$APP_DIR/build/web/_redirects"
fi

OUTPUT="$APP_DIR/build/web"
echo ""
echo "Build complete: $OUTPUT"
echo ""
echo "Deploy to Cloudflare Pages:"
echo "  ./scripts/deploy_web_archive_cf.sh"
echo ""
echo "Or manually upload $OUTPUT and point DNS:"
echo "  CNAME archive -> factlockcam-archive.pages.dev"
echo ""
echo "Post-deploy acceptance:"
echo "  curl -sI 'https://archive.factlockcam.com/courier?pkg=test' | head -1"
echo "  (expect HTTP/2 200 — SPA index.html, not 404 from host)"
echo ""
echo "Verify script: scripts/verify_web_archive_deploy.sh https://archive.factlockcam.com"
