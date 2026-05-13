---
tags: [source_summary, audit, snapseal, prooflock, repository]
summary: "Source summary for the 2026-05-11 repository vs wiki reconciliation audit (immutable raw)."
---

# Project Audit Source (2026-05-11)

## Core Synthesis

This immutable **`raw/`** document records a **repository audit** that reconciled the Flutter/Supabase/tree with LLM Wiki pages that had fallen behind **2026-05-10** narratives. The audit establishes, as compiled fact for the wiki:

- **Sealing** follows **`VaultService.proofLockFile`**: isolate hash, **`check_proof_status`** when online, **`signHash`** via **`NativeEnclaveChannel`** (platform handlers present but **simulated**), **`SimulatedChainNotarizer`** / RPC **`simulate_chain_notarize`**, local **AES-GCM** persistence, **`proof_ledger`** insert on success, **`pending_sync`** with backoff when remote work fails.
- **Reconciliation UX/code**: `PendingSyncScheduler`, dashboard **`syncPendingInBackground`**, and **Retry now** on pending items.
- **Local consistency**: compensating delete of encrypted + thumbnail files if SQLite upsert fails after file writes.
- **Polygon / attestation**: `PolygonChainNotarizer` is a **stub**; `REQUIRE_HARDWARE_ATTESTATION` exists on **`AppConfig`** but was **unwired** at audit time.
- **Tooling**: filtered **`dart_defines.json`** generation from `.env.local` / shell env for IDE and CLI runs.
- **Tests**: retry, dashboard, and native enclave channel tests exist in addition to the widget shell.

The durable **compiled** page with wiki cross-links and the findings table lives in [[Project_Audit_2026-05-11]]. Downstream concept/analysis pages ([[FactLockCam_Product_Baseline_2026-05]], [[FactLockCam_Master_Blueprint]], [[ProofLock_Refactor_Scope]], [[Master_Context_10MAY2026]]) were aligned in the same maintenance window.

## Provenance Tracking

* *Claims*: Derived from `raw/project_audit_2026-05-11.md` (2026-05-11)

## Related Notes

* [[Project_Audit_2026-05-11]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[FactLockCam_Master_Blueprint]]
* [[ProofLock_Refactor_Scope]]
* [[overview]]
* [[log]]
