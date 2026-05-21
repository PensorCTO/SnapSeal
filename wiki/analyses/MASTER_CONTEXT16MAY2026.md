---
tags: [analysis, architecture, factlockcam, prooflock, system_context, test_audit, codebase_audit]
summary: "Comprehensive architecture snapshot for 2026-05-16: audit-verified health (36/36 tests passing, 1 info-level analysis finding, 18 wiki pages validated), web courier infrastructure, web platform architecture, Heavy Metal design system, and status of the Cloud E2EE Vault pivot announced on 2026-05-13."
---

# Master Context (16 MAY 2026)

## Core Synthesis

This page is the **current** comprehensive architecture snapshot for FactLockCam as of **2026-05-16**. It supersedes [[MASTER_CONTEXT13MAY2026]] for timeline currency. For product workflow and hosted Supabase repair narrative, continue to anchor on [[FactLockCam_Product_Baseline_2026-05]]; for finish-line vs ProofLock manifest, see [[ProofLock_Refactor_Scope]]; for repo-vs-wiki reconciliation, see [[Project_Audit_2026-05-11]]; for the layered engineering blueprint, see [[FactLockCam_Blueprints_14May2026]].

### Audit-Verified Codebase Health

On 2026-05-16, a comprehensive project audit was performed with these verified results:

| Check | Result |
|-------|--------|
| `flutter test` | **36/36 PASS** — 11 test files, zero failures, zero errors |
| `dart analyze lib/` | **1 info** — `dart:html` deprecation in `cipher_engine_web.dart:8`; no errors/warnings |
| `dart format --output=none` | **5 of 79 files** need formatting |
| `flutter pub get` | **Pass** — 31 newer versions incompatible with constraints |
| Codebase | 68 Dart source files (6,987 lines), 11 test files (1,184 lines) |
| Supabase migrations | 10 files spanning 2026-04-28 through 2026-05-17 |
| Wiki pages | 18 pages, all pass `scripts/wiki_ingest.py --validate` |
| Glossary | 52 defined terms |
| `.cursor/rules/*.mdc` | 15 rule files (9 always-apply) |
| CI | Supabase validate/deploy only (no Flutter test CI) |

### What Changed Since 13MAY2026

The following changes have landed since the [[MASTER_CONTEXT13MAY2026]] snapshot:

**New Supabase Courier Surface (May 14-15):** Four new migrations deliver the end-to-end courier package infrastructure:
- `20260514220000_web_courier_schema.sql` — `courier_packages` table (RLS, no direct SELECT), `attempt_courier_unlock` RPC (SECURITY DEFINER, 5-max retries, auto-burn + storage cleanup), `check_courier_attempts` RPC (public-anon)
- `20260515000000_web_courier_indices.sql` — Performance indexes for courier lookup
- `20260515032134_get_or_create_courier_package.sql` — Mobile courier origination RPC (owner-scoped, idempotent)
- `20260516000000_ensure_courier_blobs_storage_bucket.sql` — `courier-blobs` Supabase Storage bucket (50 MB limit)
- `20260517000000_repair_courier_storage_object_rls.sql` — Storage path-scoped RLS policies for courier uploads (fixes 403 errors)

**Web Platform Architecture (May 14-15):** Platform-conditional implementations for Flutter web target:
- `cipher_engine_web.dart` (AES-GCM via Web Crypto; currently uses deprecated `dart:html` — see audit finding)
- `vault_service_web.dart`, `local_vault_storage_web.dart`, `vault_database_web.dart`
- `courier_unlock_view.dart` — Flutter web UI for courier unlock (reads `?pkg=` query param)
- `courier_link_provider.dart` + generated `.g.dart` — Riverpod AsyncNotifier
- `archive_thumbnail_web.dart`, `archive_video_source_web.dart`
- `index.html`, `manifest.json`, PWA icon assets
- New `.cursor/rules/web-architecture.mdc` (platform conditionals, GoRouter deep linking, crypto parity, local Supabase port `127.0.0.1:54325`)

**Heavy Metal Design System (May 13-14):**
- `ShutterIrisPainter` (six-blade mechanical iris motif, `RepaintBoundary`-wrapped) supersedes `ShutterButtonPainter` (marked DEPRECATED in glossary)
- `HeavyMetalBackdropMixin` for background video/graphics layers
- `app_colors.dart`: Titanium Deep (#121212), Titanium Panel (#1C1C1C), Stark White (#FFFFFF), Kinetic Green (#00D26A), Verified Neon (#39FF14)
- `app_typography.dart`: `GoogleFonts.spaceMono` for HUD/hashes/telemetry; Inter for body
- `Heavy_Metal_Design_System` concept page in wiki
- `FactLockCamBackground.mp4` video asset

**Ephemeral QA Environment Tooling (May 14-15):**
- `scripts/start_qa_env.sh` — one-command QA: Flutter Web on :3000, Ngrok HTTPS tunnel, iOS Simulator build with `WEB_VAULT_BASE_URL`
- `WEB_VAULT_BASE_URL` compile-time define support in `write_flutter_dart_defines.py`
- `.cursor/rules/ephemeral-environments.mdc` — tunnel awareness, no production domain assumptions

**Wiki Expansion (May 14-15):**
- [[FactLockCam_Blueprints_14May2026]] added — layered technical blueprint with Mermaid diagram (engineering onboarding focus)
- [[overview]] populated with reading order and dual-workspace summary
- [[log]] initialized with May 14-15 activity entries
- Glossary expanded from ~30 to **52 terms** (added AES-GCM, C2PA, PolygonChainNotarizer, ProofLockConflictException, proof_ledger, REQUIRE_HARDWARE_ATTESTATION, RLS, RPC, SealLedgerRepository, SHA-256, SimulatedChainNotarizer)
- `ShutterButtonPainter` marked as **DEPRECATED** in glossary

**Corrupted File Remediation (May 15):**
- `vault_service_io.dart` had become corrupted (trailing newline in filename on prior recreation caused the file to contain SQL migration content rather than Dart code). The corrupted file was deleted; the legitimate 856-line implementation was confirmed intact. No recurrence.

**No new runtime features landed** since 13MAY2026 — all changes are infrastructure, wiki, web platform foundations, and courier backend schema.

### Codebase Health — Audit Findings

| Finding | Location | Severity | Notes |
|---------|----------|----------|-------|
| `dart:html` deprecation | `cipher_engine_web.dart:8` | Info | Migrate to `package:web` + `dart:js_interop` |
| Unformatted files | 5 files under `lib/` | Style | `dart format` needed on `app_config.dart`, `cipher_engine_web.dart`, `debug_agent_ndjson_io.dart`, `seal_ledger_repository.dart`, `dashboard_controller.dart` |
| TODO: verified view payload | `asset_action_provider.dart:24` | Low | Archive navigation integration |
| TODO: courier export wiring | `asset_action_provider.dart:41` | Medium | Sealed-share/courier export not wired |
| TODO: certificate export wiring | `asset_action_provider.dart:45` | Medium | PDF/certificate export not wired |
| Native signing TODOs | `AppDelegate.swift:26`, `MainActivity.kt:22` | **High** | Replace simulated `signHash` with Secure Enclave / Keystore |
| PolygonChainNotarizer stub | `chain_notarizer.dart` | **High** | `PolygonChainNotarizer` throws `UnsupportedError` |
| Unwired REQUIRE_HARDWARE_ATTESTATION | `app_config.dart` | Medium | Defined as compile-time flag; not referenced in capture/sync gates |
| No Flutter test CI | `.github/workflows/supabase.yml` | Medium | CI validates Supabase migrations only; Flutter tests are manual |
| 31 packages held back | `pubspec.yaml` | Low | Newer versions incompatible with current constraints |

### Product Surface (Authenticated Shell)

| Area | Behavior (unchanged from May 13) |
| :--- | :--- |
| **Routes** | GoRouter: `/logon`, `/vault-home`, `/archive`, `/courier?pkg=...` (new). Legacy `/vault-dashboard` → `/vault-home`. Sign-out burns local wallet before remote sign-out. **Camera route `/camera` removed** — `CameraView` is now embedded via `IndexedStack` tabs in `VaultHomeView`. |
| **Hub** | `VaultHomeView`: `IndexedStack` with hub index 0 = `HapticHubPanel` (four tiles). Indices 1–2 = **lazy-mounted** photo/video `CameraView` (`_cameraPanel()` — active panel only); 3 = `UnifiedArchiveViewport`; 4 = `AccountSettingsPanel`. No bottom nav — panel back buttons return to hub. Post-capture → index 0. Physical iOS QA requires lazy mount ([[Polygon_Try1_Postmortem]]). See [[iOS_Device_Development_Workflow]] for `flutter run` attach caveats. |
| **Archive** | Split **Photos** / **Videos** tabs; thumbnails from disk; pending-sync badges; banner with **Retry now**; registry-driven actions; per-item **local** delete; full-size photo (`ArchivePhotoView`) and verified video playback (`ArchiveVideoView`) via `extractForCourier`. |
| **Capture** | Shared `CameraView` with `AcquisitionMode` (photo/video). `ShutterIrisPainter` replaces `ShutterButtonPainter`. Forensic overlay stack: `ReticlePainter`, `TelemetryOverlay`, `CameraChromeFrame`. |
| **Web courier** | `CourierUnlockView` at `/courier?pkg=...` — new, guest-accessible. Backend RPCs complete; end-to-end UI flow not yet wired. |

### Seal and Sync Runtime (Unchanged Pipeline Ordering)

1. Capture → `Isolate.run` read + SHA-256 fingerprint.
2. When online/configured: `check_proof_status`; conflict → `ProofLockConflictException`.
3. `NativeEnclaveChannel.signHash` → **simulated** payloads.
4. `ChainNotarizer` → default `SimulatedChainNotarizer` → `simulate_chain_notarize`; `PolygonChainNotarizer` still a stub.
5. AES-GCM encrypt, thumbnail, SQLite upsert.
6. `proof_ledger` insert on happy remote path; else `pending_sync` with backoff.
7. `PendingSyncScheduler` (~3 min) + hub/archive `syncPendingInBackground` + UI **Retry now**.

### Architecture Pivot (2026-05-13) — Implementation Status

The **Cloud E2EE Vault & Web Verification** paradigm shift remains **announced but not fully implemented**:

- **Cloud E2EE Vault**: Web platform variants (`*_web.dart` files) lay conditional-import groundwork. The encrypted-blob upload/download to Supabase Storage, zero-knowledge key management, and quota telemetry UI are not built.
- **Web Courier Portal**: `courier_unlock_view.dart` exists as a Flutter web UI; the Supabase courier RPC schema (`courier_packages`, `attempt_courier_unlock`, `check_courier_attempts`, storage bucket) is complete. The end-to-end flow (mobile upload → recipient link → web decrypt → Polygonscan verification) is not wired.
- **Subscription Tiers**: Free ($0/50 MB), Picture ($1/5 GB), Video ($10/50 GB) tiers are defined in the 13MAY pivot document. No pricing enforcement, quota metering, payment integration, or egress limits exist in app or backend.

The web courier migration stack is the necessary prerequisite — now in place.

### Gap Summary (Unchanged Relative to ProofLock Target)

1. **Trust root**: Hardware-backed signing (Secure Enclave / Keystore) remains **simulated**.
2. **Durable proof**: `PolygonChainNotarizer` throws `UnsupportedError`; no chain anchoring.
3. **C2PA**: Not present in any form.
4. **Pending-sync UX**: Basic scheduler + retry banner exist; diagnostics are thin.
5. **Verification surfaces**: No outsider-facing proof lookup or courier `.plock` UX beyond nascent web UI.
6. **Test depth**: 36 tests is improved but remains thin on crypto/capture/sync failure modes.
7. **Cloud E2EE vault**: Full pivot (blob upload, quota, tiers) unimplemented.

### Suggested Sequencing (Architecture-Forward)

1. Replace simulated `NativeEnclaveChannel.signHash` with Secure Enclave / Keystore; wire `REQUIRE_HARDWARE_ATTESTATION` into capture gating.
2. Implement `PolygonChainNotarizer` (or equivalent durable chain adapter); persist real `chain_tx_hash`.
3. Wire end-to-end web courier flow: mobile upload → encrypted blob → courier link → web unlock → Polygonscan verification.
4. Expand pending-sync UX with richer diagnostics and offline awareness.
5. Implement Cloud E2EE vault: encrypted blob upload/download, quota telemetry, subscription enforcement.
6. Track C2PA as parallel advanced provenance track.
7. Expand deterministic tests for `proofLockFile` conflict paths, web courier flow, and crypto edge cases.

## Provenance Tracking

- *Wiki synthesis anchors*: Consolidated from `wiki/index.md`, `wiki/overview.md`, [[FactLockCam_Product_Baseline_2026-05]], [[FactLockCam_Master_Blueprint]], [[FactLockCam_Blueprints_14May2026]], [[ProofLock_Refactor_Scope]], [[Project_Audit_2026-05-11]], and [[MASTER_CONTEXT13MAY2026]] (2026-05-16).
- *Repo root shortcut*: `MASTER_CONTEXT16MAY2026.md` at repository root links here (mirroring the 13MAY companion pattern).
- *Prior snapshot*: Supersedes [[MASTER_CONTEXT13MAY2026]] as the dated master context sibling; [[Master_Context_11MAY2026]] and [[Master_Context_10MAY2026]] remain historical.
- *Verification on 2026-05-16*: `flutter test` in `factlockcam_app/` (36/36 passing); `dart analyze lib/` (1 info); `dart format --output=none` (5/79 unformatted); `scripts/wiki_ingest.py --validate` (18/18 pages); Supabase migration count (10).

## Related Notes

- [[FactLockCam_Blueprints_14May2026]] — Layered technical blueprint (2026-05-14)
- [[FactLockCam_Product_Baseline_2026-05]]
- [[FactLockCam_Master_Blueprint]]
- [[Project_Audit_2026-05-11]]
- [[ProofLock_Refactor_Scope]]
- [[ProofLock_Architectural_Manifest]]
- [[MASTER_CONTEXT13MAY2026]] (superseded)
- [[Master_Context_11MAY2026]] (archived)
- [[Master_Context_10MAY2026]] (archived)
- [[Heavy_Metal_Design_System]]
- [[overview]]
- [[log]]
- [[glossary]]
