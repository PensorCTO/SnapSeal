---
tags: [analysis, snapseal, application_blueprint]
summary: "Master blueprint of the current SnapSeal application state, completed capabilities, unfinished work, and working functional use cases."
---

# SnapSeal Master Blueprint

## Core Synthesis

SnapSeal is currently a Flutter application for authenticated capture, local sealing, and active-wallet proof replication. The app is framed as a mathematical certainty wallet rather than a general secrecy vault: original media enters through `VaultService`, is hashed, encrypted, stored locally, indexed in SQLite, represented by a lightweight thumbnail, and optionally synced to Supabase as an active-wallet ledger row. Polygon is still described as the intended durable proof layer, but no Polygon integration is implemented in the current codebase.

The main application shell is functional. `main.dart` initializes Supabase only when `SUPABASE_URL` and the rotated public `SUPABASE_ANON_KEY` are supplied as Dart defines. When configured, Supabase uses PKCE with URI session detection and expects the app callback `snapseal://login-callback`. The Riverpod and GoRouter stack routes unauthenticated users to `/logon`, sends authenticated users to `/dashboard`, and exposes `/camera` for capture.

Authentication is partly complete. The logon view can send Supabase Magic Links, reports unconfigured Supabase state, gives haptic feedback for success or error, and listens to Supabase auth state changes. Signing out burns local wallet data before ending the Supabase session. The local Supabase config still needs callback allow-list alignment for the custom app URL, because `supabase/config.toml` currently lists web localhost redirects but not `snapseal://login-callback`.

The local vault pipeline is the most complete functional area. Captured camera files are read off the UI isolate, hashed with SHA-256, encrypted with AES-GCM using a locally generated 256-bit key in secure storage, thumbnailed on an isolate, persisted under the app documents directory, and recorded in SQLite. The camera preview and sealing overlay are wrapped in repaint boundaries, and temporary capture files are deleted after sealing. Dashboard rendering uses thumbnail file paths and SQLite metadata rather than decrypting originals.

Supabase support is foundational but not finished. The migration creates `profiles` and `seal_ledger`, enables RLS, creates a private user-trigger function to create profiles, and allows authenticated users to insert ledger rows for their wallet. The Flutter repository can insert asset fingerprints and treat duplicate inserts for the same wallet as already synced. Failed or unavailable Supabase sync leaves local rows marked `pending_sync`, but there is no retry queue, background sync loop, or reconciliation UI yet.

The developer pipeline is mostly scaffolded. `scripts/snapseal_supabase_pipeline.sh` supports local Supabase start/reset/lint, remote login/link/push, push dry-runs, and Flutter app runs with Dart defines. GitHub Actions validates Supabase migrations on pull requests and can manually deploy migrations to a linked project. Test coverage is still minimal: one widget test verifies the logon shell renders.

## Finished or Functionally Present

- Flutter application shell with Material theming, Riverpod providers, and GoRouter routing.
- Config-aware Supabase initialization with PKCE and publishable-key support.
- Magic Link request flow with configured/unconfigured UI states.
- Supabase auth-state listener that drives authenticated routing.
- Sign-out path that burns local wallet state before Supabase sign-out.
- Camera capture screen with rear-camera preference, no-audio capture, sealing state, and error display.
- Local sealing pipeline: SHA-256 fingerprinting, AES-GCM encryption, thumbnail generation, SQLite metadata, secure local key storage, and temp capture cleanup.
- Dashboard listing from SQLite using local thumbnails and pending-sync badges.
- Local wallet burn operation that removes SQLite rows, vault files, and the secure vault key.
- Courier extraction primitive that decrypts an original and re-verifies its SHA-256 fingerprint before returning bytes.
- Supabase foundation schema for profiles, wallet IDs, active ledger rows, RLS, and new-user profile creation.
- Supabase ledger insert path from Flutter for authenticated users.
- Supabase local/remote pipeline script and CI migration validation workflow.

## Needs To Be Finished

- Add production and local deep-link configuration for `snapseal://login-callback` in Supabase and platform manifests as needed.
- Build pending-sync retry and reconciliation so offline ledger inserts can be retried after connectivity or auth returns.
- Implement Polygon proof submission and persistence; `polygon_tx_hash` exists in the database but is not written by the app.
- Add proof verification and lookup use cases beyond inserting active-wallet ledger rows.
- Add UI around courier export/extraction; `extractForCourier` exists as a service primitive but is not user-facing.
- Add wallet unlink/delete flows that intentionally invoke the private unlink behavior; the migration defines `private.unlink_active_wallet` but the app does not call it.
- Tighten Supabase Data API access validation, including any required role grants for `anon` and `authenticated` in the deployed project.
- Expand test coverage for auth controller behavior, vault sealing/extraction, pending-sync behavior, dashboard rendering, and Supabase repository edge cases.
- Add failure handling around partial local writes in the vault pipeline; current storage/database steps are sequential and do not yet roll back written files if a later local step fails.
- Replace placeholder/simple UI metaphors with the intended final capture and digital wax seal experience.

## Working Functional Use Cases

### Launch The App

The app can launch with or without Supabase configuration. Without Supabase configuration, it still renders the local wallet shell and explains that Magic Link auth requires environment configuration. With configuration, Supabase initializes before `SnapSealApp` is mounted.

### Request A Magic Link

An email address entered on `/logon` can be submitted through Supabase OTP. On success, the UI shows a "Check your email" state and emits success haptics. On failure, the controller stores the error string and the UI displays it.

### Enter The Authenticated Wallet

When Supabase supplies a session through auth state changes, GoRouter redirects from `/logon` to `/dashboard`. When no session exists, protected routes redirect back to `/logon`.

### Capture And Seal Media

An authenticated user can open `/camera`, capture an image, and pass the captured file to `VaultService`. The service hashes the original bytes, encrypts them, creates a thumbnail, writes both artifacts locally, inserts SQLite metadata, attempts Supabase ledger sync, updates `pending_sync`, deletes the temporary camera file, and returns to the dashboard.

### View The Local Wallet

The dashboard lists local archive items from SQLite in descending creation order. It renders thumbnails directly from disk and shows a shortened asset fingerprint, with a `(pending)` label when Supabase sync did not complete.

### Burn The Local Wallet

The dashboard burn action deletes archive metadata, local vault files, and the secure-storage vault key. Sign-out performs the same local burn before Supabase sign-out, so local media is removed from the device session.

### Prepare A Courier Payload

The domain service can extract a sealed asset by fingerprint, decrypt the encrypted original with the local vault key, recompute the SHA-256 hash, and throw if the decrypted bytes do not match the expected fingerprint. This use case exists at the service layer but not yet in UI.

### Validate And Push Supabase Work

Developers can run the Supabase helper script to start/reset/lint local Supabase, run the Flutter app with Supabase Dart defines, preview remote migration pushes, and push migrations. CI validates migrations on Supabase-related pull requests.

## Current Risk Register

- The product's durable-proof promise is not complete until Polygon integration exists.
- `pending_sync` can become a permanent state because no retry worker or manual retry action exists.
- Magic Link callback behavior depends on external Supabase and platform deep-link configuration that is not fully represented in `supabase/config.toml`.
- Local sealing does not yet provide an atomic transaction across file writes and SQLite metadata.
- Test coverage is too thin to protect the capture, encryption, burn, and Supabase sync paths.
- Public read access on `seal_ledger` is intentional in the migration, but deployed API role grants and privacy posture still need explicit review before production.

## Provenance Tracking

* *Application shell and routing*: Derived from `snapseal_app/lib/main.dart`, `snapseal_app/lib/app/snapseal_app.dart`, and `snapseal_app/lib/app/router/app_router.dart` (2026-04-30)
* *Authentication behavior*: Derived from `snapseal_app/lib/data/supabase/auth_repository.dart`, `snapseal_app/lib/ui/controllers/auth_controller.dart`, and `snapseal_app/lib/ui/views/logon_view.dart` (2026-04-30)
* *Capture and vault behavior*: Derived from `snapseal_app/lib/ui/views/camera/camera_view.dart`, `snapseal_app/lib/domain/services/vault_service.dart`, `snapseal_app/lib/core/crypto/cipher_engine.dart`, `snapseal_app/lib/data/local/vault_database.dart`, and `snapseal_app/lib/data/services/local_vault_storage.dart` (2026-04-30)
* *Dashboard and local wallet behavior*: Derived from `snapseal_app/lib/ui/views/dashboard_view.dart`, `snapseal_app/lib/ui/controllers/dashboard_controller.dart`, and `snapseal_app/lib/data/models/archive_item.dart` (2026-04-30)
* *Supabase schema and pipeline*: Derived from `supabase/migrations/20260428013509_snapseal_foundation.sql`, `supabase/README.md`, `supabase/config.toml`, `scripts/snapseal_supabase_pipeline.sh`, and `.github/workflows/supabase.yml` (2026-04-30)
* *Testing state*: Derived from `snapseal_app/test/widget_test.dart` (2026-04-30)

## Related Notes

* [[overview]]
* [[glossary]]
