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

## [2026-04-30] analysis | SnapSeal Master Blueprint

- Created `wiki/analyses/SnapSeal_Master_Blueprint.md`.
- Documented finished capabilities, unfinished work, working functional use cases, and current risks for the SnapSeal app.
- Updated `wiki/index.md`, `wiki/overview.md`, and `wiki/glossary.md` to include the SnapSeal blueprint.

## [2026-05-03] ingest | ProofLock Architectural Manifest

- Added immutable source `raw/prooflock_architectural_manifest.md`.
- Created `wiki/sources/ProofLock_Architectural_Manifest.md`.
- Created `wiki/analyses/ProofLock_Refactor_Scope.md` (manifest ↔ codebase gap analysis and phased effort).
- Updated `wiki/analyses/SnapSeal_Master_Blueprint.md` for email OTP auth and ProofLock target alignment.
- Updated `wiki/index.md`, `wiki/overview.md`, `wiki/glossary.md`, and aligned Cursor rules for capture paths and foundation constraints.
- Marked manifest row `COMPILED` in `manifest.md`.

## [2026-05-09] analysis | System Context Audit

- Created `wiki/analyses/System_Context_Audit_2026-05-09.md`.
- Audited git status, wiki health, Flutter implementation surfaces, Supabase migrations, and pipeline scripts.
- Re-validated wiki with `python3 scripts/wiki_ingest.py --validate` and app smoke tests with `flutter test`.
- Updated `wiki/index.md` to include the new comprehensive context baseline page.

## [2026-05-09] maintenance | Product baseline and wiki consolidation

- Added `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md` as the canonical SnapSeal status entry (verified workflow, compressed DB repair/backfill narrative).
- Replaced `wiki/analyses/System_Context_Audit_2026-05-09.md` body with a short archived stub pointing to the baseline.
- Updated `wiki/analyses/SnapSeal_Master_Blueprint.md`, `wiki/overview.md`, `wiki/index.md`, and `wiki/glossary.md` to link the baseline and trim duplicated audit prominence.
- Re-ran `python3 scripts/wiki_ingest.py --validate`.

## [2026-05-10] analysis | Master context architecture snapshot

- Added `wiki/analyses/Master_Context_10MAY2026.md` as a schema-compliant first-class wiki artifact (frontmatter, core synthesis, provenance, related notes).
- Indexed the new analysis in `wiki/index.md` under Analyses.
- Captured a comprehensive current-state architecture snapshot spanning Flutter runtime, local vault/data model, Supabase operations/migrations, and ProofLock gap framing.

## [2026-05-10] maintenance | Phase 2 vault-first dashboard route

- Replaced `/dashboard` with `/vault-dashboard` via `VaultDashboardView` (`snapseal_app/lib/ui/views/vault_dashboard_view.dart`).
- Added background pending-sync attempts (`VaultDatabase.listPendingArchiveItems`, `VaultService.retryPendingRemoteSync`, `DashboardController` fire-and-forget refresh).
- Updated `wiki/analyses/SnapSeal_Master_Blueprint.md`, `wiki/analyses/Master_Context_10MAY2026.md`, and `snapseal_app/README.md`; ran `flutter test` / `dart analyze`.

## [2026-05-10] maintenance | Tamper-evident wording + ledger RLS (wiki)

- Aligned SnapSeal product framing with Rule 03 / app copy: **tamper-evident** media vault and risk-reduction language (not “mathematical certainty wallet”).
- Updated `wiki/overview.md`, `wiki/glossary.md`, and `wiki/analyses/SnapSeal_Master_Blueprint.md` (including ledger `SELECT` now wallet-scoped per `20260510120000_tighten_ledger_select_rls.sql`).
- Re-ran `python3 scripts/wiki_ingest.py --validate`.

## [2026-05-10] maintenance | Repo root snapshots: tamper-evident wording

- Updated `Master_Context10MAY2026.md` and `PHASE_2_Blueprints10MAY2026.md` to replace “mathematical certainty wallet” / “mathematical certainty” with tamper-evident / risk-reduction language consistent with [[overview]] and Rule 03.
- Adjusted `Master_Context10MAY2026.md` risks to reflect wallet-scoped ledger `SELECT` (`20260510120000_tighten_ledger_select_rls.sql`).
- Renamed `.cursor/rules/snapseal-foundation.mdc` rule description (metadata only) to tamper-evident vault wording.

## [2026-05-11] audit | Project audit + wiki refresh

- Cross-checked Flutter vault/RPC/sync/native-channel paths against `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md`, `wiki/analyses/SnapSeal_Master_Blueprint.md`, `wiki/analyses/ProofLock_Refactor_Scope.md`, and `wiki/analyses/Master_Context_10MAY2026.md`.
- Added `wiki/analyses/Project_Audit_2026-05-11.md` (schema-first-class) with findings table and residual gaps.
- Updated baseline, blueprint, refactor scope, master context, `wiki/overview.md`, `wiki/index.md`, and `wiki/glossary.md` for **`proofLockFile`**, simulated **`NativeEnclaveChannel`**, **`proof_ledger`**, pending-sync **scheduler + UI retry**, **`dart_defines.json`**, and expanded tests.
- Re-ran `python3 scripts/wiki_ingest.py --validate`.

## [2026-05-11] ingest | Project audit raw source

- Added immutable `raw/project_audit_2026-05-11.md` and source summary `wiki/sources/Project_Audit_2026-05-11_Source.md`; marked `COMPILED` in `manifest.md` targeting [[Project_Audit_2026-05-11_Source]].
- Linked `wiki/analyses/Project_Audit_2026-05-11.md` provenance to the raw source; indexed the source in `wiki/index.md` and `wiki/overview.md`.
- Re-ran `python3 scripts/wiki_ingest.py --validate`.

## [2026-05-11] feature | Phase 2 dual-mode capture (photo + video)

- Added `AcquisitionMode` enum (`snapseal_app/lib/ui/views/camera/acquisition_mode.dart`) and threaded `mode` as a `/camera?mode=...` query parameter through `app_router.dart`.
- Reworked `CameraView` to accept `AcquisitionMode`: photo retains single-tap shutter; video toggles `startVideoRecording` / `stopVideoRecording` with REC indicator and red shutter, then routes the resulting `XFile` through the existing `VaultService.sealAndStoreCapture` ProofLock pipeline.
- Replaced the single dashboard "Capture" FAB with side-by-side **Photo** and **Video** extended FABs in `VaultDashboardView`; added a play-arrow badge overlay on `video/*` grid items and a video-aware error fallback.
- Updated `VaultService._inferMimeType` to map `.mov`/`.mp4`/`.m4v`/`.webm` to their `video/*` MIME types so dashboards, video playback, and certificate drafts can branch on media kind.
- Permissions: added `NSMicrophoneUsageDescription` (`snapseal_app/ios/Runner/Info.plist`) and `android.permission.RECORD_AUDIO` (`snapseal_app/android/app/src/main/AndroidManifest.xml`).
- Tests: added a `vault_dashboard_view_test.dart` assertion for the Photo + Video FABs and updated `widget_test.dart` to tap "Photo" rather than the retired "Capture". `flutter analyze` and `flutter test` are green (13 tests).
