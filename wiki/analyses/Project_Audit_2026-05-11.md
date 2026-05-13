---
tags: [analysis, audit, snapseal, prooflock, wiki_maintenance]
summary: "Repository audit as of 2026-05-11: reconciles LLM Wiki claims with Flutter/Supabase implementation (seal pipeline, sync, tests, dev tooling)."
---

# Project Audit (2026-05-11)

## Core Synthesis

This audit cross-checked `factlockcam_app/`, `supabase/`, `scripts/`, and key wiki pages ([[FactLockCam_Product_Baseline_2026-05]], [[FactLockCam_Master_Blueprint]], [[ProofLock_Refactor_Scope]], [[Master_Context_10MAY2026]]). Several pages written through **2026-05-10** were **stale** relative to the current tree: capture now runs a **ProofLock-shaped** Dart pipeline (`VaultService.proofLockFile`), the Supabase client exposes **`check_proof_status`** and **`simulate_chain_notarize`**, **`proof_ledger`** rows are inserted on the happy remote path, **pending remote sync** is retried on a **3-minute timer** plus **dashboard lifecycle** and a **“Retry now”** banner, partial local seal failure triggers **compensating file deletion**, and **native `MethodChannel` signing exists but is deliberately simulated** on iOS/Android (TODO comments for Secure Enclave / Keystore). **Polygon** remains unwired: `USE_POLYGON_NOTARIZER=true` selects `PolygonChainNotarizer`, which still throws `UnsupportedError`. `REQUIRE_HARDWARE_ATTESTATION` is defined in `AppConfig` but **not referenced** elsewhere yet.

**Historical note:** this audit records the repo state at ingest time. Later 2026-05-11 UI work split the authenticated surface into `/vault-home` and `/archive`, added local per-item delete, full-size photo viewing, native video-frame thumbnails, and a metallic forensic viewfinder. The 2026-05-12 cleanup added the Domain Interaction Contract, cached photo-view extraction, REC-state failure reset, and MIME-aware video-thumbnail fallback documentation; see [[Master_Context_11MAY2026]] and [[FactLockCam_Master_Blueprint]] for current behavior.

Developer ergonomics improved: **`scripts/write_flutter_dart_defines.py`** emits filtered **`factlockcam_app/dart_defines.json`** (only `SUPABASE_URL` / `SUPABASE_ANON_KEY` by default), **`scripts/sync_flutter_dart_defines.sh`** and **VS Code/Cursor launch** run sync before debug. Tests now include **`vault_service_retry_test.dart`**, **`vault_dashboard_view_test.dart`**, and **`native_enclave_channel_test.dart`** in addition to **`widget_test.dart`**.

### Findings vs prior wiki claims

| Topic | Prior wiki (stale) | Current code |
| :--- | :--- | :--- |
| Pending sync | No retry worker / no reconciliation UI | `PendingSyncScheduler` (3 min), `syncPendingInBackground` on dashboard open, banner + **Retry now** |
| `check_proof_status` | Not called from app | `SealLedgerRepository.checkProofStatus` + used in `proofLockFile` / `retryPendingRemoteSync` |
| Seal remote writes | `seal_ledger` insert only | Primary path: **`proof_ledger`** + simulated chain RPC; **`syncAssetFingerprint`** still used in **`retryPendingRemoteSync`** (best-effort `seal_ledger`) |
| Local atomicity | No rollback on SQLite failure after files | **`_persistSealedBytes`** deletes encrypted + thumbnail on DB upsert failure |
| Native TEE | Absent | **Present as channel + simulated signature**; not production hardware-backed |
| Tests | Widget shell only | Retry, dashboard, enclave channel tests added |
| Polygon | Not in app | Flag + stub notarizer only |

### Residual gaps (unchanged or narrowed)

- Replace simulated native signatures with **real** Secure Enclave / Keystore signing and wire **`REQUIRE_HARDWARE_ATTESTATION`** when product requires it.
- Implement **PolygonChainNotarizer** (or drop flag until ready).
- **Courier / `.plock` UX** remains thin at the UI layer relative to vault-first ambitions (`extractForCourier` / `CourierCrypto` exist).
- **Supabase `courier_packages` / RPC-only courier** model from the manifest is not implemented.
- **C2PA**, **production** chain anchoring, and broader **test matrix** for failure modes.

## Provenance Tracking

* *Primary source*: Derived from `raw/project_audit_2026-05-11.md` via [[Project_Audit_2026-05-11_Source]] (2026-05-11 formal ingest)
* *Audit methodology*: Read `wiki/index.md` → baseline/blueprint/refactor/master context → grep/read `factlockcam_app/lib/domain/services/vault_service.dart`, `factlockcam_app/lib/ui/controllers/pending_sync_scheduler.dart`, `factlockcam_app/lib/ui/controllers/dashboard_controller.dart`, `factlockcam_app/lib/ui/views/vault_dashboard_view.dart`, `factlockcam_app/lib/data/supabase/seal_ledger_repository.dart`, `factlockcam_app/ios/Runner/AppDelegate.swift`, `factlockcam_app/android/app/src/main/kotlin/com/snapseal/snapseal/MainActivity.kt`, `scripts/write_flutter_dart_defines.py`, `factlockcam_app/test/*.dart` (2026-05-11)

## Related Notes

* [[Project_Audit_2026-05-11_Source]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[FactLockCam_Master_Blueprint]]
* [[ProofLock_Refactor_Scope]]
* [[Master_Context_10MAY2026]]
* [[Master_Context_11MAY2026]]
* [[overview]]
* [[log]]
