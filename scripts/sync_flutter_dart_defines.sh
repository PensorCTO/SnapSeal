#!/usr/bin/env bash
# Merge repo-root .env.local (if present) with current shell env and write
# factlockcam_app/dart_defines.json for IDE / flutter --dart-define-from-file.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${FACTLOCKCAM_ENV_FILE:-$ROOT_DIR/.env.local}"
OUT="${FACTLOCKCAM_FLUTTER_DEFINES_OUT:-$ROOT_DIR/factlockcam_app/dart_defines.json}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

exec python3 "$ROOT_DIR/scripts/write_flutter_dart_defines.py" \
  --env-file "$ENV_FILE" \
  --out "$OUT"
