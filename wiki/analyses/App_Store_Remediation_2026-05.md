---
tags: [analysis, factlockcam, app_store, compliance, archive, qa, 2026-05]
summary: "Tenth QA pass (2026-05-24): App Store remediation — WEB_ARCHIVE_BASE_URL rename, courier archive indices pushed, dead code removed, TestFlight-ready backend."
---

# App Store Remediation (May 2026)

## Core Synthesis

**Tenth device QA pass (2026-05-24)** — user-confirmed after executing the 2026 App Store compliance remediation blueprint (audit against *Navigating the 2026 App Store Compliance and Optimization Standards*).

This pass completes **code-side** submission prep while **deferring trademark/domain purchase** until after TestFlight validation.

### Compile-time archive nomenclature

| Before | After |
|--------|-------|
| `WEB_VAULT_BASE_URL` | **`WEB_ARCHIVE_BASE_URL`** |
| `webVaultBaseUrl` / `_effectiveCourierWebVaultBase()` | `webArchiveBaseUrl` / `_effectiveCourierWebArchiveBase()` |
| Default origin `vault.factlockcam.com` | **`https://archive.factlockcam.com`** |

Sources: `app_config.dart`, `vault_service_io.dart`, `scripts/write_flutter_dart_defines.py`, `scripts/sync_flutter_dart_defines.sh`.

`AppConfig.webVaultBaseUrl` retained as `@Deprecated` alias only.

### Dead code elimination

- Deleted `lib/ui/mobile/vault/professional_nav_bar.dart` (unreferenced; hub uses `HapticHubPanel` only).
- Renamed `TransactionalVaultPersister` → **`TransactionalArchivePersister`** (`transactional_archive_persister.dart`).

### iOS native (privacy manifest untouched)

- **`NSCameraUsageDescription`** — forensic/crypto copy for Guideline 5.1.1.
- **`ITSAppUsesNonExemptEncryption`** = `false` (verified).

### Supabase — courier archive indices (hosted)

Migration **`20260524150000_optimize_courier_archive.sql`** pushed via `scripts/factlockcam_supabase_pipeline.sh push`:

| Index | Columns | Purpose |
|-------|---------|---------|
| `idx_courier_packages_package_hash` | `asset_hash` | Accelerates fingerprint lookups (`get_or_create_courier_package`) |
| `idx_courier_packages_id_expires_at` | `(package_id, expires_at)` | Expiry gate on `attempt_courier_unlock` |
| `idx_courier_packages_owner_asset_hash` | `(owner_id, asset_hash)` | Owner + fingerprint composite lookup |

Remote migration history: **20/20** local ↔ remote in sync.

### Defines re-sync

`./scripts/sync_flutter_dart_defines.sh` regenerated `dart_defines.json` + `generated_dart_defines.dart` from `.env.local` with production Supabase + Polygon RPC; archive/support URLs use script defaults until domains are purchased.

### Cursor compliance rule

`.cursor/rules/app_store_compliance.mdc` — Archive nomenclature, no placeholder UI, privacy manifest lock, courier index requirement.

### TestFlight posture (pre-domain)

| Flow | TestFlight without purchased domains |
|------|--------------------------------------|
| Login, capture, seal, archive, certificate | ✅ Hosted Supabase + Polygon |
| Send Proof share sheet | ✅ Package creation |
| Courier link opens in Safari | ⚠️ Use **Ngrok** or staging origin in `.env.local` → re-sync |
| Help & Support URL | ⚠️ Temporary FAQ page until `factlockcam.com` registered |

TestFlight does **not** require live marketing domains; App Store Connect review does.

### Automated tests

`flutter test` **40/40** after remediation.

## Provenance Tracking

* *Blueprint*: User architectural manifest + 2026 App Store compliance audit session 2026-05-24.
* *Ops*: `factlockcam_supabase_pipeline.sh push`, `sync_flutter_dart_defines.sh`; user-confirmed tenth QA pass.
* *Code*: `vault_service_io.dart`, `app_config.dart`, `Info.plist`, courier migration, deleted `professional_nav_bar.dart`, `transactional_archive_persister.dart`.

## Related Notes

* [[App_Store_Hardening_2026-05]] — fifteenth QA (2026-05-30): hardware signing, manifest remediation
* [[Production_Transition_2026-05]]
* [[Send_Proof_Courier_2026-05]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[log]]
