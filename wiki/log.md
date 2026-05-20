---
tags: [maintenance, log, llm_wiki]
summary: "Append-only chronology of wiki maintenance and major documentation events."
---

# Wiki log

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
