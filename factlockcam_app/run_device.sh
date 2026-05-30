#!/usr/bin/env bash
# Device QA: sync Supabase defines from repo-root .env.local, then run with dart_defines.json.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/sync_flutter_dart_defines.sh"
cd "$(dirname "$0")"
exec flutter run --dart-define-from-file=dart_defines.json "$@"
