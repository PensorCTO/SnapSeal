---
tags: [analysis, architecture, factlockcam, prooflock, system_context, phase_2]
summary: "Comprehensive architecture snapshot for 2026-05-11 covering four-panel vault UX, dual-mode capture, ProofLock-shaped seal pipeline, pending-sync reconciliation, and remaining ProofLock gaps."
---

# Master Context (11 MAY 2026)

## Core Synthesis

This page is the first-class wiki twin of `MASTER_CONTEXT11MAY2026.md`; for the **latest dated roll-forward**, see [[MASTER_CONTEXT13MAY2026]]. It superseded [[Master_Context_10MAY2026]] until 2026-05-13 and remains authoritative for granular 2026-05-11 provenance citations. The 2026-05-09 baseline ([[FactLockCam_Product_Baseline_2026-05]]) remains the canonical product status anchor, the 2026-05-11 reconciliation ([[Project_Audit_2026-05-11]]) records the repo-vs-wiki delta, and this page consolidates the resulting architecture picture for that date.

FactLockCam is a Flutter **tamper-evident** local media vault (risk reduction / authenticity heuristics — not absolute proof-of-truth) running a **ProofLock-shaped** online seal pipeline against Supabase. The product reality is a local-first sealed-media wallet with verified logon → `/vault-home` hub → Archive / Picture / Video happy path on a correctly migrated hosted project, now extended to **dual-mode capture (photo + video)** through a single sealing pipeline and a split archive for Photos and Videos.

### Phase 2 dual-mode capture and four-panel UX (current in this snapshot)

- **`AcquisitionMode`** enum (`factlockcam_app/lib/ui/views/camera/acquisition_mode.dart`) defines `photo` and `video` intents and is threaded through `app_router.dart` as a `/camera?mode=...` query parameter.
- **`VaultHomeView`** (`/vault-home`) is the post-login hub with three large actions: **Archive**, **Picture**, and **Video**. The legacy `/vault-dashboard` route redirects to `/vault-home`.
- **`ArchiveView`** (`/archive`) separates local media into **Photos** and **Videos** tabs, keeps pending-sync banners/actions, and opens shared archive actions for metadata, certificate draft, verified full-size viewing/playback, and local delete.
- **`CameraView`** initializes the camera with `enableAudio: mode.isVideo` and either `controller.takePicture()` (photo) or `controller.startVideoRecording` / `stopVideoRecording` (video). Its shutter is now custom-painted by `ShutterButtonPainter`: a white stroked ring with transparent center at rest, a 150 ms `Curves.easeOutExpo` white inner snap on photo tap-down, and a Kinetic Green (`0xFF00D26A`) inner fill while video recording. It also includes a forensic viewfinder first pass: `ReticlePainter`, `TelemetryOverlay` (`GoogleFonts.robotoMono`), and a metallic `CameraChromeFrame` around the live preview + repaint-bounded overlay stack.
- **`VaultService._inferMimeType`** maps `.mov` / `.mp4` / `.m4v` / `.webm` to `video/*` MIMEs so archive views, video playback, and future certificate code can branch on media kind.
- **Video thumbnails** use `video_thumbnail` to extract JPEG frames; empty thumbnail files are treated as missing so older sealed videos can regenerate thumbnails on archive load. When thumbnails are regenerated from decrypted bytes, temp files now use MIME-aware extensions (`.mov`, `.webm`, `.mp4`, etc.) instead of hardcoded `.mp4`.
- **Owner-side viewing** now includes `ArchivePhotoView` (verified decrypt + full-size image with pinch/zoom) and `ArchiveVideoView` (verified decrypt + temp-file playback with bounded layout to avoid RenderFlex overflow). `ArchivePhotoView` caches its verified extraction future per asset fingerprint to avoid repeated decrypt/verify work on rebuilds.
- **Domain Interaction Contract:** `MediaActionType`, `AssetActionRegistry`, `AssetAction`, and `UniversalAssetToolbar` standardize archive view/verify/delete/share/export actions from each asset's `mediaType` string. Archive cards remain repaint-bounded, and delete/verify actions delegate through Riverpod/GetIt bridge providers to the vault service layer.
- **Per-item local delete** removes SQLite metadata plus encrypted/thumbnail files on device, but intentionally does not delete remote proof rows.
- **Permissions:** added `NSMicrophoneUsageDescription` (`factlockcam_app/ios/Runner/Info.plist`) and `android.permission.RECORD_AUDIO` (`factlockcam_app/android/app/src/main/AndroidManifest.xml`).
- **Camera teardown and failure-state fixes:** `CameraView.dispose()` cannot be `async`, so the asynchronous stop-then-dispose chain is delegated to a static `_teardownCamera` helper and explicitly `unawaited(...)`; this guarantees `stopVideoRecording` completes before `controller.dispose()` without violating the `State.dispose()` contract. Sealing failures also clear stale `_isRecording` state so the telemetry overlay does not keep showing `[REC]` after recording has stopped.
- **Tests:** Widget/unit coverage now exercises hub/archive actions, media action registry/toolbar behavior, photo full-size action and rebuild caching, forensic viewfinder widgets, retry behavior, native channel shims, and MIME-aware video thumbnail temp extension mapping; `flutter analyze` + `flutter test` are green (31 tests after the archive action + hardening refresh).

### Runtime architecture (current)

1. **Auth + routing.** Supabase email OTP (6-digit "Magic Number") + GoRouter-guarded `/logon`, `/vault-home`, `/archive`, and `/camera?mode=photo|video`; legacy `/vault-dashboard` redirects to `/vault-home`. Sign-out burns the local wallet before remote sign-out.
2. **Capture + seal pipeline.** Camera capture (photo or video) → isolate read + SHA-256 → `check_proof_status` preflight → `NativeEnclaveChannel.signHash` (simulated dev payload today) → `SimulatedChainNotarizer` / `simulate_chain_notarize` RPC (or future Polygon adapter) → AES-GCM encryption + image/video thumbnail → SQLite metadata (MIME `image/*` or `video/*`) → `proof_ledger` insert when remote steps succeed, otherwise `pending_sync = true` with backoff. `_persistSealedBytes` compensates with file deletion if SQLite upsert fails after writes; video thumbnail regeneration from decrypted bytes preserves MIME-specific temp extensions.
3. **Hub + archive + retrieval.** `/vault-home` offers Archive / Picture / Video. `/archive` renders Photos and Videos from SQLite + local thumbnails, including play-arrow badges for video rows. `PendingSyncScheduler` (~3 min) and `syncPendingInBackground` (hub/archive open) reconcile pending rows; a banner offers **"Retry now"**. `ArchivePhotoView` and `ArchiveVideoView` use `extractForCourier` to decrypt + re-verify SHA-256 before full-size viewing or playback, with photo extraction cached per fingerprint. Archive actions are media-type-driven through the Domain Interaction Contract and still support local per-item delete.

### Data planes

- **Local plane (source of truth for immediate UX):** encrypted originals (image and video bytes), image/video thumbnails, SQLite archive rows with `pending_sync` + backoff, secure vault key, and local-only per-item delete behavior.
- **Remote plane:** `profiles`, `seal_ledger` (best-effort replica path in `retryPendingRemoteSync`), `proof_ledger` + `simulated_chain_ledger` (primary proof surface), repair-aligned RPCs `check_proof_status` and `simulate_chain_notarize` (`SECURITY DEFINER` with `NOTIFY pgrst`). Ledger `SELECT` is **wallet-scoped** for authenticated sessions per `supabase/migrations/20260510120000_tighten_ledger_select_rls.sql`.

### Operations and developer ergonomics

- `scripts/factlockcam_supabase_pipeline.sh` provides `login`, `link`, `start`, `reset`, `lint`, `push-dry-run`, `push`, `migration-list`, `config-push`, `flutter-defines`, and `app-run`.
- `scripts/write_flutter_dart_defines.py` + `scripts/sync_flutter_dart_defines.sh` emit a **filtered** `factlockcam_app/dart_defines.json` (default keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`); IDE launch runs sync as a pre-task.
- `scripts/supabase_local_hard_reset.sh` provides deterministic local Supabase recovery.
- **Operational lesson (2026-05-11):** updates to `dart_defines.json` (or rotating Supabase keys in `.env.local`) require a **cold rebuild** — a Dart hot-restart keeps stale compile-time defines and the app surfaces "Supabase is not configured yet…". Use `bash scripts/factlockcam_supabase_pipeline.sh app-run` or `flutter run --dart-define-from-file dart_defines.json` after any defines change.

### Risk and gap summary

- Native `NativeEnclaveChannel.signHash` still returns simulated `SIMULATED_DEV|...` payloads on iOS and Android; Secure Enclave / Keystore work outstanding.
- `REQUIRE_HARDWARE_ATTESTATION` is defined on `AppConfig` but **not referenced** in capture/sync gating.
- `PolygonChainNotarizer` is a stub (`UnsupportedError`); `USE_POLYGON_NOTARIZER` must stay `false`.
- No production `courier_packages` / RPC-only courier table; service-layer `extractForCourier` is the owner-side viewing/playback primitive.
- C2PA pipeline is not present.
- Tests cover retry, hub/archive UI, action registry/toolbar behavior, full-size photo action and rebuild caching, forensic viewfinder widgets, native channel, video thumbnail MIME extension mapping, and widget shell, but failure-mode coverage for `proofLockFile` conflicts, network faults, and video-mode permissions remains thin.
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

* *Wiki navigation and status framing*: Derived from `wiki/index.md`, `wiki/overview.md`, `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`, and [[FactLockCam_Master_Blueprint]] (2026-05-11)
* *Phase 2 dual-mode capture + four-panel UX surface*: Derived from `factlockcam_app/lib/ui/views/camera/acquisition_mode.dart`, `factlockcam_app/lib/ui/views/camera/camera_view.dart`, `factlockcam_app/lib/ui/views/camera/camera_chrome_frame.dart`, `factlockcam_app/lib/core/ui/painters/reticle_painter.dart`, `factlockcam_app/lib/core/ui/painters/shutter_button_painter.dart`, `factlockcam_app/lib/ui/views/camera/telemetry_overlay.dart`, `factlockcam_app/lib/app/router/app_router.dart`, `factlockcam_app/lib/ui/views/vault_home_view.dart`, `factlockcam_app/lib/ui/views/archive_view.dart`, `factlockcam_app/lib/ui/views/archive_item_actions.dart`, `factlockcam_app/lib/core/archive/domain/models/media_action_type.dart`, `factlockcam_app/lib/core/archive/domain/services/asset_action_registry.dart`, `factlockcam_app/lib/core/archive/presentation/widgets/universal_asset_toolbar.dart`, `factlockcam_app/lib/features/archive/presentation/providers/asset_action_provider.dart`, `factlockcam_app/lib/ui/views/archive_photo_view.dart`, `factlockcam_app/lib/ui/views/archive_video_view.dart`, `factlockcam_app/lib/domain/services/vault_service.dart`, `factlockcam_app/ios/Runner/Info.plist`, `factlockcam_app/android/app/src/main/AndroidManifest.xml`, `factlockcam_app/test/vault_dashboard_view_test.dart`, `factlockcam_app/test/archive_asset_actions_test.dart`, `factlockcam_app/test/archive_photo_view_test.dart`, `factlockcam_app/test/vault_service_video_thumbnail_test.dart`, `factlockcam_app/test/forensic_viewfinder_test.dart`, and `factlockcam_app/test/widget_test.dart` (2026-05-11; shutter-painter refresh added 2026-05-11; archive action contract + hardening refresh added 2026-05-12)
* *ProofLock-shaped seal + reconciliation surface*: Cross-checked against [[Project_Audit_2026-05-11]], `factlockcam_app/lib/data/supabase/seal_ledger_repository.dart`, `factlockcam_app/lib/ui/controllers/pending_sync_scheduler.dart`, `factlockcam_app/lib/ui/controllers/dashboard_controller.dart`, `factlockcam_app/lib/core/ghost_key/native_enclave_channel.dart`, and `factlockcam_app/lib/domain/blockchain/chain_notarizer.dart` (2026-05-11)
* *Supabase ops + dart-defines pipeline*: Derived from `scripts/factlockcam_supabase_pipeline.sh`, `scripts/write_flutter_dart_defines.py`, `scripts/sync_flutter_dart_defines.sh`, `scripts/supabase_local_hard_reset.sh`, `.vscode/launch.json`, `.vscode/tasks.json`, and `supabase/migrations/` (2026-05-11)
* *Source companion artifact*: This page mirrors `MASTER_CONTEXT11MAY2026.md` (2026-05-11) and superseded [[Master_Context_10MAY2026]] until 2026-05-13; the roll-forward consolidated snapshot is [[MASTER_CONTEXT13MAY2026]].

## Related Notes

* [[FactLockCam_Product_Baseline_2026-05]]
* [[FactLockCam_Master_Blueprint]]
* [[Project_Audit_2026-05-11]]
* [[Project_Audit_2026-05-11_Source]]
* [[ProofLock_Refactor_Scope]]
* [[ProofLock_Architectural_Manifest]]
* [[Master_Context_10MAY2026]]
* [[MASTER_CONTEXT13MAY2026]]
* [[overview]]
* [[log]]
* [[glossary]]
