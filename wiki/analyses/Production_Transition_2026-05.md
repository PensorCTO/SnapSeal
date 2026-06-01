---
tags: [analysis, factlockcam, app_store, production, courier, qa, 2026-05]
summary: "Ninth QA pass (2026-05-24): production dart-defines, courier lookup migrations, iOS privacy/export compliance, and test isolation for App Store submission."
---

# Production Transition (May 2026)

## Core Synthesis

**Ninth device QA pass (2026-05-24)** — user-confirmed after production-transition remediation from the Infrastructure Specification for the web archive.

This sprint moves FactLockCam from stealth/dev posture toward **App Store submission readiness**: production compile-time URLs, hosted courier lookup performance, iOS privacy manifest completeness, and a green automated test suite under production notarizer defaults.

### Production compile-time config

| Define | Production value | Role |
|--------|------------------|------|
| `APP_ENVIRONMENT` | `production` | Runtime guardrails (`AppConfig.isProduction`) |
| `WEB_ARCHIVE_BASE_URL` | `https://archive.factlockcam.com` | Courier share links + web unlock origin (renamed from `WEB_VAULT_BASE_URL` in tenth QA — [[App_Store_Remediation_2026-05]]) |
| `SUPPORT_URL` | `https://factlockcam.com/support` | Account panel Help & Support |
| `USE_POLYGON_NOTARIZER` | `true` | Live Polygon saga (unchanged default) |

Sources: `factlockcam_app/dart_defines.json`, `scripts/write_flutter_dart_defines.py`, gitignored `generated_dart_defines.dart` (via `scripts/sync_flutter_dart_defines.sh`).

**Pre-submit ops:** Confirm both HTTPS origins are live before archiving a release build with `--dart-define-from-file dart_defines.json`.

### Supabase courier lookup (hosted + local)

| Migration | Purpose |
|-----------|---------|
| `20260524130000_optimize_courier_lookups.sql` | `unlock_code` + `status` columns on `courier_packages`; backfill; index `(unlock_code, status)` |
| `20260524140000_courier_lookup_trigger.sql` | Trigger `courier_packages_sync_lookup_fields` keeps lookup columns in sync on insert/update |
| `20260524150000_optimize_courier_archive.sql` | Btree indices on `asset_hash`, `(package_id, expires_at)`, `(owner_id, asset_hash)` — pushed tenth QA |

Pushed via `scripts/factlockcam_supabase_pipeline.sh push`; remote **20/20** migrations in sync.

### iOS App Store compliance

| Artifact | Change |
|----------|--------|
| `PrivacyInfo.xcprivacy` | Declares DiskSpace (`E174.1`), EmailAddress, PreciseLocation collected types |
| `Info.plist` | `ITSAppUsesNonExemptEncryption` = `false` (export compliance) |

Run Xcode **Generate Privacy Report** on the release archive before Connect upload.

### Test isolation + suite health

- `test/test_dependencies.dart` — shared `setupTestDependencies()` (sqflite FFI, path_provider/shared_preferences mocks, DI reset).
- `AppConfig.isFlutterTest` — skips Supabase init, polygon monitor, and pending-sync scheduler timers in tests.
- `vault_service_retry_test.dart` — polygon + simulated retry paths; `TransactionalArchivePersister` mock for `proofLockFile`.
- `vault_service_io.dart` — polygon retry defers on recoverable relay failures (parity with simulated sync).

**Result:** `flutter test` **40/40** passing under production compile defaults (`USE_POLYGON_NOTARIZER=true`).

### Still manual before Connect

- Verify live **`archive.factlockcam.com`** and **`factlockcam.com/support`** (or use Ngrok + temp support page for **TestFlight only** — [[App_Store_Remediation_2026-05]]).
- Release archive with production dart-defines file.
- App Store Connect metadata + age-rating questionnaire.
- Recipient Send Proof E2E once web archive host serves `/courier?pkg=…` ([[Send_Proof_Courier_2026-05]]).

## Provenance Tracking

* *Spec + implementation*: Agent session 2026-05-24; Infrastructure Specification production transition; user-confirmed ninth QA pass.
* *Code*: `app_config.dart`, `account_settings_panel.dart`, `vault_service_io.dart`, `test_dependencies.dart`, `vault_service_retry_test.dart`, iOS `PrivacyInfo.xcprivacy`, `Info.plist`, courier migrations under `supabase/migrations/`.
* *Ops*: `scripts/factlockcam_supabase_pipeline.sh push`, `supabase migration up --local`.

## Related Notes

* [[App_Store_Remediation_2026-05]]
* [[Send_Proof_Courier_2026-05]]
* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[FactLockCam_Master_Blueprint]]
* [[overview]]
* [[log]]
