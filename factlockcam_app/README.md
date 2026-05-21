# FactLockCam App

FactLockCam is a Flutter foundation for a tamper-evident local media vault.
Captured media is hashed, encrypted into a local vault, indexed in SQLite, and
shown via thumbnails. Supabase provides OTP authentication, profile-to-wallet
mapping, and an active-wallet replica of Polygon proof rows.

Any future PDF or certificate export must include the disclaimer in
`lib/core/legal/disclaimers.dart` (FRE 902 framing — supports workflow disclosure,
not guaranteed admissibility).

## Run

Supabase keys are compile-time `dart-define` values (see `lib/core/config/app_config.dart`).
Fill repo-root `.env.local` from `../.env.example` with **SUPABASE_URL** and **SUPABASE_ANON_KEY**.

**Recommended (CLI):** generates a **filtered** `dart_defines.json` (only those two keys—CLI-only
secrets such as `SUPABASE_DB_PASSWORD` stay out of the binary) and runs Flutter:

```bash
../scripts/factlockcam_supabase_pipeline.sh app-run
```

**IDE / plain `flutter run`:** sync defines from `.env.local` once (writes `dart_defines.json`
and `lib/core/config/generated_dart_defines.dart` so plain `flutter run` picks up keys):

```bash
../scripts/sync_flutter_dart_defines.sh
flutter run
```

Optional explicit defines file (overrides generated fallbacks):

```bash
flutter run --dart-define-from-file dart_defines.json
```

Or use the VS Code / Cursor launch configuration **factlockcam_app (Supabase from .env.local)**,
which runs the sync script before debug (`factlockcam_app/dart_defines.json` is gitignored).

Manual one-liners still work:

```bash
flutter run \
  --dart-define SUPABASE_URL=<project-url> \
  --dart-define SUPABASE_ANON_KEY=<rotated-public-anon-key>
```

Without those values, the local wallet shell still opens and the auth form shows
a configuration notice.

FactLockCam uses Supabase email OTP with the 6-digit `{{ .Token }}` in the email
template. No native deep-link callback is required.

## Manual Magic Number Verification

1. Launch the app on simulator/device with Supabase URL and rotated public anon key.
2. Enter an email and tap `Send Magic Number`.
3. Confirm `Check your email for the 6-digit Magic Number.` appears.
4. Type the 6-digit code from the email and tap `Verify Magic Number`.
5. Verify the app redirects to `/vault-home` (hub: Archive, Picture, Video).
6. From the hub, open **Archive** to browse photos and videos separately; use **Picture** / **Video** to capture. Tap sign out and verify the app returns to `/logon` after local burn.

## Foundation

- `lib/core/crypto/`: isolate-backed SHA-256, AES-GCM, and thumbnail work.
- `lib/data/local/`: SQLite archive index.
- `lib/data/services/`: local vault file I/O.
- `lib/domain/services/`: `VaultService`, the media gatekeeper.
- `lib/ui/`: Riverpod controllers and initial logon/dashboard views.
