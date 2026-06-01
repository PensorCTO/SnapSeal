# FactLockCam — App Store submission checklist (Sprint 4)

## Build

```bash
cd factlockcam_app
flutter pub get
flutter test
flutter build ipa --release \
  --dart-define-from-file=dart_defines.json
```

Upload the IPA from `build/ios/ipa/` via Transporter or Xcode Organizer.

## Privacy manifest

- [ ] Confirm `ios/Runner/PrivacyInfo.xcprivacy` is included in the Runner target (Copy Bundle Resources).
- [ ] App Store Connect **App Privacy** labels match the manifest (photos/videos, user ID for account; no tracking).

## Manual interruption QA (Xcode / device)

1. Start a large photo or video seal from the camera hub.
2. While the sealing overlay is visible, background the app (Home gesture).
3. Optional: stop the process from Xcode debug bar to simulate SIGKILL.
4. Relaunch — archive chronology and grid must show no broken thumbnails or zero-byte placeholders.
5. Repeat with aggressive scroll/tap on the in-flight asset card during seal.

## Automated torture (optional CI)

```bash
cd factlockcam_app
flutter test integration_test/asset_lock_torture_test.dart -d <device_id>
```

Requires a physical or simulator device with integration_test driver wiring.

## Journal integrity

- [ ] After forced termination during `prepared`, boot recovery rolls back journal rows (see `BootRecoveryService`).
- [ ] UI lock overlay clears after recovery (`syncLocksFromPreparedJournal` runs post-open in DI).
