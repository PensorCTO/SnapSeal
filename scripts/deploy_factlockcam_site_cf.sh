#!/usr/bin/env bash
# Build Astro marketing site and deploy to Cloudflare Pages (factlockcam apex).
#
# Custom domain: factlockcam.com (+ optional www) in Cloudflare Pages dashboard.
#
# Prerequisites:
#   cd projects/FactLockCam_Site && npm install
#   npx wrangler login
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$ROOT_DIR/projects/FactLockCam_Site"
PAYLOAD="$SITE_DIR/dist"
PROJECT="${CF_PAGES_PROJECT:-factlockcam}"

resolve_wrangler() {
  local bin="$SITE_DIR/node_modules/.bin/wrangler"
  if [[ -x "$bin" ]]; then
    echo "$bin"
    return
  fi
  echo "npx --prefix $SITE_DIR wrangler"
}

if [[ ! -d "$SITE_DIR" ]]; then
  echo "Site directory not found: $SITE_DIR" >&2
  echo "Run from repo root: bash scripts/deploy_factlockcam_site_cf.sh" >&2
  exit 1
fi

echo "==> Building FactLockCam marketing site"
(
  cd "$SITE_DIR"
  npm run build
)

WRANGLER="$(resolve_wrangler)"

if [[ ! -d "$PAYLOAD" ]]; then
  echo "Missing deploy payload: $PAYLOAD" >&2
  echo "Build first: (cd \"$SITE_DIR\" && npm run build)" >&2
  echo "Do not deploy from factlockcam_app — dist lives under projects/FactLockCam_Site/dist" >&2
  exit 1
fi

BRANCH="${CF_PAGES_BRANCH:-main}"

echo ""
echo "==> Deploying to Cloudflare Pages"
echo "    project: $PROJECT"
echo "    branch:  $BRANCH"
echo "    payload: $PAYLOAD"
echo ""

# shellcheck disable=SC2086
$WRANGLER pages deploy "$PAYLOAD" \
  --project-name="$PROJECT" \
  --branch="$BRANCH" \
  --commit-dirty=true

echo ""
echo "Deploy complete."
echo ""
echo "Custom domain: Cloudflare Dashboard → Workers & Pages → $PROJECT → add factlockcam.com"
echo "Verify: curl -sI https://factlockcam.com/ | head -1"
