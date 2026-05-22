---
tags: [analysis, polygon, saga, factlockcam, blockchain, supabase, edge_functions]
summary: "May 2026 Polygon Try 2: synchronous capture-time relay, local chain_tx_hash persistence, certificate tx line, and seeded monitor UI."
---

# Polygon Saga (Live)

## Core Synthesis

**Try 2 is complete and QA-verified** on physical iPhone against hosted project `jqvnwtslmoxjwzusmtxs`.

- **Third QA 2026-05-21:** capture + Polygon ledger insert re-verified after Sprint 2 local persist ([[Vault_Transactional_Journal]]) and SQLite open race fix.
- **Second QA 2026-05-20:** post-capture proof progress regression and certificate tx-hash omission fixed.

When `USE_POLYGON_NOTARIZER=true` (default after `scripts/sync_flutter_dart_defines.sh`), capture runs:

1. Isolate SHA-256 hash
2. Device sign + **EIP-191 EVM sign** (`PolygonWalletService`)
3. Local AES-GCM vault + SQLite (`pending_sync=true`)
4. `proof_ledger` INSERT with `notarization_status=pending_notarization`
5. **Await** `anchor-relay` Edge Function (camera overlay shows **"Generating Proof…"** until return)
6. Relay calls `finalize_polygon_notarization`; client persists **`chain_tx_hash`** locally (SQLite v5) and clears `pending_sync`
7. Verified flash + haptic on success

Simulated chain remains available when `USE_POLYGON_NOTARIZER=false`.

**Simulated on-chain hash (QA default):** When `ALCHEMY_API_URL` or `RELAYER_PRIVATE_KEY` are unset on the Edge Function, `anchor-relay` finalizes with deterministic `polygon-sim:<asset_hash>` (hex-encoded as `chain_tx_hash`). When both secrets are set, the relay broadcasts `notarize(bytes32)` on Polygon mainnet via the shared relayer wallet. See [[Polygon_Mainnet_Wiring_2026-05]] for the seventh QA regression fix (v3 returned 500 without secrets).

## Architecture (Try 2 — post-regression fix)

```mermaid
sequenceDiagram
    participant UI as Camera + Vault UI
    participant VS as VaultService
    participant WS as PolygonWalletService
    participant ER as anchor-relay
    participant DB as Supabase proof_ledger
    participant SQL as SQLite archive_items

    UI->>VS: proofLockFile (overlay: Generating Proof…)
    VS->>WS: signMessageHash (EIP-191, isolate)
    VS->>VS: transactional journal + local vault encrypt
    VS->>DB: INSERT pending_notarization
    VS->>ER: invoke anchor-relay (await)
    ER->>DB: finalize_polygon_notarization (tx_hash)
    ER-->>VS: { tx_hash }
    VS->>SQL: chain_tx_hash + pending_sync=0
    VS-->>UI: SealCaptureResult (verified flash)
```

## Key surfaces

| Layer | Artifact | Role |
|-------|----------|------|
| Domain | `WalletService` / `PolygonWalletService` | EVM key in `FlutterSecureStorage`; `profiles.evm_address` sync |
| Domain | `VaultBlockchainHandler` / `PolygonBlockchainHandler` | `invoke('anchor-relay')` → returns `transactionHash` |
| Domain | `PolygonChainNotarizer` | EIP-191 owner sign + delegate to `PolygonBlockchainHandler` |
| Domain | `NotarizationMonitorService` | Realtime `UPDATE` + **RPC receipt polling** when `POLYGON_RPC_URL` set |
| Domain | `NotarizationMonitorService` | Realtime `UPDATE` + **initial remote seed** on `watchAsset` |
| Domain | `ProofSyncNotifier` | Clears local pending + invalidates dashboard on relay success |
| Data | `ArchiveItem.chainTxHash` | SQLite column (DB v5); written on relay success |
| Data | `SealLedgerRepository.fetchProofChainTxHash` | Remote fallback for certificates on legacy rows |
| Export | `CertificateExportService.buildCertificateDraft` | Async; includes **Ledger Transaction Hash** line |
| UI | `camera_view.dart` `_SealingOverlay` | Polygon copy: **Generating Proof…** |
| UI | `chronology_card.dart` / omni grid | **Generating Proof…** badge via `proofNotarizationStateProvider` |
| Edge | `supabase/functions/anchor-relay/index.ts` | JWT + EIP-191 verify → live broadcast or sim fallback → finalize row |
| DB | `20260520120000_polygon_saga_proof_ledger.sql` | `notarization_status`, nullable `chain_tx_hash`, finalize RPCs |
| DB | `20260523000000_polygon_tx_indexing.sql` | Indexes for monitor polling by `chain_tx_hash` / `notarization_status` |
| Config | `POLYGON_RPC_URL` | Optional dart-define for client-side receipt polling |
| Flag | `USE_POLYGON_NOTARIZER` | Compile-time via `dart_defines.json` (sync script defaults **true**) |

## QA notes

| Issue | Fix |
|-------|-----|
| Post-capture proof progress disappeared | Fire-and-forget relay returned before UI could show state; **await relay** during `proofLockFile` |
| Vault badge skipped "Generating Proof…" | Relay finished before dashboard refresh; monitor now **seeds** initial status; chronology shows badge while `pendingNotarization` |
| Certificate missing tx hash | `CertificateExportService` adds ledger hash; local SQLite + remote fetch |
| Legacy rows without local hash | Certificate falls back to `fetchProofChainTxHash` from `proof_ledger` |
| Pending sync stuck after capture (2026-05-22) | `anchor-relay` v3 returned 500 without Polygon secrets; client swallowed error. Fixed: sim fallback redeploy — [[Polygon_Mainnet_Wiring_2026-05]] |
| Flutter Web compile failure | Unconditional `sqlite3` import in `journal_repository.dart`; fixed with stub/io conditional export |

**Deploy checklist:** `supabase db push` (saga + indexing migrations) + `supabase functions deploy anchor-relay --no-verify-jwt`. Optional: `supabase secrets set ALCHEMY_API_URL=... RELAYER_PRIVATE_KEY=...` for live mainnet.

**Device rebuild (required):** signed debug build with `--dart-define-from-file=dart_defines.json` — never `--no-codesign` for physical install ([[iOS_Device_Development_Workflow]]).

## Provenance Tracking

* *Implementation*: `vault_service_io.dart`, `vault_blockchain_handler.dart`, `notarization_monitor_service.dart`, `certificate_export_service.dart`, `vault_database_io.dart` (v5), `seal_ledger_repository.dart` (2026-05-20 regression fix).
* *Try 1 context*: [[Polygon_Try1_Postmortem]], [`POSTMORTEM_POLYGON_TRY1.md`](../../POSTMORTEM_POLYGON_TRY1.md).

## Related Notes

* [[Polygon_Mainnet_Wiring_2026-05]]
* [[Polygon_Try1_Postmortem]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[ProofLock_Refactor_Scope]]
* [[FactLockCam_Master_Blueprint]]
* [[glossary]]
