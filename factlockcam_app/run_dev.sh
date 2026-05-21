#!/usr/bin/env bash
# Sync Supabase keys from repo-root .env.local, then run Flutter (iOS/Android/desktop).
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$APP_DIR/.." && pwd)"

bash "$ROOT_DIR/scripts/sync_flutter_dart_defines.sh"
cd "$APP_DIR"
exec flutter run "$@"
