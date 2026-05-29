#!/usr/bin/env bash
# Build Flutter Web and deploy to Cloudflare Pages (factlockcam-archive).
#
# First-run Wrangler prompts (human-in-the-loop — press Enter at each):
#   1. Create a new project → accept default (factlockcam-archive)
#   2. Production branch → main
#
# Subsequent deploys are non-interactive once the Pages project exists.
#
# Prerequisites:
#   cd projects/FactLockCam_Site && npm install
#   npx wrangler login   # once per machine
#
# Optional env overrides:
#   CF_PAGES_PROJECT  (default: factlockcam-archive)
#   CF_PAGES_BRANCH   (default: main)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/factlockcam_app"
SITE_DIR="$ROOT_DIR/projects/FactLockCam_Site"
PAYLOAD="$APP_DIR/build/web"
PROJECT="${CF_PAGES_PROJECT:-factlockcam-archive}"
BRANCH="${CF_PAGES_BRANCH:-main}"

resolve_wrangler() {
  local bin="$SITE_DIR/node_modules/.bin/wrangler"
  if [[ -x "$bin" ]]; then
    echo "$bin"
    return
  fi
  if [[ -d "$SITE_DIR/node_modules/wrangler" ]]; then
    echo "npx --prefix $SITE_DIR wrangler"
    return
  fi
  echo ""
}

echo "==> Building archive web bundle"
"$ROOT_DIR/scripts/build_web_archive.sh"

WRANGLER="$(resolve_wrangler)"
if [[ -z "$WRANGLER" ]]; then
  echo "Wrangler not found. Run: cd projects/FactLockCam_Site && npm install" >&2
  exit 1
fi

if [[ ! -d "$PAYLOAD" ]]; then
  echo "Missing deploy payload: $PAYLOAD" >&2
  exit 1
fi

echo ""
echo "==> Deploying to Cloudflare Pages"
echo "    project: $PROJECT"
echo "    branch:  $BRANCH"
echo "    payload: $PAYLOAD"
echo ""
echo "If this is the first deploy, Wrangler will prompt twice — press Enter to accept defaults."
echo ""

# shellcheck disable=SC2086
$WRANGLER pages deploy "$PAYLOAD" \
  --project-name="$PROJECT" \
  --branch="$BRANCH" \
  --commit-dirty=true

echo ""
echo "Deploy complete."
echo ""

PAGES_ALIAS="https://main.${PROJECT}.pages.dev"
echo "==> Smoke-check Pages alias: $PAGES_ALIAS"
if "$ROOT_DIR/scripts/verify_web_archive_deploy.sh" "$PAGES_ALIAS"; then
  echo "OK: Pages alias serving Flutter courier SPA."
else
  echo "WARN: Pages alias smoke check failed — inspect deployment in Cloudflare dashboard." >&2
fi

echo ""
echo "Custom domain (required for iOS Send Proof links using archive.factlockcam.com):"
echo "  Cloudflare Dashboard → Workers & Pages → $PROJECT → Custom domains"
echo "  → Add: archive.factlockcam.com"
echo "  (Use CNAME archive → ${PROJECT}.pages.dev if prompted; remove orphan A records.)"
echo ""
echo "After custom domain is Active, verify:"
echo "  $ROOT_DIR/scripts/verify_web_archive_deploy.sh https://archive.factlockcam.com"
