---
tags: [maintenance, log, llm_wiki]
summary: "Append-only chronology of wiki maintenance and major documentation events."
---

# Wiki log

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
