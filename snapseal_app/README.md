# SnapSeal App

SnapSeal is a Flutter foundation for a mathematical certainty wallet. Captured
media is intended to be hashed, encrypted into a local vault, indexed in SQLite,
and displayed through local thumbnails. Supabase provides OTP authentication,
profile-to-wallet mapping, and an active-wallet replica of Polygon proof rows.

## Run

```bash
flutter run \
  --dart-define SUPABASE_URL=<project-url> \
  --dart-define SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

Without those values, the local wallet shell still opens and the auth form shows
a configuration notice.

Configure Supabase Auth URL allow-list with:

- `snapseal://login-callback`

The app uses PKCE with native deep-link handling built into `supabase_flutter`.

For the standard repo pipeline, copy `../.env.example` to `../.env.local`, fill
the SnapSeal project values, then run:

```bash
../scripts/snapseal_supabase_pipeline.sh app-run
```

## Manual Magic Link Verification

1. Launch the app on simulator/device with Supabase URL and publishable key.
2. Enter an email and tap `Send Magic Link`.
3. Confirm `Check your email for the Magic Link.` appears.
4. Open the email and tap the link containing `snapseal://login-callback`.
5. Verify app logs include auth state updates and the app redirects to `/dashboard`.
6. Tap sign out and verify the app returns to `/logon` after local burn.

## Foundation

- `lib/core/crypto/`: isolate-backed SHA-256, AES-GCM, and thumbnail work.
- `lib/data/local/`: SQLite archive index.
- `lib/data/services/`: local vault file I/O.
- `lib/domain/services/`: `VaultService`, the media gatekeeper.
- `lib/ui/`: Riverpod controllers and initial logon/dashboard views.
