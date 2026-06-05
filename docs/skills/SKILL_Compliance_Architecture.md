# SKILL: FactLockCam Zero-Trust & App Store Compliance Alignment

## Description

A procedural toolkit to systematically eradicate legacy terminology, scaffold User-Generated Content (UGC) safety infrastructure, and prepare technical blueprints for provisional patent filing.

## Prerequisites

- Read `wiki/index.md`, `wiki/overview.md`, and `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`.
- Read `.cursor/rules/app_store_compliance.mdc`, `courier-origination.mdc`, and `02_supabase_rls_security.mdc`.
- Existing compliance pass: `wiki/analyses/Compliance_Refactor_2026-06.md`.

## Step 1: Lexicon Enforcement

1. Grep user-visible strings under `lib/ui/`, `lib/core/marketing/`, `lib/core/legal/` — replace **Vault** with **Archive** in UI copy only.
2. Plan structural renames with typedef shims (non-breaking):
   - `VaultService` → `ArchiveService` (`vault_service_io.dart` → `archive_service_io.dart`)
   - `VaultDatabase` → `ArchiveDatabase`
   - `LocalVaultStorage` → `LocalArchiveStorage`
3. **Defer breaking renames:** `factlock_vault` bucket, SQL `vault_key`, Secure Storage `factlockcam:vault_key`, on-disk `factlockcam_vault.db`.
4. Extend `marketing_compliance_test.dart` and `presentation_archive_copy_test.dart` after each pass.

## Step 2: Safety Infrastructure Scaffolding

1. Create `factlockcam_app/lib/features/ugc_safety/` module:
   - Domain: `ContentReportReason`, `BlockOriginRequest`
   - Data: `SafetyRepository` (RPC only — no Supabase in widgets)
   - Presentation: `ReportContentSheet`, `BlockSenderDialog`
   - Providers: `contentReportProvider`, `senderBlockProvider` (Riverpod + GetIt bridge)
2. Integrate reporting into `UniversalAssetToolbar` via `additionalActions` in `archive_item_actions.dart`.
3. Integrate reporting/blocking into `CourierUnlockView` (primary recipient surface).
4. **Never** place identity verification gates in front of `CameraView` — placeholders in Account panel only.
5. Migration: `supabase/migrations/20260605120000_ugc_safety_infrastructure.sql`.
6. Edge Function: `supabase/functions/courier-content-scan/` — async ML placeholder on `courier-blobs` upload.
7. Fire-and-forget `invoke('courier-content-scan')` from `proof_courier_service.dart` after upload (off hot path).

## Step 3: Database Governance

1. Audit RLS on `courier_packages`, `proof_ledger`, `archive_quotas`, `subscription_cycles`.
2. Verify `courier_packages.vault_key` never returned to anon/authenticated SELECT.
3. Document matrix in `wiki/analyses/Zero_Trust_RLS_Audit_2026-06.md`.
4. Ensure all new tables have INSERT/UPDATE/DELETE/SELECT policies per role.
5. Index `courier_content_reports(package_id)` and `courier_sender_blocks(blocked_owner_id)`.

## Step 4: Patent Blueprint Compilation

1. Extract transactional journal logic from `transactional_archive_persister.dart`.
2. Document isolate lock coordinator from `isolate_lock_coordinator.dart`.
3. Document async Polygon saga from `vault_service_io.dart` `_proofLockFilePolygonSaga`.
4. Structure as `wiki/analyses/Provisional_Patent_Technical_Exhibit_2026-06.md` with:
   - Inputs, Outputs, Expected Failure Modes per component
   - Enablement-oriented prose (35 U.S.C. § 112)
5. Export copy under `docs/patent/` if needed for filing.

## Wiki Reconciliation

After each implementation pass:

1. Append summary to `wiki/log.md`.
2. Update `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`.
3. Add analysis pages under `wiki/analyses/` as needed.
4. Update `wiki/index.md` and `wiki/glossary.md`.
5. Run `python3 scripts/wiki_ingest.py --validate`.

## Test Checklist

- `flutter test` — full suite green after each PR.
- Widget test: `CourierUnlockView` report affordance visible.
- RPC: anon `report_courier_package` does not leak `owner_id`.
- `marketing_compliance_test.dart` — no banned claims in report copy.
