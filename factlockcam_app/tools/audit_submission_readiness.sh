#!/usr/bin/env bash
# Pre-upload Archive submission readiness gate for FactLockCam iOS builds.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$ROOT_DIR/factlockcam_app"
IOS_DIR="$APP_DIR/ios"
PRIVACY_MANIFEST="$IOS_DIR/Runner/PrivacyInfo.xcprivacy"
INFO_PLIST="$IOS_DIR/Runner/Info.plist"
DART_DEFINES="$APP_DIR/dart_defines.json"
GENERATED_DEFINES="$APP_DIR/lib/core/config/generated_dart_defines.dart"

echo "==> FactLockCam Archive submission readiness audit"

if [[ ! -f "$PRIVACY_MANIFEST" ]]; then
  echo "FAIL: Missing Archive privacy manifest: $PRIVACY_MANIFEST" >&2
  exit 1
fi
echo "OK: PrivacyInfo.xcprivacy present"

if ! grep -q 'ITSAppUsesNonExemptEncryption' "$INFO_PLIST"; then
  echo "FAIL: ITSAppUsesNonExemptEncryption missing from Info.plist" >&2
  exit 1
fi
if ! grep -A1 'ITSAppUsesNonExemptEncryption' "$INFO_PLIST" | grep -q '<false/>'; then
  echo "FAIL: ITSAppUsesNonExemptEncryption must be false for exempt encryption" >&2
  exit 1
fi
echo "OK: Export compliance (ITSAppUsesNonExemptEncryption=false)"

check_production_urls() {
  local file="$1"
  local label="$2"
  if [[ ! -f "$file" ]]; then
    echo "SKIP: $label not found ($file) — run scripts/sync_flutter_dart_defines.sh"
    return 0
  fi
  if grep -Ei 'ngrok|localhost|127\.0\.0\.1' "$file" | grep -v '^[[:space:]]*//' | grep -q .; then
    echo "FAIL: $label contains ngrok or localhost (production submission must use archive.factlockcam.com)" >&2
    grep -Eni 'ngrok|localhost|127\.0\.0\.1' "$file" | grep -v '^[[:space:]]*//' >&2 || true
    exit 1
  fi
  echo "OK: $label has no ngrok/localhost"
}

check_production_urls "$DART_DEFINES" "dart_defines.json"
check_production_urls "$GENERATED_DEFINES" "generated_dart_defines.dart"

if [[ -f "$DART_DEFINES" ]]; then
  if grep -E '"ENABLE_PROOF_LINKS"[[:space:]]*:[[:space:]]*"true"' "$DART_DEFINES" >/dev/null 2>&1; then
    echo "FAIL: ENABLE_PROOF_LINKS=true in dart_defines.json — submission builds must keep false" >&2
    exit 1
  fi
  echo "OK: ENABLE_PROOF_LINKS not enabled in dart_defines.json"
fi

echo "==> flutter analyze"
(cd "$APP_DIR" && flutter analyze)

echo "==> flutter test"
(cd "$APP_DIR" && flutter test)

echo ""
echo "audit_submission_readiness: OK — Archive submission checks passed"
