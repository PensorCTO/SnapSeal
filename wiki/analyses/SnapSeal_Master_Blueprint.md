---
tags: [analysis, snapseal, application_blueprint]
summary: "Master blueprint of the current SnapSeal application state, completed capabilities, unfinished work, and working functional use cases."
---

# SnapSeal Master Blueprint

## Core Synthesis

**Current baseline:** verified primary workflow and compressed Supabase posture are summarized in [[SnapSeal_Product_Baseline_2026-05]] (read that page first for status).

SnapSeal is currently a Flutter application for authenticated capture, local sealing, and active-wallet proof replication. The app is framed as a **tamper-evident** media vault (risk reduction / authenticity heuristics) rather than a general secrecy vault or an absolute “proof-of-reality” claim: original media enters through `VaultService` (`snapseal_app/lib/domain/services/vault_service.dart`), is hashed, encrypted (AES-GCM via `VaultEncryptionHandler` / `CipherEngine`), stored locally, indexed in SQLite, represented by a lightweight thumbnail, and optionally synced to Supabase as an active-wallet ledger row. Polygon is still described as the intended durable proof layer, but no Polygon integration is implemented in the current codebase.

The main application shell is functional. `snapseal_app/lib/main.dart` initializes Supabase only when `SUPABASE_URL` and the rotated public `SUPABASE_ANON_KEY` are supplied as Dart defines (no PKCE / URI session options in the current tree). The Riverpod and GoRouter stack routes unauthenticated users to `/logon`, sends authenticated users to `/vault-dashboard`, and exposes `/camera` for capture.

Authentication uses **Supabase email OTP**: the logon flow sends a one-time code via `signInWithOtp`, collects a **6-digit** code in the UI, and completes session establishment with `verifyOTP` (`OtpType.email`). Unconfigured Supabase still allows the local wallet shell with an in-app notice. Signing out burns local wallet data before ending the Supabase session.

The local vault pipeline is the most complete functional area. Captured camera files are read off the UI thread via `Isolate.run`, fingerprinted (SHA-256), encrypted with **AES-GCM** using a locally generated 256-bit key in secure storage, thumbnailed, persisted under the app documents directory, and recorded in SQLite. The camera preview and sealing overlay are wrapped in repaint boundaries, and temporary capture files are deleted after sealing. Dashboard rendering uses thumbnail file paths and SQLite metadata rather than decrypting originals.

Core Supabase-backed capture and ledger sync are **working on a migrated hosted project** (see [[SnapSeal_Product_Baseline_2026-05]]). Foundation migrations create `profiles` and `seal_ledger`, enable RLS, attach new-user profile creation, and allow authenticated users to insert ledger rows for their wallet. A forward migration (`supabase/migrations/20260510120000_tighten_ledger_select_rls.sql`) replaces earlier **world-readable** `SELECT` on ledger tables with **wallet-scoped** reads for authenticated sessions (aligned with ProofLock tenant-boundary intent). The Flutter repository can insert asset fingerprints and treat duplicate inserts for the same wallet as already synced. Failed or unavailable Supabase sync leaves local rows marked `pending_sync`, but there is no retry queue, background sync loop, or reconciliation UI yet. Broader product gaps (Polygon, reconciliation UX, ProofLock-class hardening) remain below.

The developer pipeline is mostly scaffolded. `scripts/snapseal_supabase_pipeline.sh` supports local Supabase start/reset/lint, remote login/link/push, push dry-runs, and Flutter app runs with Dart defines. GitHub Actions validates Supabase migrations on pull requests and can manually deploy migrations to a linked project. Test coverage is still minimal: one widget test verifies the logon shell renders.

### Relation to ProofLock manifesto (target architecture)

The ingested **ProofLock** manifest ([[ProofLock_Architectural_Manifest]]) describes a **future bar** for market viability: **hardware enclave signing**, **Polygon anchoring**, **C2PA**, **`check_proof_status` RPC**, and a **`proof_ledger` / RPC-only courier** model. SnapSeal today implements **only a subset** (local hashing, encrypted vault, Supabase ledger insert, isolate discipline). A concrete gap analysis and phased effort estimate live in [[ProofLock_Refactor_Scope]].

## Finished or Functionally Present

- Flutter application shell with Material theming, Riverpod providers, and GoRouter routing.
- Config-aware Supabase initialization with publishable-key support (Dart defines).
- Email OTP send + 6-digit verify flow with configured/unconfigured UI states.
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

- Build pending-sync retry and reconciliation so offline ledger inserts can be retried after connectivity or auth returns.
- Implement Polygon proof submission and persistence; `polygon_tx_hash` exists in the database but is not written by the app.
- Add proof verification and lookup use cases beyond inserting active-wallet ledger rows.
- Add UI around courier export/extraction; `extractForCourier` exists as a service primitive but is not user-facing.
- Add wallet unlink/delete flows that intentionally invoke the private unlink behavior; the migration defines `private.unlink_active_wallet` but the app does not call it.
- Tighten Supabase Data API access validation, including any required role grants for `anon` and `authenticated` in the deployed project, especially while `seal_ledger` remains world-readable by policy.
- Expand test coverage for auth controller behavior, vault sealing/extraction, pending-sync behavior, dashboard rendering, and Supabase repository edge cases.
- Add failure handling around partial local writes in the vault pipeline; current storage/database steps are sequential and do not yet roll back written files if a later local step fails.
- Replace placeholder/simple UI metaphors with the intended final capture and digital wax seal experience.
- **ProofLock viability track:** native Secure Enclave / Keystore signing path, C2PA FFI, and anti-injection capture strategy (see [[ProofLock_Refactor_Scope]]).

## Working Functional Use Cases

### Launch The App

The app can launch with or without Supabase configuration. Without Supabase configuration, it still renders the local wallet shell and explains that **Magic Number** (email OTP) auth requires environment configuration. With configuration, Supabase initializes before `SnapSealApp` is mounted.

### Request A Magic Number (Email OTP)

An email address entered on `/logon` can be submitted through `signInWithOtp`. On success, the UI prompts for the **6-digit** code. On failure, the controller stores the error string and the UI displays it.

### Enter The Authenticated Wallet

When Supabase supplies a session through auth state changes, GoRouter redirects from `/logon` to `/vault-dashboard`. When no session exists, protected routes redirect back to `/logon`.

### Capture And Seal Media

An authenticated user can open `/camera`, capture an image, and pass the captured file to `VaultService`. The service hashes the original bytes, encrypts them, creates a thumbnail, writes both artifacts locally, inserts SQLite metadata, attempts Supabase ledger sync, updates `pending_sync`, deletes the temporary camera file, and returns to the dashboard. **Baseline (2026-05):** this path is verified end-to-end on a correctly migrated Supabase project ([[SnapSeal_Product_Baseline_2026-05]]).

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
- Ledger `SELECT` is wallet-scoped after `20260510120000_tighten_ledger_select_rls.sql`; continue to review grants (`anon` vs `authenticated`), RPC surfaces (`check_proof_status`), and privacy posture before production.
- Local sealing does not yet provide an atomic transaction across file writes and SQLite metadata.
- Test coverage is too thin to protect the capture, encryption, burn, and Supabase sync paths.
- **ProofLock-class risk:** software-only capture + hash path does not prove physical sensor origin; enterprise spoofing scenarios remain out of scope until native TEE signing and capture hardening land ([[ProofLock_Refactor_Scope]]).

## Provenance Tracking

* *Application shell and routing*: Derived from `snapseal_app/lib/main.dart`, `snapseal_app/lib/app/snapseal_app.dart`, and `snapseal_app/lib/app/router/app_router.dart` (2026-04-30; routing re-verified 2026-05-03)
* *Authentication behavior*: Derived from `snapseal_app/lib/data/supabase/auth_repository.dart`, `snapseal_app/lib/ui/controllers/auth_controller.dart`, and `snapseal_app/lib/ui/views/logon_view.dart` (2026-05-03)
* *Capture and vault behavior*: Derived from `snapseal_app/lib/ui/views/camera/camera_view.dart`, `snapseal_app/lib/domain/services/vault_service.dart`, `snapseal_app/lib/core/crypto/cipher_engine.dart`, `snapseal_app/lib/core/crypto/vault_encryption_handler.dart`, `snapseal_app/lib/data/local/vault_database.dart`, and `snapseal_app/lib/data/services/local_vault_storage.dart` (2026-05-03; vault façade noted 2026-05-10)
* *Dashboard and local wallet behavior*: Derived from `snapseal_app/lib/ui/views/vault_dashboard_view.dart`, `snapseal_app/lib/ui/controllers/dashboard_controller.dart`, and `snapseal_app/lib/data/models/archive_item.dart` (2026-04-30; re-verified 2026-05-10)
* *Supabase schema and pipeline*: Derived from `supabase/migrations/20260428013509_snapseal_foundation.sql`, `supabase/migrations/20260510120000_tighten_ledger_select_rls.sql`, `supabase/README.md`, `supabase/config.toml`, `scripts/snapseal_supabase_pipeline.sh`, and `.github/workflows/supabase.yml` (2026-04-30; RLS tighten 2026-05-10)
* *ProofLock target architecture*: Derived from `raw/prooflock_architectural_manifest.md` via [[ProofLock_Architectural_Manifest]] (2026-05-03)
* *Testing state*: Derived from `snapseal_app/test/widget_test.dart` (2026-05-03)
* *Product baseline and hosted DB repairs*: Cross-checked with [[SnapSeal_Product_Baseline_2026-05]] (2026-05-09)

## Related Notes

* [[SnapSeal_Product_Baseline_2026-05]]
* [[overview]]
* [[glossary]]
* [[ProofLock_Architectural_Manifest]]
* [[ProofLock_Refactor_Scope]]
