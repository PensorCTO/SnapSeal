#!/bin/sh
# Re-signs all embedded .framework bundles after Flutter embed_and_thin and CocoaPods.
#
# Flutter copies native-asset frameworks (e.g. objective_c.framework) on iOS without
# applying EXPANDED_CODE_SIGN_IDENTITY (macOS-only in xcode_backend.dart). Device
# install then fails with MIInstallerErrorDomain Code 13 / 0xe8008014.

set -eu

FRAMEWORKS_DIR="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks"

if [ ! -d "${FRAMEWORKS_DIR}" ]; then
  exit 0
fi

if [ "${CODE_SIGNING_ALLOWED:-}" != "YES" ]; then
  exit 0
fi

if [ -z "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] || [ "${EXPANDED_CODE_SIGN_IDENTITY}" = "-" ]; then
  echo "warning: Sign Embedded Frameworks skipped (no signing identity)."
  exit 0
fi

echo "Signing embedded frameworks in ${FRAMEWORKS_DIR}"

find "${FRAMEWORKS_DIR}" -maxdepth 1 -name '*.framework' -type d | while read -r framework; do
  name=$(basename "${framework}" .framework)
  binary="${framework}/${name}"
  if [ ! -e "${binary}" ]; then
    continue
  fi
  /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
    --preserve-metadata=identifier,entitlements,flags \
    "${binary}"
  /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
    --preserve-metadata=identifier,entitlements,flags \
    "${framework}"
done
