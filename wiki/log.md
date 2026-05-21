---
tags: [maintenance, log, llm_wiki]
summary: "Append-only chronology of wiki maintenance and major documentation events."
---

# Wiki log

## 2026-05-21

- **App Store prep + fifth QA pass** (committed to `main`):
  - **Code:** Bundled legal docs + `LegalDocumentView`; multi-shot capture (`sealAndStoreCapture` buffered bytes, `_enqueueCaptureSeal`); GPS/UTC HUD; archive delete/view/thumbnail fixes; sidecar-lock staging promote (fixes 0-byte `.seal`); caller-isolate vault I/O; proof bundle zip share; `cipher_engine_roundtrip_test`, `locked_rename_test`.
  - **QA:** User-confirmed pass on physical device (rapid photos, thumbnails, view/decrypt, delete).
  - **Wiki:** Added [[App_Store_Prep_Capture_Seal_2026-05]]; refreshed [[FactLockCam_Product_Baseline_2026-05]], [[Vault_Transactional_Journal]], [[Isolate_Lock_Coordinator]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Sprint 4 reactive UI locks + fourth QA pass** (committed to `main`):
  - **Code:** `IsolateLockCoordinator`, advisory file locks, `AssetSecuringOverlay` on chronology/grid, `PrivacyInfo.xcprivacy`, `docs/app_store_submission_checklist.md`, `integration_test` stub.
  - **QA:** User-confirmed pass on physical device.
  - **Wiki:** Refined [[Isolate_Lock_Coordinator]]; cross-links in [[Vault_Transactional_Journal]], [[FactLockCam_Product_Baseline_2026-05]], [[overview]], [[glossary]], [[index]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Sprint 2 vault integrity + third device QA** on `cursor/wiki-supabase-local-reset-audit`:
  - **Code:** WAL journal (`factlockcam_journal.db`), `TransactionalVaultPersister`, boot recovery before `runApp`, sqflite single-flight + eager open, hub lazy archive/account panels, unique `VaultPanelNavigationBar` hero tags, landscape 2×2 hub grid, dart-defines sync → `GeneratedDartDefines` (gitignored generated file).
  - **QA:** User-confirmed physical iPhone capture + Polygon ledger insert after SQLite race fix; hub RenderFlex overflow fixed.
  - **Wiki:** Added [[Vault_Transactional_Journal]]; refreshed [[FactLockCam_Product_Baseline_2026-05]], [[FactLockCam_Master_Blueprint]], [[Polygon_Saga_Live]], [[index]], [[overview]], [[glossary]].
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

## 2026-05-20

- **Polygon proof UX + certificate tx hash** (user-confirmed QA pass) on branch `cursor/wiki-supabase-local-reset-audit`:
  - **Code:** Await `anchor-relay` during capture (fixes missing post-capture progress); persist `chain_tx_hash` in SQLite v5; `CertificateExportService` includes ledger tx hash; monitor seeds initial `ProofState`; vault badges use **Generating Proof…** copy.
  - **Tests:** `vault_service_retry_test.dart` updated for `markSyncSucceeded(chainTxHash:)`; 33/33 pass.
  - **Wiki:** Refreshed [[Polygon_Saga_Live]] (await-relay sequence, QA table); [[FactLockCam_Product_Baseline_2026-05]], [[FactLockCam_Master_Blueprint]], [[overview]], [[glossary]], [[index]] aligned.
  - Validation: `python3 scripts/wiki_ingest.py --validate`.

- **Final QA pass + wiki cleanup** on branch `cursor/wiki-supabase-local-reset-audit`:
  - User-confirmed QA pass; `flutter test` **33/33**; analyzer warnings cleared in vault UI (`Matrix4.translateByDouble`, unused catch params) and web crypto lint.
  - **App icon** committed: `FactLockCamAppIcon.png` + `flutter_launcher_icons` for iOS/Android/web (commit `b476f37`).
  - **Wiki optimized:** [[index]] reorganized — active analyses vs archived snapshots; [[FactLockCam_Product_Baseline_2026-05]] updated with branding + final QA status; [[FactLockCam_Master_Blueprint]] test count corrected (33); [[Polygon_Saga_Live]] QA date aligned; [[glossary]] adds `flutter_launcher_icons`, app icon, fixes `SimulatedChainNotarizer` vs live Polygon saga; [[overview]] points to baseline first.
  - Validation: `python3 scripts/wiki_ingest.py --validate` — 22/22 pages OK.

## 2026-05-21

- **Polygon Try 2 live + QA pass** on physical iPhone (~2s proof finalization):
  - Landed PR1–PR5: `WalletService`, `VaultBlockchainHandler`, async `VaultService` saga, `anchor-relay` Edge Function, migrations (`notarization_status`, `evm_address`, finalize RPCs), Realtime monitor, `ProofSyncNotifier` local pending clear.
  - Fixed indefinite pending UI: relay HTTP 200 did not call `markSyncSucceeded` until `ProofSyncNotifier` + `_finalizeLocalPolygonSync`.
  - Hosted deploy: `supabase db push`, `supabase functions deploy anchor-relay`; `USE_POLYGON_NOTARIZER` default **true** in dart-defines sync.
  - Added [[Polygon_Saga_Live]]; updated [[Polygon_Try1_Postmortem]], [[FactLockCam_Product_Baseline_2026-05]], [[glossary]], [[index]], [[overview]], [[ProofLock_Refactor_Scope]] (partial).

## 2026-05-20

- **Polygon Try 1 postmortem audit** after May 19 rollback:
  - Added repo-root [`POSTMORTEM_POLYGON_TRY1.md`](../POSTMORTEM_POLYGON_TRY1.md) and wiki [[Polygon_Try1_Postmortem]].
  - Automated bisect on stash snapshot `c87ac99`: Polygon DI alone passes 33/33 tests; UI-only changes fail `widget_test` back-button finder; full WIP builds/installs on device and sim.
  - Updated root-cause ranking: process failure + device-specific runtime (dual IndexedStack cameras + UI bisect) — Polygon DI rejected as startup cause.
  - Documented Try 2 PR sequence (PR0 lazy camera → PR1–PR5 Polygon path).
  - Forensic branch: `audit/polygon-try1-bisect` (worktree `ProofLockCleanup-audit`).
- **Integrity restoration + wiki refinement** after post-audit device regression:
  - Root cause of post-audit "broken app": audit worktree installed WIP binary on iPhoneTanto; main repo source was docs-only.
  - **PR0 landed:** `VaultHomeView._cameraPanel()` lazy-mounts `CameraView` only when Picture/Video panel active — fixes physical-device blank screen from eager dual-camera init.
  - **QA re-verified:** `flutter test` 33/33 (10 files); iPhoneTanto manual launch passes full hub workflow (user-confirmed).
  - Refined [[Polygon_Try1_Postmortem]], [[iOS_Device_Development_Workflow]], [[FactLockCam_Master_Blueprint]], [[FactLockCam_Product_Baseline_2026-05]], [[glossary]], [[overview]], repo-root postmortem Resolution section; Try 2 entry point → PR1.

## 2026-05-19

- **Device QA + wiki reconciliation** after hub refactor commit `19269d2`:
  - Added [[iOS_Device_Development_Workflow]]: physical iOS 26 + Flutter 3.38 `flutter run` VM Service attach failures vs successful build/install/manual launch; recommended `flutter attach` and Xcode paths.
  - Updated [[FactLockCam_Master_Blueprint]], [[MASTER_CONTEXT16MAY2026]], [[FactLockCam_Product_Baseline_2026-05]], [[glossary]], [[index]], [[overview]] to replace stale **ProfessionalNavBar** / bottom-tab / standalone `/archive` descriptions with **hub-first** `HapticHubPanel` + five `IndexedStack` panels (hub, photo, video, archive omni, account).
  - Documented May 2026 rollback: uncommitted debug/Polygon WIP stashed. VM attach failures are tooling-layer; blank device screen was addressed by PR0 lazy camera mount (see [[Polygon_Try1_Postmortem]]).

## 2026-05-17

- Performed comprehensive LLM Wiki review and cleanup: updated stale references across 7 wiki pages for accuracy with the current codebase state.
  - Fixed broken wiki links (`CourierRepository`, `VaultPathResolver` glossary terms).
  - **[[FactLockCam_Master_Blueprint]]**: Updated test count 31→36, replaced `ShutterButtonPainter`→`ShutterIrisPainter`, corrected standalone `/camera` route → tab-embedded `IndexedStack`/`ProfessionalNavBar` hub model.
  - **[[FactLockCam_Blueprints_14May2026]]**: Updated companion reference from [[MASTER_CONTEXT13MAY2026]]→[[MASTER_CONTEXT16MAY2026]], removed standalone `/camera` route from routing table, test count 31→36.
  - **[[FactLockCam_Product_Baseline_2026-05]]**: Replaced `ShutterButtonPainter`→`ShutterIrisPainter`, updated camera routing description for tab-embedded model.
  - **[[overview]]**: Updated Related Notes to reference [[MASTER_CONTEXT16MAY2026]] instead of 13MAY.
  - **[[index]]**: Updated Blueprints and Master Blueprint descriptions for current architecture.
  - **[[Heavy_Metal_Design_System]]**: Added [[MASTER_CONTEXT16MAY2026]] to Related Notes.
  - **[[glossary]]**: Updated `AcquisitionMode` entry (no standalone `/camera` route).
- Cleaned up stale `snapseal` tag on [[Project_Audit_2026-05-11]] analysis page.

- Implemented **Courier Retrofit** (per Diagnostic Integrity Report "Send Proof" Courier Failure blueprint):
  - Decoupled state and UI: `CourierLink` notifier returns `Future<String>` (not void); `SharePlus` side-effect moved to `ArchiveItemActions.showSendProofDialog` in the UI layer.
  - Fixed iOS path drift: created `VaultPathResolver` DI service; injected into `VaultService`; all four `_storage.resolveArchivePaths` call sites replaced with `_pathResolver.resolve`.
  - Removed `.plock` reference from `courier_crypto.dart` doc comment; confirmed no XOR/PLOCK_VERIFIED_V1 exists in codebase (AES-GCM unified end-to-end).
  - Encapsulated web data layer: created `CourierRepository` wrapping `SupabaseClientHandle` with typed `checkCourierAttempts`, `attemptUnlock`, `downloadBlob` methods; injected into `CourierUnlockNotifier`, replacing direct `Supabase.instance.client` access.
  - Wired Send Proof stubs: replaced SnackBar TODOs in `AssetInspectorScreen._onSendProof` and `ChronologyViewport._onSwipeShare` with full `showSendProofDialog` flow.
- Added glossary terms: `CourierRepository`, `VaultPathResolver`.
- Updated [[FactLockCam_Blueprints_14May2026]] with courier retrofit details and corrected suggested read order.
- Updated [[MASTER_CONTEXT16MAY2026]] audit findings to reflect wired courier export.
- Updated [[FactLockCam_Master_Blueprint]] courier/package export and "Prepare A Courier Payload" section.
- Updated [[overview]] to reference [[MASTER_CONTEXT16MAY2026]] instead of 13MAY.

## 2026-05-14

- Added [[FactLockCam_Blueprints_14May2026]] under `wiki/analyses/`: layered technical architecture blueprint (companion to [[MASTER_CONTEXT13MAY2026]]); mirrors repo root `FactLockCam_Blueprints14May2026.md`.
- Updated [[index]] Analyses section with navigation link to the new page.
- Populated [[overview]] and initialized this [[log]] (files were previously empty).

## 2026-05-15

- Performed comprehensive project-state audit covering Flutter codebase (49 Dart files, P0 corrupted file), Supabase migrations (10 files, 2 destructive repairs), test coverage (11 files, gaps), wiki health (18 pages, all pass validation), and unresolved risks (10 items).
- Deleted corrupted `vault_service_io.dart` file (trailing newline in filename, contained SQL migration content rather than Dart).
- Added 11 missing terms to [[glossary]]: AES-GCM, C2PA, PolygonChainNotarizer, ProofLockConflictException, proof_ledger, REQUIRE_HARDWARE_ATTESTATION, RLS, RPC, SealLedgerRepository, SHA-256, SimulatedChainNotarizer.
- Marked `ShutterButtonPainter` as DEPRECATED in [[glossary]] (superseded by ShutterIrisPainter).
- Added `deepseek-cursor-proxy/` to `.gitignore`.

## 2026-05-16

- Performed comprehensive project audit: `flutter test` (36/36 passing, all 11 test files), `dart analyze lib/` (1 info: `dart:html` deprecation), `dart format --output=none` (5 of 79 unformatted), wiki validation (18/18 pages pass).
- Created [[MASTER_CONTEXT16MAY2026]] at repo root, superseding [[MASTER_CONTEXT13MAY2026]].
- Created `wiki/analyses/MASTER_CONTEXT16MAY2026.md` as wiki twin.
- Updated [[index]] to mark 13MAY as superseded and 16MAY as current snapshot.
- Implemented `ProfessionalNavBar` bottom navigation: custom forensic-styled tab bar (Home/Picture/Video/More) with VerifiedNeon accent, monospaced uppercase labels, and 2px selected-tab indicator.
- Rewrote `VaultHomeView` as `ConsumerStatefulWidget` shell using `IndexedStack` to preserve tab state; camera views (photo/video) embedded directly instead of standalone GoRouter route.
- Removed standalone `/camera?mode=` route from `app_router.dart`; camera is now tab-embedded.
- Fixed post-capture flow: `CameraView.onCaptureComplete` callback switches back to Home tab after sealing completes (eliminates the "stranded" post-capture state).
- Fixed video capture "Sealing..." hang: added `setState(() { _isSealing = false; })` on success path in `_sealCapturedFile` — the `IndexedStack` keeps `CameraView` alive, so the stale flag made the sealing overlay persist.
- Moved burn wallet and sign-out actions off the `ChronologyViewport` header; `HeavyMetalLogoBanner` used without actions parameter.
- Cleaned up unused imports in chronology_viewport.dart (auth_controller, logon_view, acquisition_mode, camera_view).
- Restored Picture/Video empty-state action tiles with `onCaptureRequested` callback that switches parent tab index.
- Updated widget tests: 2/2 pass, covering logon shell rendering and tab-switch navigation flows.
- Updated [[MASTER_CONTEXT16MAY2026]] routing and hub sections to reflect new tab-shell architecture.
