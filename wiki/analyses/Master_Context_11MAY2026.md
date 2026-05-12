---
tags: [analysis, architecture, snapseal, prooflock, system_context, phase_2]
summary: "Comprehensive architecture snapshot for 2026-05-11 covering four-panel vault UX, dual-mode capture, ProofLock-shaped seal pipeline, pending-sync reconciliation, and remaining ProofLock gaps."
---

# Master Context (11 MAY 2026)

## Core Synthesis

This page is the first-class wiki twin of `MASTER_CONTEXT11MAY2026.md` and supersedes [[Master_Context_10MAY2026]] as the most recent comprehensive architecture snapshot. The 2026-05-09 baseline ([[SnapSeal_Product_Baseline_2026-05]]) remains the canonical product status anchor, the 2026-05-11 reconciliation ([[Project_Audit_2026-05-11]]) records the repo-vs-wiki delta, and this page consolidates the resulting architecture picture.

SnapSeal is a Flutter **tamper-evident** local media vault (risk reduction / authenticity heuristics — not absolute proof-of-truth) running a **ProofLock-shaped** online seal pipeline against Supabase. The product reality is a local-first sealed-media wallet with verified logon → `/vault-home` hub → Archive / Picture / Video happy path on a correctly migrated hosted project, now extended to **dual-mode capture (photo + video)** through a single sealing pipeline and a split archive for Photos and Videos.

### Phase 2 dual-mode capture and four-panel UX (current in this snapshot)

- **`AcquisitionMode`** enum (`snapseal_app/lib/ui/views/camera/acquisition_mode.dart`) defines `photo` and `video` intents and is threaded through `app_router.dart` as a `/camera?mode=...` query parameter.
- **`VaultHomeView`** (`/vault-home`) is the post-login hub with three large actions: **Archive**, **Picture**, and **Video**. The legacy `/vault-dashboard` route redirects to `/vault-home`.
- **`ArchiveView`** (`/archive`) separates local media into **Photos** and **Videos** tabs, keeps pending-sync banners/actions, and opens shared archive actions for metadata, certificate draft, verified full-size viewing/playback, and local delete.
- **`CameraView`** initializes the camera with `enableAudio: mode.isVideo` and either `controller.takePicture()` (photo) or `controller.startVideoRecording` / `stopVideoRecording` (video). It now includes a forensic viewfinder first pass: `ReticlePainter`, `TelemetryOverlay` (`GoogleFonts.robotoMono`), and a metallic `CameraChromeFrame` around the live preview + repaint-bounded overlay stack.
- **`VaultService._inferMimeType`** maps `.mov` / `.mp4` / `.m4v` / `.webm` to `video/*` MIMEs so archive views, video playback, and future certificate code can branch on media kind.
- **Video thumbnails** use `video_thumbnail` to extract JPEG frames; empty thumbnail files are treated as missing so older sealed videos can regenerate thumbnails on archive load.
- **Owner-side viewing** now includes `ArchivePhotoView` (verified decrypt + full-size image with pinch/zoom) and `ArchiveVideoView` (verified decrypt + temp-file playback with bounded layout to avoid RenderFlex overflow).
- **Per-item local delete** removes SQLite metadata plus encrypted/thumbnail files on device, but intentionally does not delete remote proof rows.
- **Permissions:** added `NSMicrophoneUsageDescription` (`snapseal_app/ios/Runner/Info.plist`) and `android.permission.RECORD_AUDIO` (`snapseal_app/android/app/src/main/AndroidManifest.xml`).
- **Camera teardown race fix:** `CameraView.dispose()` cannot be `async`, so the asynchronous stop-then-dispose chain is delegated to a static `_teardownCamera` helper and explicitly `unawaited(...)`; this guarantees `stopVideoRecording` completes before `controller.dispose()` without violating the `State.dispose()` contract.
- **Tests:** Widget coverage now exercises hub/archive actions, photo full-size action, forensic viewfinder widgets, retry behavior, and native channel shims; `flutter analyze` + `flutter test` are green (18 tests after the archive/viewfinder changes).

### Runtime architecture (current)

1. **Auth + routing.** Supabase email OTP (6-digit "Magic Number") + GoRouter-guarded `/logon`, `/vault-home`, `/archive`, and `/camera?mode=photo|video`; legacy `/vault-dashboard` redirects to `/vault-home`. Sign-out burns the local wallet before remote sign-out.
2. **Capture + seal pipeline.** Camera capture (photo or video) → isolate read + SHA-256 → `check_proof_status` preflight → `NativeEnclaveChannel.signHash` (simulated dev payload today) → `SimulatedChainNotarizer` / `simulate_chain_notarize` RPC (or future Polygon adapter) → AES-GCM encryption + image/video thumbnail → SQLite metadata (MIME `image/*` or `video/*`) → `proof_ledger` insert when remote steps succeed, otherwise `pending_sync = true` with backoff. `_persistSealedBytes` compensates with file deletion if SQLite upsert fails after writes.
3. **Hub + archive + retrieval.** `/vault-home` offers Archive / Picture / Video. `/archive` renders Photos and Videos from SQLite + local thumbnails, including play-arrow badges for video rows. `PendingSyncScheduler` (~3 min) and `syncPendingInBackground` (hub/archive open) reconcile pending rows; a banner offers **"Retry now"**. `ArchivePhotoView` and `ArchiveVideoView` use `extractForCourier` to decrypt + re-verify SHA-256 before full-size viewing or playback. Archive actions also support local per-item delete.

### Data planes

- **Local plane (source of truth for immediate UX):** encrypted originals (image and video bytes), image/video thumbnails, SQLite archive rows with `pending_sync` + backoff, secure vault key, and local-only per-item delete behavior.
- **Remote plane:** `profiles`, `seal_ledger` (best-effort replica path in `retryPendingRemoteSync`), `proof_ledger` + `simulated_chain_ledger` (primary proof surface), repair-aligned RPCs `check_proof_status` and `simulate_chain_notarize` (`SECURITY DEFINER` with `NOTIFY pgrst`). Ledger `SELECT` is **wallet-scoped** for authenticated sessions per `supabase/migrations/20260510120000_tighten_ledger_select_rls.sql`.

### Operations and developer ergonomics

- `scripts/snapseal_supabase_pipeline.sh` provides `login`, `link`, `start`, `reset`, `lint`, `push-dry-run`, `push`, `migration-list`, `config-push`, `flutter-defines`, and `app-run`.
- `scripts/write_flutter_dart_defines.py` + `scripts/sync_flutter_dart_defines.sh` emit a **filtered** `snapseal_app/dart_defines.json` (default keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`); IDE launch runs sync as a pre-task.
- `scripts/supabase_local_hard_reset.sh` provides deterministic local Supabase recovery.
- **Operational lesson (2026-05-11):** updates to `dart_defines.json` (or rotating Supabase keys in `.env.local`) require a **cold rebuild** — a Dart hot-restart keeps stale compile-time defines and the app surfaces "Supabase is not configured yet…". Use `bash scripts/snapseal_supabase_pipeline.sh app-run` or `flutter run --dart-define-from-file dart_defines.json` after any defines change.

### Risk and gap summary

- Native `NativeEnclaveChannel.signHash` still returns simulated `SIMULATED_DEV|...` payloads on iOS and Android; Secure Enclave / Keystore work outstanding.
- `REQUIRE_HARDWARE_ATTESTATION` is defined on `AppConfig` but **not referenced** in capture/sync gating.
- `PolygonChainNotarizer` is a stub (`UnsupportedError`); `USE_POLYGON_NOTARIZER` must stay `false`.
- No production `courier_packages` / RPC-only courier table; service-layer `extractForCourier` is the owner-side viewing/playback primitive.
- C2PA pipeline is not present.
- Tests cover retry, hub/archive UI, full-size photo action, forensic viewfinder widgets, native channel, and widget shell, but failure-mode coverage for `proofLockFile` conflicts, network faults, and video-mode permissions remains thin.
- Video clips can be substantially larger than stills; pending-sync windows, encryption time, and memory pressure scale accordingly.
- Local per-item delete does not tombstone or erase remote proof rows; product policy for remote erasure/tombstones remains open.

### Suggested sequencing (architecture-forward)

1. Replace simulated `signHash` with real Secure Enclave / Keystore signing and wire `REQUIRE_HARDWARE_ATTESTATION`.
2. Implement `PolygonChainNotarizer` (or equivalent durable chain) and persist `chain_tx_hash`.
3. Expand pending-sync UX with richer diagnostics + offline awareness.
4. Land outsider-facing verification + courier `.plock` flows atop `extractForCourier`; align with the manifest's RPC-only courier model.
5. Track C2PA as a parallel advanced provenance track.
6. Expand deterministic tests for `proofLockFile` conflict paths, video capture, microphone permission flows, and Supabase repository edge cases.

## Provenance Tracking

* *Wiki navigation and status framing*: Derived from `wiki/index.md`, `wiki/overview.md`, `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md`, and [[SnapSeal_Master_Blueprint]] (2026-05-11)
* *Phase 2 dual-mode capture + four-panel UX surface*: Derived from `snapseal_app/lib/ui/views/camera/acquisition_mode.dart`, `snapseal_app/lib/ui/views/camera/camera_view.dart`, `snapseal_app/lib/ui/views/camera/camera_chrome_frame.dart`, `snapseal_app/lib/core/ui/painters/reticle_painter.dart`, `snapseal_app/lib/ui/views/camera/telemetry_overlay.dart`, `snapseal_app/lib/app/router/app_router.dart`, `snapseal_app/lib/ui/views/vault_home_view.dart`, `snapseal_app/lib/ui/views/archive_view.dart`, `snapseal_app/lib/ui/views/archive_item_actions.dart`, `snapseal_app/lib/ui/views/archive_photo_view.dart`, `snapseal_app/lib/ui/views/archive_video_view.dart`, `snapseal_app/lib/domain/services/vault_service.dart`, `snapseal_app/ios/Runner/Info.plist`, `snapseal_app/android/app/src/main/AndroidManifest.xml`, `snapseal_app/test/vault_dashboard_view_test.dart`, `snapseal_app/test/forensic_viewfinder_test.dart`, and `snapseal_app/test/widget_test.dart` (2026-05-11)
* *ProofLock-shaped seal + reconciliation surface*: Cross-checked against [[Project_Audit_2026-05-11]], `snapseal_app/lib/data/supabase/seal_ledger_repository.dart`, `snapseal_app/lib/ui/controllers/pending_sync_scheduler.dart`, `snapseal_app/lib/ui/controllers/dashboard_controller.dart`, `snapseal_app/lib/core/ghost_key/native_enclave_channel.dart`, and `snapseal_app/lib/domain/blockchain/chain_notarizer.dart` (2026-05-11)
* *Supabase ops + dart-defines pipeline*: Derived from `scripts/snapseal_supabase_pipeline.sh`, `scripts/write_flutter_dart_defines.py`, `scripts/sync_flutter_dart_defines.sh`, `scripts/supabase_local_hard_reset.sh`, `.vscode/launch.json`, `.vscode/tasks.json`, and `supabase/migrations/` (2026-05-11)
* *Source companion artifact*: This page mirrors `MASTER_CONTEXT11MAY2026.md` (2026-05-11) and supersedes [[Master_Context_10MAY2026]] as the latest comprehensive snapshot.

## Related Notes

* [[SnapSeal_Product_Baseline_2026-05]]
* [[SnapSeal_Master_Blueprint]]
* [[Project_Audit_2026-05-11]]
* [[Project_Audit_2026-05-11_Source]]
* [[ProofLock_Refactor_Scope]]
* [[ProofLock_Architectural_Manifest]]
* [[Master_Context_10MAY2026]]
* [[overview]]
* [[log]]
* [[glossary]]
