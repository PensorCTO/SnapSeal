# Master Context — 16 MAY 2026

The comprehensive architecture snapshot lives in the LLM Wiki:

**[`wiki/analyses/MASTER_CONTEXT16MAY2026.md`](wiki/analyses/MASTER_CONTEXT16MAY2026.md)**

That page supersedes `wiki/analyses/MASTER_CONTEXT13MAY2026.md` for timeline currency; for product workflow and hosted Supabase repair narrative, continue to anchor on `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`; for the repo-vs-wiki reconciliation audit, see `wiki/analyses/Project_Audit_2026-05-11.md`; for the layered engineering blueprint, see `wiki/analyses/FactLockCam_Blueprints_14May2026.md` and `FactLockCam_Blueprints14May2026.md` at repo root.

---

## 2026-05-16 Audit Snapshot: Verified Health

| Check | Result | Detail |
|-------|--------|--------|
| **`flutter test`** | **36/36 PASS** | 11 test files, zero failures, zero errors. Up from 31 passing on May 13 (+5 new tests). |
| **`dart analyze lib/`** | **1 info** | Only `dart:html` deprecation in `cipher_engine_web.dart:8` — no errors, no warnings. |
| **`dart format`** | **5/79 need formatting** | `app_config.dart`, `cipher_engine_web.dart`, `debug_agent_ndjson_io.dart`, `seal_ledger_repository.dart`, `dashboard_controller.dart`. |
| **Codebase** | **6,987 lines** | 68 Dart source files under `factlockcam_app/lib/`; 11 test files (1,184 lines). |
| **Supabase migrations** | **10 total** | Spanning 2026-04-28 through 2026-05-17. **+4 new** since May 13: web courier schema, coupler indices, courier package RPC, storage bucket provisioning, coupler storage RLS repair. |
| **Wiki** | **18 pages pass validation** | All pass `scripts/wiki_ingest.py --validate`. Glossary expanded from ~30 to 52 terms. |
| **Dependencies** | **Pub get PASS** | 31 packages have newer versions incompatible with current constraints. |

---

## What Changed Since 13MAY2026

### New Features & Infrastructure

1. **Web Courier Schema & RPCs (May 14-15):** Four new migrations deliver the courier surface:
   - `courier_packages` table with RLS (black-box, no direct `SELECT`)
   - `attempt_courier_unlock` (SECURITY DEFINER, 5-max retries, auto-burn + storage cleanup on exhaustion)
   - `check_courier_attempts` (public-anon accessible)
   - `get_or_create_courier_package` (owner-scoped, idempotent)
   - `courier-blobs` storage bucket (50 MB limit, path-scoped policies)
   - Storage RLS repair for courier uploads (fixes 403)

2. **Web Platform Architecture (May 14-15):** Platform-conditional implementations added:
   - `cipher_engine_web.dart` (uses `dart:html` — see deprecation note)
   - `vault_service_web.dart`, `local_vault_storage_web.dart`, `vault_database_web.dart`
   - `courier_unlock_view.dart` — Flutter web UI for courier unlock (`?pkg=` deep link)
   - `courier_link_provider.dart` — Riverpod AsyncNotifier for courier link state
   - `archive_thumbnail_web.dart`, `archive_video_source_web.dart`
   - New `.cursor/rules/web-architecture.mdc` enforcing platform conditionals

3. **Heavy Metal Design System (May 13-14):**
   - `ShutterIrisPainter` (six-blade iris motif) supersedes `ShutterButtonPainter` (DEPRECATED)
   - `HeavyMetalBackdropMixin`, `Heavy_Metal_Design_System` concept page
   - `app_colors.dart` (titanium/verified neon/kinetic green palette), `app_typography.dart` (Space Mono)
   - `FactLockCamBackground.mp4` video asset

4. **Ephemeral QA Environment Tooling (May 14-15):**
   - `scripts/start_qa_env.sh` — single-command QA environment (Flutter Web + Ngrok tunnel + iOS Sim)
   - `WEB_VAULT_BASE_URL` compile-time define support in dart-define pipeline
   - `.cursor/rules/ephemeral-environments.mdc` — tunnel awareness, no prod domain assumptions

5. **Wiki Expansion (May 14-15):**
   - `FactLockCam_Blueprints_14May2026.md` at repo root + wiki twin (layered technical blueprint with Mermaid diagram)
   - `overview.md` and `log.md` populated (were empty)
   - 11 glossary terms added: AES-GCM, C2PA, PolygonChainNotarizer, ProofLockConflictException, proof_ledger, REQUIRE_HARDWARE_ATTESTATION, RLS, RPC, SealLedgerRepository, SHA-256, SimulatedChainNotarizer
   - `ShutterButtonPainter` marked DEPRECATED (superseded by `ShutterIrisPainter`)

6. **Corrupted File Remediation (May 15):**
   - `vault_service_io.dart` had been corrupted (contained SQL migration content, not Dart) due to trailing newline in filename on recreation. The file was deleted and the legitimate implementation confirmed intact. No recurrence.

### Code Quality Findings

| Finding | Location | Severity | Action |
|---------|----------|----------|--------|
| Deprecated `dart:html` import | `cipher_engine_web.dart:8` | Info | Migrate to `package:web` + `dart:js_interop` |
| Unformatted files | 5 files across `lib/` | Style | Run `dart format` |
| 3 TODO markers | `asset_action_provider.dart` (lines 24, 41, 45) | Low-Medium | Verified view, courier export, certificate export not yet wired |
| Native signing TODOs | `AppDelegate.swift:26`, `MainActivity.kt:22` | **High** | Replace simulated `signHash` with Secure Enclave / Keystore |
| `PolygonChainNotarizer` stub | `chain_notarizer.dart` | **High** | Still throws `UnsupportedError` |
| Unwired `REQUIRE_HARDWARE_ATTESTATION` | `app_config.dart` | Medium | Defined but not referenced in capture/sync gates |
| No Flutter test CI | `.github/workflows/supabase.yml` | Medium | Only Supabase migrations validated in CI |

### Architecture Pivot (2026-05-13) — Status Update

The **Cloud E2EE Archive & Web Verification** paradigm shift announced on May 13 remains **announced but not implemented** in terms of:

- **Cloud E2EE Archive**: The web platform variants (`*_web.dart` files) lay groundwork but the full encrypted-blob upload/download flow, zero-knowledge Supabase Storage integration, and quota telemetry UI are not yet built.
- **Web Courier Portal**: `courier_unlock_view.dart` exists as a Flutter web UI, and the Supabase courier RPC schema is complete, but the end-to-end flow (encrypted blob upload from mobile, recipient unlock via web portal, Polygonscan verification link) is not wired.
- **Subscription Tiers**: Free ($0/50 MB), Picture ($1/5 GB), Video ($10/50 GB) tiers are defined but have no pricing enforcement, no quota metering, no payment integration, and no egress limits in the app or backend.

The web courier migration stack is a necessary prerequisite for the pivot. The remaining implementation effort is largely unchanged from the 13MAY assessment.

---

## Key Pointers

- **Architecture snapshot (wiki twin):** `wiki/analyses/MASTER_CONTEXT16MAY2026.md`
- **Status anchor:** `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`
- **Capability map:** `wiki/analyses/FactLockCam_Master_Blueprint.md`
- **Layered blueprint:** `wiki/analyses/FactLockCam_Blueprints_14May2026.md` / `FactLockCam_Blueprints14May2026.md` (root)
- **Reconciliation audit:** `wiki/analyses/Project_Audit_2026-05-11.md`
- **Gap-to-target:** `wiki/analyses/ProofLock_Refactor_Scope.md`
- **Target manifest:** `wiki/sources/ProofLock_Architectural_Manifest.md`
- **Prior snapshot (superseded):** `wiki/analyses/MASTER_CONTEXT13MAY2026.md` / `MASTER_CONTEXT13MAY2026.md` (root)
- **Archived:** `wiki/analyses/Master_Context_11MAY2026.md`, `wiki/analyses/Master_Context_10MAY2026.md`
