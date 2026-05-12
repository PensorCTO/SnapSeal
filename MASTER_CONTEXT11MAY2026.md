# Master Context — 11 MAY 2026

This is the comprehensive architecture snapshot of `ProofLockCleanup` as of 11 MAY 2026. It supersedes `Master_Context10MAY2026.md` (which is preserved verbatim as a frozen snapshot). For the canonical product status entry, see `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md`; for the most recent repo-vs-wiki reconciliation, see `wiki/analyses/Project_Audit_2026-05-11.md`.

---

## 1) Project identity and intent

`ProofLockCleanup` hosts a Flutter product named **SnapSeal**, positioned as a **tamper-evident** local media vault (authenticity heuristics and risk reduction — not claims of absolute proof-of-truth) for authenticated capture, local sealing, and Supabase-backed ledger replication. The repository also operates an LLM Wiki used as the canonical synthesis layer for architecture, constraints, and ongoing alignment with a stricter future-state target called **ProofLock**.

- **SnapSeal (current reality):** local-first secure media handling (photos *and now videos*) + Supabase-backed proof surfaces (`check_proof_status`, `simulate_chain_notarize`, `proof_ledger`).
- **ProofLock (target architecture):** hardware-backed signing, pre-flight proof-status RPC, Polygon anchoring, C2PA, and stronger courier/verification guarantees.

Canonical status anchor: `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md`.

---

## 2) Repository architecture map

- `snapseal_app/` — Flutter mobile app (core product runtime).
- `supabase/` — database schema, migrations, and local/remote Supabase project assets.
- `scripts/` — repeatable operational wrappers for Supabase, dart-defines, and environment workflows.
- `wiki/` — LLM-maintained architecture knowledge base and decision context.
- `raw/` — immutable source material for wiki ingestion.

Conceptually a **product + architecture-knowledge dual system**: build/operate the app and DB; continuously synthesize and track architecture truth in the wiki.

---

## 3) Current system architecture (runtime view)

### 3.1 End-to-end user flow (verified happy path)

1. User logs in via Supabase email OTP ("Magic Number", 6-digit code).
2. From `/vault-dashboard`, user picks a capture intent via **dual FABs**:
   - **Photo** (`AcquisitionMode.photo`) → single shutter tap.
   - **Video** (`AcquisitionMode.video`) → tap to start, tap to stop; REC indicator + red shutter while recording.
3. The resulting `XFile` (image or `.mov` / `.mp4`) flows through `VaultService.sealAndStoreCapture → proofLockFile`:
   - isolate-hashed (SHA-256),
   - online preflight via `check_proof_status` RPC,
   - device signature via `NativeEnclaveChannel` (iOS/Android handlers present but **simulated** today),
   - simulated chain notarization via `simulate_chain_notarize` (default; `PolygonChainNotarizer` is still a stub),
   - AES-GCM encryption + thumbnail + SQLite metadata (MIME inferred as `image/*` or `video/*`),
   - `proof_ledger` insert when remote steps succeed; otherwise `pending_sync = true` with backoff.
4. App returns to `/vault-dashboard` with the new row visible:
   - thumbnail + shortened fingerprint,
   - **play-arrow badge overlay** on `video/*` rows (with a `videocam_outlined` fallback when image decode fails),
   - pending-sync badge when remote work is incomplete,
   - banner + **"Retry now"** action when any rows are pending.
5. Tapping a video row opens `ArchiveVideoView`, which uses the courier extract path (`VaultService.extractForCourier`) to decrypt + re-verify the SHA-256 before playback in a temp file.

### 3.2 Runtime architecture slices

- **Presentation layer (Flutter UI + routing):**
  - GoRouter auth-gated routes: `/logon`, `/vault-dashboard`, `/camera?mode=photo|video`.
  - Riverpod-driven state (auth, dashboard, vault).
  - `VaultDashboardView` provides the dual-mode entry point and the pending-sync UX.

- **Domain/service layer:**
  - `VaultService` orchestrates sealing/extraction workflows for both photo and video media.
  - `proofLockFile` enforces the ProofLock-shaped sequence; `retryPendingRemoteSync` walks pending rows and best-effort retouches `seal_ledger`.
  - `CertificateExportService` drafts text certificates (legal copy lives in `lib/core/legal/disclaimers.dart`).

- **Data/local persistence layer:**
  - Encrypted asset files + thumbnails on device storage.
  - SQLite metadata for archive listing/state, including `pending_sync` and backoff fields.
  - Encryption key in platform secure storage; compensating delete of files if SQLite upsert fails after writes.

- **Remote sync/ledger layer (Supabase):**
  - Email-OTP auth sessions and profile/wallet identity model.
  - `proof_ledger` writes on the happy remote path; `seal_ledger` retained as best-effort replica step.
  - `check_proof_status` and `simulate_chain_notarize` RPCs (`SECURITY DEFINER`).

---

## 4) Flutter application architecture (current state)

### 4.1 Platform stack

- Framework: Flutter + Dart.
- State management: Riverpod.
- Navigation: GoRouter.
- Auth/session backend: Supabase.
- Media plugins: `camera` (capture, video recording), `video_player` (playback of decrypted clips), `shared_plus` / `pdf` / `printing` for later certificate flows.

### 4.2 App initialization and configuration

- `snapseal_app/lib/main.dart` initializes Supabase only when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are available via compile-time `--dart-define` values; unconfigured mode still renders the shell with an auth notice.
- `AppConfig` also exposes `USE_POLYGON_NOTARIZER` and `REQUIRE_HARDWARE_ATTESTATION`. The latter is defined but **not yet wired** into capture/sync control flow.
- Define values are produced by `scripts/write_flutter_dart_defines.py` (filtered, only `SUPABASE_URL` + `SUPABASE_ANON_KEY` by default) and synced via `scripts/sync_flutter_dart_defines.sh`. IDE launch runs sync pre-debug.
- **Operational lesson (2026-05-11):** updating `dart_defines.json` (or rotating Supabase keys in `.env.local`) requires a **cold rebuild** of the Flutter app; a Dart hot-restart will keep stale compile-time defines and the runtime will report "Supabase is not configured yet…". Use `bash scripts/snapseal_supabase_pipeline.sh app-run` (or `flutter run --dart-define-from-file dart_defines.json`) instead of hot-restarting after a defines change.

### 4.3 Auth architecture

- Email OTP send via `signInWithOtp`.
- OTP verify (6-digit `OtpType.email`) establishes session.
- Auth state changes drive GoRouter route access.
- Sign-out path burns the local wallet (vault files, SQLite rows, secure key) before ending the remote session.

### 4.4 Capture and sealing architecture (Phase 2 dual-mode)

The capture pipeline is performance-constrained and security-constrained, and is now **dual-mode**:

- `AcquisitionMode` enum (`snapseal_app/lib/ui/views/camera/acquisition_mode.dart`) defines `photo` and `video` intents. The router parses `mode` from the `/camera?mode=...` query parameter.
- `CameraView` initializes the camera with `enableAudio: mode.isVideo` and either:
  - **Photo:** `controller.takePicture()` on shutter tap.
  - **Video:** `controller.startVideoRecording()` on first tap, `controller.stopVideoRecording()` on second tap; a REC indicator and red shutter glow render while recording.
- The resulting `XFile` always flows through `VaultService.sealAndStoreCapture → proofLockFile`, so photos and videos share identical sealing semantics. The pipeline performs:
  1. Isolate read + SHA-256 hash.
  2. Optional `check_proof_status` preflight (treats only `new` as proceedable; conflicts surface as `ProofLockConflictException`).
  3. `NativeEnclaveChannel.signHash` (simulated dev signature today).
  4. `ChainNotarizer.notarize` (default `SimulatedChainNotarizer` → RPC; `PolygonChainNotarizer` throws `UnsupportedError`).
  5. AES-GCM encryption (`VaultEncryptionHandler`) + thumbnail generation.
  6. `VaultDatabase` upsert with MIME (`image/*` or `video/*` depending on extension).
  7. `proof_ledger` insert on remote success; otherwise mark `pending_sync` with backoff.
  8. Temp capture cleanup.
- **Race-condition fix:** `CameraView.dispose()` previously called `stopVideoRecording()` without awaiting it before `controller.dispose()`. The framework contract forbids `async dispose`, so we now wrap the asynchronous teardown in a static helper (`_teardownCamera`) and explicitly `unawaited(...)` it, ensuring `stopVideoRecording` completes before the controller is torn down without violating `State.dispose()`'s synchronous contract.
- **Permissions:**
  - iOS: `NSCameraUsageDescription` and **`NSMicrophoneUsageDescription`** in `snapseal_app/ios/Runner/Info.plist`.
  - Android: `android.permission.CAMERA` and **`android.permission.RECORD_AUDIO`** in `snapseal_app/android/app/src/main/AndroidManifest.xml`.

### 4.5 Dashboard architecture

- Reads archive list from SQLite, not from decrypted originals.
- Side-by-side **Photo / Video** extended FABs replace the previous single "Capture" FAB; the burn-local-wallet action remains below.
- `video/*` rows render a play-arrow badge overlay on top of the thumbnail. When the stored thumbnail bytes cannot decode as an image (for video clips this can be the original frame or a placeholder), the grid falls back to a `videocam_outlined` icon.
- Pending-sync UX: per-row badge, top-level banner, and **Retry now** trigger `DashboardController.syncPendingInBackground`. `PendingSyncScheduler` also fires every ~3 minutes while the dashboard is alive.
- Tapping a video row opens `ArchiveVideoView`, which decrypts via `VaultService.extractForCourier`, writes a temp file, and plays it via `video_player`.

### 4.6 Data consistency behavior

- If SQLite upsert fails after asset files are written, `VaultService._persistSealedBytes` deletes the encrypted file and thumbnail to keep local state coherent.
- `retryPendingRemoteSync` walks `pending_sync` rows with exponential backoff, touching `seal_ledger` (best-effort replica) and the proof path; success clears the pending flag.

---

## 5) Data architecture

### 5.1 Local data model

- Encrypted originals and thumbnails on filesystem.
- Archive metadata in SQLite (`pending_sync`, backoff fields, MIME, fingerprint, timestamps).
- Encryption key in secure storage.

Local layer remains source-of-truth for immediate UX rendering (photos *and* videos).

### 5.2 Remote data model (Supabase)

- `profiles` (user profile + wallet identity mapping).
- `seal_ledger` (foundation active-wallet ledger replica; still used by `retryPendingRemoteSync`).
- `proof_ledger` + `simulated_chain_ledger` (repair-aligned ProofLock-style surfaces; primary insert target on the happy path).

Historical schema drift across hosted projects has been narrowed by repair migrations:

- `supabase/migrations/20260509160000_repair_remote_prooflock_schema.sql` — destructively rebuilds the canonical proof surface and RPCs.
- `supabase/migrations/20260509200000_backfill_profiles_from_auth_users.sql` — backfills missing `profiles` / `wallet_id` rows.
- `supabase/migrations/20260510120000_tighten_ledger_select_rls.sql` — replaces world-readable ledger `SELECT` with **wallet-scoped authenticated** reads.

### 5.3 RPC architecture status

- `check_proof_status(p_file_hash text)` → ownership status string.
- `simulate_chain_notarize(p_file_hash text, p_device_signature text)` → simulated tx hash.
- Both `SECURITY DEFINER` with `NOTIFY pgrst, 'reload schema';` for PostgREST metadata refresh after structural changes.

---

## 6) Supabase operations architecture

### 6.1 Scripted workflow pattern

`scripts/snapseal_supabase_pipeline.sh` centralizes:

- login / link / start / reset / lint
- push-dry-run / push
- `migration-list` (loads `.env.local`; needs `SUPABASE_DB_PASSWORD`)
- `config-push`
- `flutter-defines` (writes `snapseal_app/dart_defines.json` from `.env.local`, filtered)
- `app-run` (writes defines + runs Flutter with `--dart-define-from-file`)

The wrapper loads repo `.env.local`, ensuring required remote DB credentials are present and that compile-time defines are baked in for cold builds.

### 6.2 Local environment recovery

`scripts/supabase_local_hard_reset.sh` provides a deterministic local reset:

- Verifies Docker / CLI.
- Stops stack without backup.
- Removes lingering containers/volumes matching project naming patterns.
- Restarts stack and resets the DB.
- Prints status for validation.

### 6.3 Dart-defines pipeline

- `scripts/write_flutter_dart_defines.py` reads `.env.local` + process env, filters to `SUPABASE_URL` / `SUPABASE_ANON_KEY`, and emits `snapseal_app/dart_defines.json`.
- `scripts/sync_flutter_dart_defines.sh` is a thin shell wrapper used as a VS Code / Cursor pre-launch task.
- `dart_defines.json` is gitignored.

### 6.4 CI posture

Migration validation runs in CI for Supabase-related changes; manual deploy paths are available via the pipeline script.

---

## 7) Knowledge architecture (LLM wiki system)

Karpathy-style LLM Wiki:

- `raw/` immutable sources (now includes `raw/project_audit_2026-05-11.md`).
- `wiki/sources/` source summaries (incl. `Project_Audit_2026-05-11_Source`).
- `wiki/concepts/` stable concept pages (`SnapSeal_Product_Baseline_2026-05` is the status anchor).
- `wiki/analyses/` deep-dive analyses (`SnapSeal_Master_Blueprint`, `ProofLock_Refactor_Scope`, `Master_Context_10MAY2026`, **`Master_Context_11MAY2026`**, `Project_Audit_2026-05-11`).
- `wiki/index.md` as navigation root.
- `wiki/log.md` as append-only evolution trail.

Reading order for product state:

1. `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md` (status anchor).
2. `wiki/analyses/SnapSeal_Master_Blueprint.md` (capability map).
3. `wiki/analyses/Project_Audit_2026-05-11.md` (post-2026-05-10 reconciliation).
4. `wiki/analyses/Master_Context_11MAY2026.md` (this snapshot's wiki twin).
5. `wiki/analyses/ProofLock_Refactor_Scope.md` (gap-to-target roadmap).
6. `wiki/sources/ProofLock_Architectural_Manifest.md` (target manifest synthesis).

`Master_Context_10MAY2026.md` and `System_Context_Audit_2026-05-09.md` are retained as archived snapshots.

---

## 8) Security and integrity architecture snapshot

### 8.1 What is solid today

- Local file hashing + AES-GCM encrypted-at-rest media workflow for photos **and** videos.
- Secure-storage key usage.
- Off-main-thread heavy IO/hash via `Isolate.run`.
- ProofLock-shaped online seal path: `check_proof_status` → `signHash` (channel) → `simulate_chain_notarize` → `proof_ledger`.
- Compensating local file cleanup on SQLite failure after writes.
- Pending-sync scheduler (~3 min) + dashboard-open background sync + UI "Retry now".
- Wallet-scoped ledger `SELECT` RLS for authenticated sessions.
- Local wallet burn on sign-out.
- Auth-gated app routing.
- Awaited camera teardown that stops in-flight video recordings before disposing the controller.

### 8.2 What remains incomplete for "ProofLock-grade" guarantees

- Hardware-backed signing path is **simulated** in `NativeEnclaveChannel` (iOS Secure Enclave / Android Keystore TODOs remain).
- `REQUIRE_HARDWARE_ATTESTATION` flag exists on `AppConfig` but is **not yet referenced** in capture/sync gating.
- `PolygonChainNotarizer` still throws `UnsupportedError`; durable on-chain proof is unimplemented.
- No C2PA generation/embedding pipeline.
- No production `courier_packages` / RPC-only courier surface; service-layer `extractForCourier` is the only courier primitive today.
- Test depth is improved (retry, dashboard, native channel) but remains thinner than a production bar on crypto/capture/sync failure modes.

---

## 9) Architectural constraints and invariants

- High-frequency capture/seal visuals stay in repaint boundaries.
- Heavy IO/crypto stays off UI thread (`Isolate.run`).
- "Seal completed" with external notarization semantics requires both the local commit **and** the `proof_ledger` insert; otherwise the row is `pending_sync` and reconciliation is responsible.
- Product copy must not overclaim hardware-backed provenance until native signing is real.
- Camera teardown must finalize `stopVideoRecording` before `controller.dispose()`.
- PDF / certificate exports must include the FRE 902 disclaimer (`lib/core/legal/disclaimers.dart`).

---

## 10) Gap analysis: current state vs target state

### 10.1 Current architecture class

**Local-first secure media wallet (photo + video) with ProofLock-shaped, partially simulated remote proof replication and a basic reconciliation loop.**

### 10.2 Target architecture class (ProofLock)

**Hardware-attested capture-to-ledger proof system with chain anchoring, RPC-only courier, and standards-compliant provenance packaging.**

### 10.3 Largest gap clusters (unchanged or narrowed)

1. **Trust root gap:** simulated native signatures vs Secure Enclave / Keystore + attestation.
2. **Durable proof gap:** `simulate_chain_notarize` vs Polygon (or equivalent) anchoring with persisted tx hashes.
3. **Interoperability gap:** no C2PA artifact lifecycle.
4. **Reliability gap:** `pending_sync` scheduler + UI retry exist, but rich diagnostics and offline-aware UX are still thin.
5. **Verification gap:** no outsider-facing proof verification / courier `.plock` UX.
6. **Assurance gap:** test matrix still narrow on crypto + sync failure modes.

---

## 11) Current risks and operational cautions

- Hosted Supabase schema drift remains a risk; future migrations should keep contracts tight and continue using the wrapper script to load `.env.local`.
- The 2026-05-09 repair migration is destructive for prior `proof_ledger` rows; never run it on a hosted DB with retained legacy data without backup.
- Ledger `SELECT` is wallet-scoped; continue privacy/security review for `check_proof_status` and any verification UX.
- Simulated `signHash` payloads (`SIMULATED_DEV|...`) must not be marketed as hardware-backed provenance.
- Cold builds are required after `dart_defines.json` changes; otherwise stale compile-time defines surface as "Supabase is not configured yet…".
- Video clips can be substantially larger than stills; storage, encryption time, and pending-sync retry windows scale accordingly. Watch for memory pressure on long clips and consider streaming hash/encrypt in a future hardening pass.
- Microphone permission prompts now appear on first video capture; copy already framed for "preserving original soundtrack" — ensure App Store / Play review notes match.

---

## 12) Practical architecture roadmap (from this baseline)

1. Replace simulated `NativeEnclaveChannel.signHash` with Secure Enclave / Keystore signing and wire `REQUIRE_HARDWARE_ATTESTATION` into capture gating.
2. Implement `PolygonChainNotarizer` (or an equivalent durable chain adapter) and persist `chain_tx_hash`.
3. Expand pending-sync reconciliation UX with richer diagnostics and offline awareness.
4. Land outsider-facing verification + courier `.plock` flows atop `extractForCourier`; align with the manifest's RPC-only courier table model.
5. Track C2PA as a parallel advanced provenance track.
6. Expand deterministic tests for `proofLockFile` conflict paths, video-mode capture, microphone permission flows, and Supabase repository edge cases.
7. Replace placeholder capture/seal UI metaphors with the intended final wax-seal experience.

---

## 13) Executive summary

As of 11 MAY 2026, SnapSeal is a functioning local-first sealed-media vault that now captures and seals **both photos and videos** through a single ProofLock-shaped pipeline, with Supabase-backed proof surfaces (`check_proof_status`, `simulate_chain_notarize`, `proof_ledger`), wallet-scoped ledger RLS, a pending-sync scheduler with UI "Retry now", and compensating local file cleanup. Native enclave signing is wired as a channel but still returns simulated payloads; Polygon and C2PA remain unimplemented. The architecture has matured along reliability, atomicity, and capture-mode axes, but remains pre-viability relative to the ProofLock bar. The next trajectory is unchanged: replace simulation with real hardware signing, land durable chain anchoring, and complete the verification/courier UX.

---

## 14) Pointers

- Status anchor: `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md`
- Capability map: `wiki/analyses/SnapSeal_Master_Blueprint.md`
- Reconciliation audit: `wiki/analyses/Project_Audit_2026-05-11.md`
- Wiki twin of this file: `wiki/analyses/Master_Context_11MAY2026.md`
- Gap-to-target: `wiki/analyses/ProofLock_Refactor_Scope.md`
- Phase 2 blueprint: `PHASE_2_Blueprints10MAY2026.md`
- Prior snapshot (archived): `Master_Context10MAY2026.md`
