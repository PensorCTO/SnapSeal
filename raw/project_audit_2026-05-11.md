# Project Audit — 2026-05-11

Date: 2026-05-11

Immutable source for formal wiki ingest. Compiled analysis: `wiki/analyses/Project_Audit_2026-05-11.md` (synthesis + backlinks).

## Scope

Cross-checked `snapseal_app/`, `supabase/`, `scripts/`, and prior wiki pages including:

- `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md`
- `wiki/analyses/SnapSeal_Master_Blueprint.md`
- `wiki/analyses/ProofLock_Refactor_Scope.md`
- `wiki/analyses/Master_Context_10MAY2026.md`

## Executive findings

Documentation dated through 2026-05-10 was **stale** vs the repository at audit time:

- Capture runs a **ProofLock-shaped** Dart pipeline (`VaultService.proofLockFile`).
- The Supabase client uses **`check_proof_status`** and **`simulate_chain_notarize`**; **`proof_ledger`** rows are inserted on the happy remote path.
- **Pending remote sync** is retried via a **~3-minute** `PendingSyncScheduler`, dashboard `syncPendingInBackground` on open, and a **“Retry now”** banner on `VaultDashboardView`.
- Partial local seal failure after file writes triggers **compensating deletion** of encrypted + thumbnail files when SQLite upsert fails (`VaultService._persistSealedBytes`).
- **Native `MethodChannel`** signing (`com.snapseal.app/enclave` / `signHash`) exists on iOS and Android but returns **simulated dev** payloads (TODO: Secure Enclave / Keystore).
- **Polygon** is not implemented: `USE_POLYGON_NOTARIZER=true` selects `PolygonChainNotarizer`, which throws `UnsupportedError`.
- **`REQUIRE_HARDWARE_ATTESTATION`** is present on `AppConfig` but **not referenced** elsewhere in the Dart tree at audit time.

## Developer tooling (observed)

- `scripts/write_flutter_dart_defines.py` emits filtered `snapseal_app/dart_defines.json` (default keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`).
- `scripts/sync_flutter_dart_defines.sh` and VS Code/Cursor launch pre-task integrate this path.

## Tests (observed under `snapseal_app/test/`)

Beyond `widget_test.dart`: `vault_service_retry_test.dart`, `vault_dashboard_view_test.dart`, `native_enclave_channel_test.dart`.

## Findings vs prior wiki claims

| Topic | Prior wiki (stale) | Current code (audit snapshot) |
| :--- | :--- | :--- |
| Pending sync | No retry worker / no reconciliation UI | `PendingSyncScheduler`, `syncPendingInBackground`, banner + Retry now |
| `check_proof_status` | Not called from app | `SealLedgerRepository.checkProofStatus` + `proofLockFile` / `retryPendingRemoteSync` |
| Seal remote writes | `seal_ledger` insert only | Primary: **`proof_ledger`** + simulated chain RPC; `syncAssetFingerprint` in **`retryPendingRemoteSync`** (best-effort `seal_ledger`) |
| Local atomicity | No rollback on SQLite failure after files | **`_persistSealedBytes`** deletes artifacts on DB upsert failure |
| Native TEE | Absent | Channel + **simulated** signature; not production hardware-backed |
| Tests | Widget shell only | Retry, dashboard, enclave channel tests added |
| Polygon | Not in app | Flag + stub notarizer only |

## Residual gaps

- Replace simulated native signatures with real Secure Enclave / Keystore signing; wire `REQUIRE_HARDWARE_ATTESTATION` when required.
- Implement `PolygonChainNotarizer` or keep `USE_POLYGON_NOTARIZER=false` until ready.
- Courier / `.plock` UI remains thin; `extractForCourier` / `CourierCrypto` exist at service layer.
- Manifest-style `courier_packages` / RPC-only courier not implemented.
- C2PA, production chain anchoring, broader failure-mode test matrix.

## Methodology note

Audit used read/grep of representative paths including `vault_service.dart`, `pending_sync_scheduler.dart`, `dashboard_controller.dart`, `vault_dashboard_view.dart`, `seal_ledger_repository.dart`, `AppDelegate.swift`, `MainActivity.kt`, and the scripts/tests named above.
