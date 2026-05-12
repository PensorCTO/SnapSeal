---
tags: [analysis, snapseal, application_blueprint]
summary: "Master blueprint of the current SnapSeal application state, completed capabilities, unfinished work, and working functional use cases."
---

# SnapSeal Master Blueprint

## Core Synthesis

**Current baseline:** verified primary workflow and compressed Supabase posture are summarized in [[SnapSeal_Product_Baseline_2026-05]] (read that page first for status).

SnapSeal is currently a Flutter application for authenticated capture, local sealing, and Supabase-backed **proof surfaces** (`check_proof_status`, simulated chain notarization, **`proof_ledger`**). The app is framed as a **tamper-evident** media vault (risk reduction / authenticity heuristics) rather than a general secrecy vault or an absolute “proof-of-reality” claim: **`VaultService.proofLockFile`** (used by capture and in-memory seal helpers) hashes in an isolate, runs **`check_proof_status`** when configured, obtains a **device signature** via `NativeEnclaveChannel` (iOS/Android handlers exist but return **simulated dev** signatures until Secure Enclave / Keystore work lands), calls **`ChainNotarizer`** (default **`SimulatedChainNotarizer`** → RPC `simulate_chain_notarize`; **`PolygonChainNotarizer`** is a **stub** that throws), encrypts with **AES-GCM** (`VaultEncryptionHandler`), persists to local storage + SQLite, and inserts **`proof_ledger`** when the remote path completes. **`seal_ledger`** remains in schema and is still touched in **`retryPendingRemoteSync`** as a best-effort replica step. Polygon as **durable** chain truth is still **not** implemented end-to-end.

The main application shell is functional. `snapseal_app/lib/main.dart` initializes Supabase only when `SUPABASE_URL` and the rotated public `SUPABASE_ANON_KEY` are supplied as Dart defines (no PKCE / URI session options in the current tree). The Riverpod and GoRouter stack routes unauthenticated users to `/logon`, sends authenticated users to `/vault-home`, exposes `/archive`, and exposes `/camera?mode=photo|video` for capture. The old `/vault-dashboard` route now redirects to `/vault-home` for compatibility.

Authentication uses **Supabase email OTP**: the logon flow sends a one-time code via `signInWithOtp`, collects a **6-digit** code in the UI, and completes session establishment with `verifyOTP` (`OtpType.email`). Unconfigured Supabase still allows the local wallet shell with an in-app notice. Signing out burns local wallet data before ending the Supabase session.

The local vault pipeline is the most complete functional area. Captured camera files are read off the UI thread via `Isolate.run`, fingerprinted (SHA-256), encrypted with **AES-GCM** using a locally generated 256-bit key in secure storage, thumbnailed (image resize for photos, native frame extraction for videos), persisted under the app documents directory, and recorded in SQLite. The camera preview and forensic overlay stack are wrapped in repaint boundaries, and temporary capture files are deleted after sealing. Archive rendering uses thumbnail file paths and SQLite metadata rather than decrypting originals; full-size photo/video viewing decrypts through the verified courier extraction path only on demand.

Core Supabase-backed capture and ledger sync are **working on a migrated hosted project** (see [[SnapSeal_Product_Baseline_2026-05]]). Foundation migrations create `profiles` and `seal_ledger`, enable RLS, attach new-user profile creation, and allow authenticated users to insert ledger rows for their wallet. A forward migration (`supabase/migrations/20260510120000_tighten_ledger_select_rls.sql`) replaces earlier **world-readable** `SELECT` on ledger tables with **wallet-scoped** reads for authenticated sessions (aligned with ProofLock tenant-boundary intent). The Flutter client implements **`SealLedgerRepository`**: `check_proof_status`, `simulate_chain_notarize`, **`seal_ledger` sync**, and **`proof_ledger` insert**. When remote work cannot finish, SQLite keeps **`pending_sync`** with exponential backoff fields; **`PendingSyncScheduler`** fire-and-forget retries every ~3 minutes, the hub/archive lifecycle triggers **`syncPendingInBackground`**, and banners offer **Retry now**. Broader gaps (real TEE signing, Polygon, C2PA, courier RPC model) remain below.

The developer pipeline is mostly scaffolded. `scripts/snapseal_supabase_pipeline.sh` supports local Supabase start/reset/lint, remote login/link/push, push dry-runs, and Flutter app runs with Dart defines. GitHub Actions validates Supabase migrations on pull requests and can manually deploy migrations to a linked project. Test coverage now covers the logon shell, retry behavior, native signing channel shim, hub/archive widgets, forensic viewfinder widgets, and archive photo/video actions (21 Flutter tests passing as of the shutter-painter refresh), but still needs deeper capture/crypto/sync failure-mode coverage.

### Relation to ProofLock manifesto (target architecture)

The ingested **ProofLock** manifest ([[ProofLock_Architectural_Manifest]]) describes a **future bar** for market viability: **hardware enclave signing**, **Polygon anchoring**, **C2PA**, **`check_proof_status` RPC**, and a **`proof_ledger` / RPC-only courier** model. SnapSeal today implements a **broader subset** than early refactor notes implied: `check_proof_status`, simulated chain (`simulate_chain_notarize`), `proof_ledger` writes, **`NativeEnclaveChannel` signing (currently simulated on device)**, backoff **`pending_sync`**, and compensating local file cleanup — but **not** production TEE signing, real Polygon, C2PA, or RPC-only courier tables. A concrete gap analysis and phased effort estimate live in [[ProofLock_Refactor_Scope]].

## Finished or Functionally Present

- Flutter application shell with Material theming, Riverpod providers, and GoRouter routing.
- Config-aware Supabase initialization with publishable-key support (Dart defines).
- Email OTP send + 6-digit verify flow with configured/unconfigured UI states.
- Supabase auth-state listener that drives authenticated routing.
- Sign-out path that burns local wallet state before Supabase sign-out.
- Vault hub (`/vault-home`) with **Archive**, **Picture**, and **Video** actions; legacy `/vault-dashboard` redirects to the hub.
- Camera capture screen with rear-camera preference, **dual `AcquisitionMode` (photo / video)** driven from the hub; the custom `ShutterButtonPainter` keeps the inner area transparent at rest, snaps white on photo tap-down, and fills Kinetic Green during video recording. Video mode enables audio, starts with long press, stops through the shutter toggle, and reuses the same seal pipeline. Sealing state and error display are shared across modes.
- Forensic viewfinder first pass: `ReticlePainter`, `TelemetryOverlay` with `GoogleFonts.robotoMono`, and metallic `CameraChromeFrame` around the live preview + repaint-bounded overlay stack.
- Local sealing pipeline: SHA-256 fingerprinting, AES-GCM encryption, image/video thumbnail generation, SQLite metadata, secure local key storage, and temp capture cleanup.
- Split archive (`/archive`) listing from SQLite using local thumbnails and pending-sync badges, separated into Photos and Videos tabs.
- Full-size owner-side photo viewing (`ArchivePhotoView`) and verified video playback (`ArchiveVideoView`) through `extractForCourier`.
- Per-item local delete from archive actions (SQLite row + encrypted/thumbnail files removed locally; remote proof rows are not erased).
- Local wallet burn operation that removes SQLite rows, vault files, and the secure vault key.
- Courier extraction primitive (`extractForCourier` + `CourierCrypto.decryptAndVerifyFingerprint`) that decrypts an original and re-verifies its SHA-256 fingerprint before returning bytes.
- **ProofLock RPC surface** from Flutter: `check_proof_status`, `simulate_chain_notarize`, `proof_ledger` insert (via `SealLedgerRepository`).
- **Native signing channel** (`NativeEnclaveChannel` / `com.snapseal.app/enclave`) with **simulated** `signHash` on iOS and Android (placeholders marked TODO for real enclave/Keystore).
- **Pending-sync reconciliation**: periodic scheduler + hub/archive lifecycle hooks + UI “Retry now”; `retryPendingRemoteSync` walks replica + proof path with backoff.
- **Compensating local cleanup** if SQLite upsert fails after encrypted/thumbnail files are written.
- **Certificate draft** dialog from archive actions (text draft via `CertificateExportService`; legal copy lives in `lib/core/legal/disclaimers.dart`).
- Supabase foundation schema for profiles, wallet IDs, ledger tables (`seal_ledger`, repair-aligned `proof_ledger` / `simulated_chain_ledger`), RLS, and new-user profile creation.
- User metadata editing (title/description) for archive rows from the vault UI.
- Supabase local/remote pipeline script and CI migration validation workflow.

## Needs To Be Finished

- Implement **real** Polygon (or other durable chain) submission in **`PolygonChainNotarizer`**; keep `USE_POLYGON_NOTARIZER=false` until then.
- Wire **`REQUIRE_HARDWARE_ATTESTATION`** (and/or stricter gating) once native signing is production-grade.
- Replace **simulated** `signHash` implementations with **hardware-backed** signing and appropriate attestation/error UX.
- Add proof **verification** and outsider-facing lookup flows beyond owner session tooling.
- Add user-facing **courier / package export** (e.g. `.plock`) atop `extractForCourier`; align with manifest **RPC-only** courier model when schema exists.
- Add wallet unlink/delete flows that intentionally invoke the private unlink behavior; the migration defines `private.unlink_active_wallet` but the app does not call it.
- Continue Supabase Data API / role-grant review (`anon` vs `authenticated`), RPC privacy review, and production RLS verification.
- Expand tests for auth transitions, full **`proofLockFile`** conflict paths (`ProofLockConflictException`), network fault injection, and Supabase repository edge cases (beyond current retry/dashboard/enclave/widget coverage).
- Replace placeholder/simple UI metaphors with the intended final capture and digital wax seal experience.
- **ProofLock viability track:** C2PA, anti-injection capture strategy, and courier black-box schema (see [[ProofLock_Refactor_Scope]]).

## Working Functional Use Cases

### Launch The App

The app can launch with or without Supabase configuration. Without Supabase configuration, it still renders the local wallet shell and explains that **Magic Number** (email OTP) auth requires environment configuration. With configuration, Supabase initializes before `SnapSealApp` is mounted.

### Request A Magic Number (Email OTP)

An email address entered on `/logon` can be submitted through `signInWithOtp`. On success, the UI prompts for the **6-digit** code. On failure, the controller stores the error string and the UI displays it.

### Enter The Authenticated Wallet

When Supabase supplies a session through auth state changes, GoRouter redirects from `/logon` to `/vault-home`. When no session exists, protected routes redirect back to `/logon`. Legacy `/vault-dashboard` redirects to `/vault-home`.

### Capture And Seal Media

An authenticated user picks **Picture** or **Video** from the `/vault-home` hub, which routes to `/camera?mode=<photo|video>`. The shared `CameraView` uses a custom-painted shutter: photo tap-down rapidly fills the inner radius white before capture, while video long-press starts recording and fills the inner radius with Kinetic Green until a later shutter action stops recording. The resulting `XFile` passes through **`VaultService.sealAndStoreCapture` → `proofLockFile`**. The pipeline runs isolate hashing, **`check_proof_status`** (when online), **simulated native `signHash`**, **simulated chain notarization**, local AES-GCM persistence + SQLite (MIME inferred for `image/*` and `video/*`), image/video thumbnail generation, **`proof_ledger`** insert when remote steps succeed, `pending_sync` + backoff when they do not, deletes the temporary capture file, and returns to the previous hub/archive navigation context. **Baseline:** verified on a correctly migrated hosted project ([[SnapSeal_Product_Baseline_2026-05]]). **Audit:** see [[Project_Audit_2026-05-11]] for simulation vs production caveats.

### View The Local Wallet

The `/archive` screen lists local archive items from SQLite in descending creation order, separated into **Photos** and **Videos** tabs. It renders thumbnails from disk, shows shortened fingerprints, **pending-sync** badges, a **banner** when any item is pending (with **Retry now**), and supports **certificate draft**, metadata, and delete actions from the item sheet. `video/*` items render native frame thumbnails where available plus a play-arrow overlay badge, falling back to a `videocam_outlined` placeholder if decode fails. Tapping a video row opens `ArchiveVideoView`, which uses the courier extract path (`VaultService.extractForCourier`) to decrypt + verify the fingerprint before playback in a temp file. Tapping a photo row can open `ArchivePhotoView`, which uses the same verified extraction path to display the original with pinch/zoom.

### Burn The Local Wallet

The hub's overflow menu burn action deletes archive metadata, local vault files, and the secure-storage vault key. Sign-out performs the same local burn before Supabase sign-out, so local media is removed from the device session. Per-item archive delete removes only one local row and its encrypted/thumbnail files; it intentionally does not delete remote proof rows.

### Prepare A Courier Payload

The domain service can extract a sealed asset by fingerprint, decrypt the encrypted original with the local vault key, recompute the SHA-256 hash, and throw if the decrypted bytes do not match the expected fingerprint. This use case exists at the service layer but not yet in UI.

### Validate And Push Supabase Work

Developers can run the Supabase helper script to start/reset/lint local Supabase, run the Flutter app with Supabase Dart defines, preview remote migration pushes, and push migrations. CI validates migrations on Supabase-related pull requests.

## Current Risk Register

- The product's durable on-chain proof story is not complete until a real **`PolygonChainNotarizer`** (or equivalent) exists; simulated RPC remains the default.
- `pending_sync` can still linger when auth is missing or errors are non-recoverable; backoff and **silent** best-effort retries may need stronger user-visible diagnostics.
- Ledger `SELECT` is wallet-scoped after `20260510120000_tighten_ledger_select_rls.sql`; continue to review grants (`anon` vs `authenticated`), RPC surfaces (`check_proof_status`), and privacy posture before production.
- Local delete is device-local only; product policy for proof-row tombstones or remote erasure remains undecided.
- Test coverage is improved but still too thin to protect the full capture, encryption, burn, and Supabase sync failure matrix.
- **Simulated signing risk:** software-only `signHash` responses are **not** ProofLock-grade hardware provenance; they are development placeholders on the path to Secure Enclave / Keystore.
- **ProofLock-class risk:** software-delivered camera bytes + simulated signatures do not prove physical sensor origin; enterprise spoofing scenarios remain out of scope until native TEE signing and capture hardening land ([[ProofLock_Refactor_Scope]]).

## Provenance Tracking

* *Application shell and routing*: Derived from `snapseal_app/lib/main.dart`, `snapseal_app/lib/app/snapseal_app.dart`, and `snapseal_app/lib/app/router/app_router.dart` (2026-04-30; routing re-verified 2026-05-03)
* *Authentication behavior*: Derived from `snapseal_app/lib/data/supabase/auth_repository.dart`, `snapseal_app/lib/ui/controllers/auth_controller.dart`, and `snapseal_app/lib/ui/views/logon_view.dart` (2026-05-03)
* *Capture and vault behavior*: Derived from `snapseal_app/lib/ui/views/camera/camera_view.dart`, `snapseal_app/lib/core/ui/painters/shutter_button_painter.dart`, `snapseal_app/lib/domain/services/vault_service.dart`, `snapseal_app/lib/core/crypto/cipher_engine.dart`, `snapseal_app/lib/core/crypto/vault_encryption_handler.dart`, `snapseal_app/lib/data/local/vault_database.dart`, and `snapseal_app/lib/data/services/local_vault_storage.dart` (2026-05-03; vault façade noted 2026-05-10; shutter painter refresh 2026-05-11)
* *Hub, archive, and local wallet behavior*: Derived from `snapseal_app/lib/ui/views/vault_home_view.dart`, `snapseal_app/lib/ui/views/archive_view.dart`, `snapseal_app/lib/ui/views/archive_item_actions.dart`, `snapseal_app/lib/ui/views/archive_photo_view.dart`, `snapseal_app/lib/ui/views/archive_video_view.dart`, `snapseal_app/lib/ui/controllers/dashboard_controller.dart`, and `snapseal_app/lib/data/models/archive_item.dart` (2026-04-30; re-verified 2026-05-10; four-panel UX + archive delete/full-size view/video thumbnails refreshed 2026-05-11)
* *Supabase schema and pipeline*: Derived from `supabase/migrations/20260428013509_snapseal_foundation.sql`, `supabase/migrations/20260510120000_tighten_ledger_select_rls.sql`, `supabase/README.md`, `supabase/config.toml`, `scripts/snapseal_supabase_pipeline.sh`, and `.github/workflows/supabase.yml` (2026-04-30; RLS tighten 2026-05-10)
* *ProofLock target architecture*: Derived from `raw/prooflock_architectural_manifest.md` via [[ProofLock_Architectural_Manifest]] (2026-05-03)
* *Testing state*: Derived from `snapseal_app/test/widget_test.dart`, `snapseal_app/test/vault_service_retry_test.dart`, `snapseal_app/test/vault_dashboard_view_test.dart`, `snapseal_app/test/native_enclave_channel_test.dart` (2026-05-11)
* *Post-May-10 reconciliation*: [[Project_Audit_2026-05-11]]
* *Product baseline and hosted DB repairs*: Cross-checked with [[SnapSeal_Product_Baseline_2026-05]] (2026-05-09)

## Related Notes

* [[SnapSeal_Product_Baseline_2026-05]]
* [[overview]]
* [[glossary]]
* [[ProofLock_Architectural_Manifest]]
* [[ProofLock_Refactor_Scope]]
* [[Project_Audit_2026-05-11]]
