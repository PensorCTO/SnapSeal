---
tags: [analysis, architecture, factlockcam, prooflock, system_context, phase_2]
summary: "Comprehensive architecture snapshot for 2026-05-13: four-panel vault UX, dual-mode capture, ProofLock-shaped seal pipeline, Domain Interaction Contract, pending-sync reconciliation, and remaining ProofLock-class gaps."
---

# Master Context (13 MAY 2026)

## Core Synthesis

This page is the **current** comprehensive architecture snapshot for FactLockCam as of **2026-05-13**. It supersedes [[Master_Context_11MAY2026]] for timeline currency; substantive product behavior matches the 2026-05-11/12 wiki consolidation (dual-mode capture, four-panel UX, archive action contract, capture/archive hardening). **Canonical verified workflow and hosted-Supabase repair narrative** remain in [[FactLockCam_Product_Baseline_2026-05]]; **finish-line vs ProofLock manifest** remains in [[ProofLock_Refactor_Scope]]; **repo-vs-wiki audit table** remains in [[Project_Audit_2026-05-11]]. **Repository check (2026-05-13):** `flutter test` reports **31 passing tests** across **nine** files under `factlockcam_app/test/` (hub/archive, forensic viewfinder, shutter behavior, retry path, native channel shim, asset actions, photo-view caching, video-thumbnail MIME temp extensions, widget shell).

FactLockCam is a Flutter **tamper-evident** local media vault—authenticity heuristics and risk reduction, **not** a claim of absolute proof-of-truth or sensor-origin certainty. Against a configured Supabase project it runs a **ProofLock-shaped** online path: preflight **`check_proof_status`**, **`NativeEnclaveChannel.signHash`** (still **simulated** on device), **`SimulatedChainNotarizer`** / **`simulate_chain_notarize`**, local **AES-GCM** sealing, SQLite metadata, and **`proof_ledger`** insertion when remote steps succeed, with **`pending_sync`** plus backoff otherwise.

### Product surface (authenticated shell)

| Area | Behavior |
| :--- | :--- |
| **Routes** | GoRouter: `/logon`, `/vault-home`, `/archive`, `/camera?mode=photo\|video`; legacy `/vault-dashboard` → `/vault-home`. Sign-out burns the local wallet before remote sign-out. |
| **Hub** | `VaultHomeView`: **Archive**, **Picture**, **Video**. |
| **Archive** | Split **Photos** / **Videos** tabs; thumbnails from disk; pending-sync badges; banner with **Retry now**; registry-driven actions; per-item **local** delete (no remote proof erasure); full-size photo (`ArchivePhotoView`) and verified video playback (`ArchiveVideoView`) via **`extractForCourier`**. |
| **Capture** | Shared `CameraView` with **`AcquisitionMode`**: photo `takePicture()`, video `startVideoRecording` / `stopVideoRecording` with **`enableAudio`** in video mode. Custom **`ShutterButtonPainter`**: transparent center at rest, brief white inner snap on photo press, Kinetic Green fill while recording. Forensic overlay stack: **`ReticlePainter`**, **`TelemetryOverlay`**, **`CameraChromeFrame`**; high-frequency visuals remain repaint-bounded per project rules. |
| **MIME & media** | `VaultService._inferMimeType` maps common video extensions to `video/*`. Video thumbnails use `video_thumbnail`; empty thumbnails treated as missing for regeneration; temp files for regenerated thumbs use **MIME-aware** extensions (`.mov`, `.webm`, `.mp4`, etc.). |
| **Domain Interaction Contract** | `MediaActionType`, `AssetActionRegistry`, `AssetAction`, **`UniversalAssetToolbar`** drive archive actions from each asset's media type rather than bespoke buttons. |
| **Hardening (carried forward)** | `ArchivePhotoView` caches verified extraction future per asset fingerprint to avoid redundant decrypt/verify on rebuilds. **`CameraView`** teardown uses **`_teardownCamera`** so `stopVideoRecording` completes before `dispose`; sealing failures clear stale **`_isRecording`** / REC UX. **`_persistSealedBytes`** compensates by deleting encrypted + thumbnail files if SQLite upsert fails after writes. |

### Seal and sync runtime (conceptual ordering)

1. Capture → **`Isolate.run`** read + SHA-256 fingerprint.
2. When online/configured: **`check_proof_status`** (e.g. `new` path); conflict → **`ProofLockConflictException`**.
3. **`NativeEnclaveChannel.signHash`** → today returns **developer-simulated** payloads (Secure Enclave / Keystore still TODO).
4. **`ChainNotarizer`**: default **`SimulatedChainNotarizer`** → **`simulate_chain_notarize`**; **`PolygonChainNotarizer`** remains a stub—keep **`USE_POLYGON_NOTARIZER`** false until implemented.
5. AES-GCM encrypt, image or video thumbnail, SQLite upsert (`image/*` or `video/*` metadata).
6. **`proof_ledger`** insert on happy remote path; else **`pending_sync`** with backoff. **`retryPendingRemoteSync`** still touches **`seal_ledger`** as best-effort replica work.
7. **`PendingSyncScheduler`** (~3 min) plus hub/archive **`syncPendingInBackground`** reconcile pending rows; UI exposes **Retry now**.

### Data and security posture

- **Local source of truth for UX:** encrypted originals, thumbnails, SQLite rows (including backoff fields), secure vault key. Temp capture files removed after sealing on success paths.
- **Remote:** **`profiles`**, **`seal_ledger`**, **`proof_ledger`**, **`simulated_chain_ledger`**; RPCs **`check_proof_status`**, **`simulate_chain_notarize`**. Ledger **`SELECT`** is **wallet-scoped** for authenticated sessions per **`supabase/migrations/20260510120000_tighten_ledger_select_rls.sql`**.
- **`REQUIRE_HARDWARE_ATTESTATION`** exists on **`AppConfig`** but is **not wired** into capture/sync gating yet.

### Developer operations

- **`scripts/factlockcam_supabase_pipeline.sh`**: login, link, local start/reset, lint, push dry-run/push, migration list, config push, Flutter defines, app run.
- **`scripts/write_flutter_dart_defines.py`** + **`scripts/sync_flutter_dart_defines.sh`** (and IDE pre-launch tasks) emit **filtered** **`factlockcam_app/dart_defines.json`** (default keys **`SUPABASE_URL`**, **`SUPABASE_ANON_KEY`**).
- **Operational lesson:** after changing defines or rotating keys, perform a **cold rebuild**—hot restart can leave stale compile-time defines and surface “Supabase is not configured” incorrectly.

### Risk and gap summary (unchanged priorities)

Major gaps relative to [[ProofLock_Architectural_Manifest]] remain: **hardware-backed signing**, **real Polygon** (or equivalent) anchoring, **C2PA**, **courier / `.plock` UX** atop **`extractForCourier`**, **`courier_packages` / RPC-only courier** schema, outsider verification surfaces, richer **`pending_sync`** diagnostics, **`REQUIRE_HARDWARE_ATTESTATION`** wiring, deeper tests for **`proofLockFile`** conflicts and network/crypto edge cases. Local per-item delete does not tombstone remote proofs—policy still open.

### Suggested sequencing (architecture-forward)

1. Replace simulated **`signHash`** with Secure Enclave / Keystore signing; gate on **`REQUIRE_HARDWARE_ATTESTATION`** when appropriate.
2. Implement durable chain write path (**`PolygonChainNotarizer`** or successor); persist real **`chain_tx_hash`** semantics.
3. Expand pending-sync UX (offline clarity, actionable errors).
4. Ship outsider verification + courier packaging aligned with manifest RPC boundaries.
5. Track C2PA and capture hardening as parallel ProofLock viability work ([[ProofLock_Refactor_Scope]]).

## Provenance Tracking

* *Wiki synthesis anchors*: Consolidated from `wiki/index.md`, `wiki/overview.md`, [[FactLockCam_Product_Baseline_2026-05]], [[FactLockCam_Master_Blueprint]], [[ProofLock_Refactor_Scope]], [[Project_Audit_2026-05-11]], and [[Master_Context_11MAY2026]] (2026-05-13).
* *Repo root shortcut*: `MASTER_CONTEXT13MAY2026.md` at repository root links here (mirroring the `MASTER_CONTEXT11MAY2026.md` companion pattern).
* *Prior snapshot*: Supersedes [[Master_Context_11MAY2026]] as the dated **master context** sibling; [[Master_Context_10MAY2026]] remains historical.
* *Verification on 2026-05-13*: `flutter test` in `factlockcam_app/` (31 passing); test files include `vault_service_retry_test.dart`, `vault_service_video_thumbnail_test.dart`, `archive_photo_view_test.dart`, `archive_asset_actions_test.dart`, `vault_dashboard_view_test.dart`, `forensic_viewfinder_test.dart`, `camera_shutter_button_test.dart`, `native_enclave_channel_test.dart`, `widget_test.dart`.

## Related Notes

* [[FactLockCam_Blueprints_14May2026]] - Layered technical blueprint (2026-05-14); onboarding-oriented companion to this snapshot.
* [[FactLockCam_Product_Baseline_2026-05]]
* [[FactLockCam_Master_Blueprint]]
* [[Project_Audit_2026-05-11]]
* [[ProofLock_Refactor_Scope]]
* [[ProofLock_Architectural_Manifest]]
* [[Master_Context_11MAY2026]]
* [[Master_Context_10MAY2026]]
* [[overview]]
* [[log]]
* [[glossary]]
