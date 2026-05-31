#!/usr/bin/env bash
# Merge repo-root .env.local (if present) with current shell env and write
# factlockcam_app/dart_defines.json for IDE / flutter --dart-define-from-file.
#
# Optional keys include ENABLE_PROOF_LINKS (false for App Store release until archive
# is live; set true in .env.local for device Send Proof QA). Debug builds also
# enable Send Proof when WEB_ARCHIVE_BASE_URL is set unless ENABLE_PROOF_LINKS=false.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${FACTLOCKCAM_ENV_FILE:-$ROOT_DIR/.env.local}"
OUT="${FACTLOCKCAM_FLUTTER_DEFINES_OUT:-$ROOT_DIR/factlockcam_app/dart_defines.json}"
DART_OUT="${FACTLOCKCAM_FLUTTER_DART_OUT:-$ROOT_DIR/factlockcam_app/lib/core/config/generated_dart_defines.dart}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

exec python3 "$ROOT_DIR/scripts/write_flutter_dart_defines.py" \
  --env-file "$ENV_FILE" \
  --out "$OUT" \
  --dart-out "$DART_OUT"
