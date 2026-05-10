# SnapSeal App

SnapSeal is a Flutter foundation for a mathematical certainty wallet. Captured
media is intended to be hashed, encrypted into a local vault, indexed in SQLite,
and displayed through local thumbnails. Supabase provides OTP authentication,
profile-to-wallet mapping, and an active-wallet replica of Polygon proof rows.

## Run

```bash
flutter run \
  --dart-define SUPABASE_URL=<project-url> \
  --dart-define SUPABASE_ANON_KEY=<rotated-public-anon-key>
```

Without those values, the local wallet shell still opens and the auth form shows
a configuration notice.

SnapSeal uses Supabase email OTP with the 6-digit `{{ .Token }}` in the email
template. No native deep-link callback is required.

For the standard repo pipeline, copy `../.env.example` to `../.env.local`, fill
the SnapSeal project values, then run:

```bash
../scripts/snapseal_supabase_pipeline.sh app-run
```

## Manual Magic Number Verification

1. Launch the app on simulator/device with Supabase URL and rotated public anon key.
2. Enter an email and tap `Send Magic Number`.
3. Confirm `Check your email for the 6-digit Magic Number.` appears.
4. Type the 6-digit code from the email and tap `Verify Magic Number`.
5. Verify the app redirects to `/vault-dashboard`.
6. Tap sign out and verify the app returns to `/logon` after local burn.

## Foundation

- `lib/core/crypto/`: isolate-backed SHA-256, AES-GCM, and thumbnail work.
- `lib/data/local/`: SQLite archive index.
- `lib/data/services/`: local vault file I/O.
- `lib/domain/services/`: `VaultService`, the media gatekeeper.
- `lib/ui/`: Riverpod controllers and initial logon/dashboard views.
