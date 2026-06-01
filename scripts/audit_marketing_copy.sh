#!/usr/bin/env bash
# Fail if banned consumer marketing phrases appear in site/app consumer paths.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BAN_PATTERNS=(
  'Your personal history'
  'completely safe from modification'
  'Permanently authenticated'
  'Lens-to-cloud'
  'unbreakable'
  'flawless'
  'indefinite security'
  'mathematical certainty'
  'absolute anti-deepfake'
  'Absolute privacy'
  'Undeniable truth'
)

# Exclude ban-list definition files (they document forbidden phrases by name).
PATHS=(
  "$ROOT_DIR/projects/FactLockCam_Site/src/pages"
  "$ROOT_DIR/projects/FactLockCam_Site/src/components"
  "$ROOT_DIR/projects/FactLockCam_Site/src/layouts"
  "$ROOT_DIR/factlockcam_app/lib/ui/mobile/logon_view.dart"
  "$ROOT_DIR/factlockcam_app/lib/ui/mobile/vault/haptic_hub_panel.dart"
  "$ROOT_DIR/factlockcam_app/lib/ui/mobile/archive_item_actions.dart"
  "$ROOT_DIR/factlockcam_app/pubspec.yaml"
  "$ROOT_DIR/factlockcam_app/web/manifest.json"
)

failed=0
for pattern in "${BAN_PATTERNS[@]}"; do
  if rg -i --fixed-strings "$pattern" "${PATHS[@]}" 2>/dev/null; then
    echo "BANNED phrase found: $pattern" >&2
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "audit_marketing_copy: FAILED" >&2
  exit 1
fi

echo "audit_marketing_copy: OK"
