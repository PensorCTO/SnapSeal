---
tags: [log, maintenance, llm_wiki]
summary: "Append-only activity log for ingests, queries, lint passes, and major wiki maintenance."
---

# Wiki Log

## [2026-04-26] ingest | Sample LLM Wiki Source

- Added `raw/sample_llm_wiki_source.md`.
- Created `wiki/sources/Sample_Source.md`.
- Created `wiki/concepts/LLM_Wiki_Pattern.md`.
- Initialized `wiki/index.md`, `wiki/overview.md`, and `wiki/glossary.md`.
- Marked sample source as `COMPILED` in `manifest.md`.

## [2026-04-30] analysis | FactLockCam Master Blueprint

- Created `wiki/analyses/FactLockCam_Master_Blueprint.md`.
- Documented finished capabilities, unfinished work, working functional use cases, and current risks for the FactLockCam app.
- Updated `wiki/index.md`, `wiki/overview.md`, and `wiki/glossary.md` to include the FactLockCam blueprint.

## [2026-05-03] ingest | ProofLock Architectural Manifest

- Added immutable source `raw/prooflock_architectural_manifest.md`.
- Created `wiki/sources/ProofLock_Architectural_Manifest.md`.
- Created `wiki/analyses/ProofLock_Refactor_Scope.md` (manifest ↔ codebase gap analysis and phased effort).
- Updated `wiki/analyses/FactLockCam_Master_Blueprint.md` for email OTP auth and ProofLock target alignment.
- Updated `wiki/index.md`, `wiki/overview.md`, `wiki/glossary.md`, and aligned Cursor rules for capture paths and foundation constraints.
- Marked manifest row `COMPILED` in `manifest.md`.

## [2026-05-09] analysis | System Context Audit

- Created `wiki/analyses/System_Context_Audit_2026-05-09.md`.
- Audited git status, wiki health, Flutter implementation surfaces, Supabase migrations, and pipeline scripts.
- Re-validated wiki with `python3 scripts/wiki_ingest.py --validate` and app smoke tests with `flutter test`.
- Updated `wiki/index.md` to include the new comprehensive context baseline page.

## [2026-05-09] maintenance | Product baseline and wiki consolidation

- Added `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md` as the canonical FactLockCam status entry (verified workflow, compressed DB repair/backfill narrative).
- Replaced `wiki/analyses/System_Context_Audit_2026-05-09.md` body with a short archived stub pointing to the baseline.
- Updated `wiki/analyses/FactLockCam_Master_Blueprint.md`, `wiki/overview.md`, `wiki/index.md`, and `wiki/glossary.md` to link the baseline and trim duplicated audit prominence.
- Re-ran `python3 scripts/wiki_ingest.py --validate`.

## [2026-05-10] analysis | Master context architecture snapshot

- Added `wiki/analyses/Master_Context_10MAY2026.md` as a schema-compliant first-class wiki artifact (frontmatter, core synthesis, provenance, related notes).
- Indexed the new analysis in `wiki/index.md` under Analyses.
- Captured a comprehensive current-state architecture snapshot spanning Flutter runtime, local vault/data model, Supabase operations/migrations, and ProofLock gap framing.

## [2026-05-10] maintenance | Phase 2 vault-first dashboard route

- Replaced `/dashboard` with `/vault-dashboard` via `VaultDashboardView` (`factlockcam_app/lib/ui/views/vault_dashboard_view.dart`).
- Added background pending-sync attempts (`VaultDatabase.listPendingArchiveItems`, `VaultService.retryPendingRemoteSync`, `DashboardController` fire-and-forget refresh).
- Updated `wiki/analyses/FactLockCam_Master_Blueprint.md`, `wiki/analyses/Master_Context_10MAY2026.md`, and `factlockcam_app/README.md`; ran `flutter test` / `dart analyze`.

## [2026-05-10] maintenance | Tamper-evident wording + ledger RLS (wiki)

- Aligned FactLockCam product framing with Rule 03 / app copy: **tamper-evident** media vault and risk-reduction language (not “mathematical certainty wallet”).
- Updated `wiki/overview.md`, `wiki/glossary.md`, and `wiki/analyses/FactLockCam_Master_Blueprint.md` (including ledger `SELECT` now wallet-scoped per `20260510120000_tighten_ledger_select_rls.sql`).
- Re-ran `python3 scripts/wiki_ingest.py --validate`.

## [2026-05-10] maintenance | Repo root snapshots: tamper-evident wording

- Updated `Master_Context10MAY2026.md` and `PHASE_2_Blueprints10MAY2026.md` to replace “mathematical certainty wallet” / “mathematical certainty” with tamper-evident / risk-reduction language consistent with [[overview]] and Rule 03.
- Adjusted `Master_Context10MAY2026.md` risks to reflect wallet-scoped ledger `SELECT` (`20260510120000_tighten_ledger_select_rls.sql`).
- Renamed `.cursor/rules/snapseal-foundation.mdc` rule description (metadata only) to tamper-evident vault wording.

## [2026-05-11] audit | Project audit + wiki refresh

- Cross-checked Flutter vault/RPC/sync/native-channel paths against `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`, `wiki/analyses/FactLockCam_Master_Blueprint.md`, `wiki/analyses/ProofLock_Refactor_Scope.md`, and `wiki/analyses/Master_Context_10MAY2026.md`.
- Added `wiki/analyses/Project_Audit_2026-05-11.md` (schema-first-class) with findings table and residual gaps.
- Updated baseline, blueprint, refactor scope, master context, `wiki/overview.md`, `wiki/index.md`, and `wiki/glossary.md` for **`proofLockFile`**, simulated **`NativeEnclaveChannel`**, **`proof_ledger`**, pending-sync **scheduler + UI retry**, **`dart_defines.json`**, and expanded tests.
- Re-ran `python3 scripts/wiki_ingest.py --validate`.

## [2026-05-11] ingest | Project audit raw source

- Added immutable `raw/project_audit_2026-05-11.md` and source summary `wiki/sources/Project_Audit_2026-05-11_Source.md`; marked `COMPILED` in `manifest.md` targeting [[Project_Audit_2026-05-11_Source]].
- Linked `wiki/analyses/Project_Audit_2026-05-11.md` provenance to the raw source; indexed the source in `wiki/index.md` and `wiki/overview.md`.
- Re-ran `python3 scripts/wiki_ingest.py --validate`.

## [2026-05-11] feature | Phase 2 dual-mode capture (photo + video)

- Added `AcquisitionMode` enum (`factlockcam_app/lib/ui/views/camera/acquisition_mode.dart`) and threaded `mode` as a `/camera?mode=...` query parameter through `app_router.dart`.
- Reworked `CameraView` to accept `AcquisitionMode`: photo retains single-tap shutter; video toggles `startVideoRecording` / `stopVideoRecording` with REC indicator and red shutter, then routes the resulting `XFile` through the existing `VaultService.sealAndStoreCapture` ProofLock pipeline.
- Replaced the single dashboard "Capture" FAB with side-by-side **Photo** and **Video** extended FABs in `VaultDashboardView`; added a play-arrow badge overlay on `video/*` grid items and a video-aware error fallback.
- Updated `VaultService._inferMimeType` to map `.mov`/`.mp4`/`.m4v`/`.webm` to their `video/*` MIME types so dashboards, video playback, and certificate drafts can branch on media kind.
- Permissions: added `NSMicrophoneUsageDescription` (`factlockcam_app/ios/Runner/Info.plist`) and `android.permission.RECORD_AUDIO` (`factlockcam_app/android/app/src/main/AndroidManifest.xml`).
- Tests: added a `vault_dashboard_view_test.dart` assertion for the Photo + Video FABs and updated `widget_test.dart` to tap "Photo" rather than the retired "Capture". `flutter analyze` and `flutter test` are green (13 tests).

## [2026-05-11] fix | Camera dispose race for video recording

- `CameraView.dispose()` previously called `controller.stopVideoRecording()` without awaiting it before `controller.dispose()`, creating a race that could leak the platform encoder (`factlockcam_app/lib/ui/views/camera/camera_view.dart`).
- Extracted a static `_teardownCamera` helper that awaits `stopVideoRecording` (when recording) before `controller.dispose()`, and explicitly `unawaited(...)` the future from synchronous `State.dispose()` to preserve the framework contract.
- `flutter analyze` and `flutter test` remain clean after the fix.

## [2026-05-11] maintenance | Master Context (11 MAY 2026) + wiki cleanup

- Added `MASTER_CONTEXT11MAY2026.md` (repo root) as the current comprehensive architecture snapshot superseding `Master_Context10MAY2026.md`.
- Added `wiki/analyses/Master_Context_11MAY2026.md` as the schema-compliant wiki twin (frontmatter, Core Synthesis, Provenance Tracking, Related Notes); indexed in `wiki/index.md` and `wiki/overview.md`.
- Marked `[[Master_Context_10MAY2026]]` as archived snapshot in `wiki/index.md`.
- Extended `wiki/glossary.md` with `AcquisitionMode`, **Dual-mode capture (Photo + Video)**, and the **Cold-build dart-defines rule** (operational lesson from the 2026-05-11 Supabase-config QA recovery: `--dart-define` values only refresh on a cold Flutter build).
- Re-ran `python3 scripts/wiki_ingest.py --validate`.

## [2026-05-11] maintenance | Four-panel vault UX wiki refresh

- Updated `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`, `wiki/analyses/FactLockCam_Master_Blueprint.md`, and `wiki/analyses/Master_Context_11MAY2026.md` for the post-login `/vault-home` hub, `/archive` Photos/Videos tabs, legacy `/vault-dashboard` redirect, and shared `/camera?mode=photo|video` capture flow.
- Documented archive behavior changes: native video-frame thumbnails, zero-byte thumbnail regeneration, owner-side full-size photo viewing (`ArchivePhotoView`), verified video playback (`ArchiveVideoView`), and per-item local delete that leaves remote proof rows intact.
- Updated `wiki/index.md`, `wiki/overview.md`, and `wiki/glossary.md` to include the four-panel UX, local archive delete, and owner-side verified viewing terminology.

## [2026-05-11] maintenance | Shutter painter wiki refresh

- Reviewed wiki health with `python3 scripts/wiki_ingest.py --status` and `python3 scripts/wiki_ingest.py --validate` before edits: 15 wiki pages, 0 pending manifest rows, 0 broken wiki links.
- Updated `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`, `wiki/analyses/FactLockCam_Master_Blueprint.md`, `wiki/analyses/Master_Context_11MAY2026.md`, and `wiki/overview.md` for the custom `ShutterButtonPainter`: transparent-at-rest center, 150 ms white photo tap-down snap, and Kinetic Green fill while video recording.
- Added `ShutterButtonPainter` to `wiki/glossary.md` and refreshed test status to `flutter analyze` + `flutter test` green (21 tests).

## [2026-05-12] maintenance | Domain Interaction Contract + wiki cleanup

- Reviewed wiki health with `python3 scripts/wiki_ingest.py --status` and `python3 scripts/wiki_ingest.py --validate`: 15 wiki pages, 0 pending manifest rows, 0 broken wiki links.
- Updated `wiki/overview.md`, `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`, `wiki/analyses/FactLockCam_Master_Blueprint.md`, `wiki/analyses/Master_Context_11MAY2026.md`, `wiki/analyses/ProofLock_Refactor_Scope.md`, and `wiki/analyses/Project_Audit_2026-05-11.md` for the media-type-driven archive action contract (`MediaActionType`, `AssetActionRegistry`, `AssetAction`, `UniversalAssetToolbar`).
- Documented recent hardening: `ArchivePhotoView` caches verified extraction per asset fingerprint, `CameraView` clears stale REC state on sealing failures, and `VaultService` uses MIME-aware temp extensions when regenerating video thumbnails from decrypted bytes.
- Added glossary entries for **Domain Interaction Contract**, **UniversalAssetToolbar**, and **MIME-aware video thumbnail fallback**; refreshed test status to `flutter analyze` + `flutter test` green (31 tests).

## [2026-05-13] analysis | Master Context (13 MAY 2026)

- Added `wiki/analyses/MASTER_CONTEXT13MAY2026.md` as the dated **current** comprehensive architecture snapshot; updated `wiki/index.md` (mark [[Master_Context_11MAY2026]] superseded), `wiki/overview.md` synthesis + provenance, and `wiki/analyses/Master_Context_11MAY2026.md` framing to reference the roll-forward.
- Cross-checked `flutter test` in `factlockcam_app/` (31 passing tests across nine test files).
- Re-ran `python3 scripts/wiki_ingest.py --validate`.
- Added repo-root `MASTER_CONTEXT13MAY2026.md` as a shortcut pointer into the wiki page.

## [2026-05-13] maintenance | FactLockCam Rename

- Renamed the Flutter runtime directory to `factlockcam_app/`, updated package imports to `package:factlockcam/`, and refreshed native identifiers to `com.factlockcam.app`.
- Renamed active product wiki anchors to [[FactLockCam_Product_Baseline_2026-05]] and [[FactLockCam_Master_Blueprint]]; updated current wiki navigation, overview, glossary, and master-context references.
- Preserved local vault persistence identifiers (`snapseal_vault.db`, `snapseal_vault`, `snapseal:vault_key`) to avoid an on-device data migration.

## [2026-05-13] feature | Heavy Metal UI Framework

- Added [[Heavy_Metal_Design_System]] to document the titanium surface palette, Inter/Space Mono typography split, Kinetic Green vs Verified Neon semantics, mechanical iris shutter motif, and heavy haptic lock interaction.
- Updated `wiki/index.md` and `wiki/glossary.md` with the new concept and terms: Titanium Deep, Verified Neon, Kinetic Green, and Shutter Iris.
- Implemented the Flutter-side design system under `factlockcam_app/lib/app/theme/`, `CameraView`, `TelemetryOverlay`, `VaultHomeView`, and `ShutterIrisPainter`.

## [2026-05-13] feature | Video-backed Heavy Metal dashboard

- Rebuilt `VaultHomeView` (`factlockcam_app/lib/ui/views/vault_home_view.dart`) as a `Stack`-based dashboard: muted, non-looping `video_player` backdrop (`assets/videos/FactLockCamBackground.mp4`) held on its first frame, a top-to-bottom titanium gradient overlay, and three hardware-styled hub tiles (Archive / Picture / Video) over a `SafeArea` content layer.
- Wired each hub tile through a single `_handleHubTap` path that fires `HapticService.lock()` (heavy impact), seeks the controller to `Duration.zero`, plays once, and an end-of-clip listener auto-pauses + resets to the first frame.
- Hardened the controller lifecycle: deferred initialization with full try/catch fallback (renders the titanium-deep solid color when the asset/codec is unavailable), `addListener` only on success, and disposal in `State.dispose`. Added `enableBackgroundVideo` + `debugControllerFactory` testing seams so widget tests never touch the platform `video_player` channel; `flutter_test_config.dart` now disables the pipeline globally for tests.
- Declared `assets/videos/` (directory) in `factlockcam_app/pubspec.yaml` and consolidated the previously duplicated `flutter:` key; added an `assets/videos/README.txt` placeholder describing the expected `FactLockCamBackground.mp4` path so the binary can be staged in later without analyzer churn.
- Tests: extended `test/vault_dashboard_view_test.dart` with a Stack-layout assertion (`CHOOSE AN ACTION` + descendant `Stack`). `dart format`, `flutter analyze`, and `flutter test` all green (36 tests).

## [2026-05-13] fix | Heavy Metal logo banner + lighter video overlay

- QA flagged that the Heavy Metal video was buried behind an opaque "wall" and that the top of the screen needed dedicated logo real estate. Two fixes:
  - Reworked `TitaniumOverlay` (`factlockcam_app/lib/core/ui/widgets/heavy_metal_backdrop.dart`) into a soft bottom-only vignette (transparent for the upper 45% of the height, fading to ~50% titanium at 85% and ~75% at the very bottom edge) so the video reads cleanly through the middle of the screen while the lower button strip still gets a legibility scrim.
  - Added a reusable `HeavyMetalLogoBanner` widget (solid `titaniumDeep` plinth, hairline `verifiedNeon` underline, soft drop shadow) with a `child` slot for `Image.asset(...)` later and an `actions` slot that renders Material chrome (popup menus, icon buttons) in the top-right without an `AppBar`. The default placeholder is a lock-mark puck + `FACTLOCKCAM` wordmark + `TAMPER-EVIDENT MEDIA VAULT` mono tagline.
- `VaultHomeView` now uses `Column(HeavyMetalLogoBanner(actions: …), Expanded(Stack(video, vignette, content)))`. The action tiles are docked to the bottom of the video region via a `Spacer`, exposing a clear band of video between the logo banner and the buttons.
- `LogonView` replaced its `CupertinoNavigationBar` with the same `HeavyMetalLogoBanner` (now serves as the brand zone for the auth screen) and pulled the redundant in-form heading. The auth form bottom-docks via `MainAxisAlignment.end`. Extracted form children into `_buildFormChildren(AuthUiState)` for readability.
- Tests: `test/vault_dashboard_view_test.dart` and `test/widget_test.dart` updated to expect `FACTLOCKCAM` (the banner wordmark) instead of the old `FactLockCam` AppBar/NavBar title. `dart format`, `flutter analyze`, and `flutter test` all green (36 tests).

## [2026-05-13] fix | Backdrop binary relocation + LogonView parity

- QA found no video behind the three hub tiles: the bundled mp4 was staged at `factlockcam_app/assets/images/FactLockCamMainDashBackground.mp4` while `VaultHomeView` was reading the canonical `assets/videos/FactLockCamBackground.mp4` path, so the controller's catch-fallback was always firing. Moved + renamed the file to `factlockcam_app/assets/videos/FactLockCamBackground.mp4` and removed the placeholder `README.txt`.
- Extracted the controller lifecycle and presentational layers into `factlockcam_app/lib/core/ui/widgets/heavy_metal_backdrop.dart`: `HeavyMetalBackdropMixin` (paused-on-first-frame init, end-of-clip auto-reset, disposal), `BackgroundVideoLayer`, `TitaniumOverlay`, and `kHeavyMetalBackdropAsset`. The mixin exposes `playBackdropFromStart()` so any screen can kick the clip from an action handler. `HeavyMetalBackdropMixin.enabled` is the global kill-switch used by `flutter_test_config.dart`.
- `VaultHomeView` now mixes in `HeavyMetalBackdropMixin`; its private `_BackgroundVideoLayer`/`_TitaniumOverlay`/`enableBackgroundVideo`/`debugControllerFactory` were retired in favor of the shared widgets and mixin statics.
- `LogonView` (`factlockcam_app/lib/ui/views/logon_view.dart`) is now the same `Stack`-backed screen: muted backdrop + titanium overlay underneath a transparent `CupertinoPageScaffold`. Headings and labels switched to monospaced uppercase (`TAMPER-EVIDENT MEDIA VAULT`, `SEND MAGIC NUMBER`, `VERIFY MAGIC NUMBER`), `CupertinoTextField` decorated with a titanium-panel fill + verifiedNeon stroke for legibility on video, and both `_sendOtp` / `_verifyOtp` now call `playBackdropFromStart()` immediately after the tap haptic.
- Tests: `test/widget_test.dart` updated to the uppercase Cupertino labels. `dart format`, `flutter analyze`, and `flutter test` all green (36 tests).
