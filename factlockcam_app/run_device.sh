#!/usr/bin/env bash
# Device QA: sync Supabase defines from repo-root .env.local, then run Flutter.
# Compile-time fallbacks live in lib/core/config/generated_dart_defines.dart after sync.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
SIGNING_LOCAL="$APP_DIR/ios/Flutter/Signing.local.xcconfig"
SIGNING_EXAMPLE="$APP_DIR/ios/Flutter/Signing.local.xcconfig.example"

if [[ ! -f "$SIGNING_LOCAL" ]]; then
  if [[ -f "$SIGNING_EXAMPLE" ]]; then
    cp "$SIGNING_EXAMPLE" "$SIGNING_LOCAL"
    echo "Created ios/Flutter/Signing.local.xcconfig from example (device QA bundle ID)." >&2
    echo "If install still fails, edit PRODUCT_BUNDLE_IDENTIFIER to a unique ID your Apple team owns." >&2
  else
    echo "Missing ios/Flutter/Signing.local.xcconfig — required for device install when" >&2
    echo "com.factlockcam.app is not on your development team. See Signing.local.xcconfig.example." >&2
    exit 1
  fi
fi

"$ROOT/scripts/sync_flutter_dart_defines.sh"
cd "$APP_DIR"
exec flutter run --dart-define-from-file=dart_defines.json "$@"
