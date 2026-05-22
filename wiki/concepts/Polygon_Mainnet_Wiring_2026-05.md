---
tags: [concept, polygon, factlockcam, supabase, edge_functions, qa]
summary: "Seventh QA (2026-05-22): prooflock_production relay wiring, anchor-relay sim fallback, web compile fix, RPC monitor, and hosted deploy checklist."
---

# Polygon Mainnet Wiring (2026-05)

## Core Synthesis

**Seventh QA pass (2026-05-22)** wires FactLockCam to the same Polygon relayer pattern as `prooflock_production`, fixes a **regression** that left captures stuck in **pending sync**, and restores **Flutter Web** compilation.

### What landed

| Area | Change |
|------|--------|
| Edge Function | `anchor-relay` uses `ethers.js` + shared contract `0x83508c78104b8b58ff844EE5654FaaC06cFFc155` when `ALCHEMY_API_URL` + `RELAYER_PRIVATE_KEY` are set; otherwise **QA sim fallback** (`polygon-sim:<asset_hash>` hex) per blueprint |
| Client relay | `PolygonBlockchainHandler` reads `transactionHash` from relay response; `PolygonChainNotarizer` delegates to wallet sign + handler |
| Monitor | `PolygonNotarizationMonitorService.checkPendingPolygonTransactions()` polls Polygon RPC via `Web3Client` when `POLYGON_RPC_URL` is defined |
| DB | Migration `20260523000000_polygon_tx_indexing.sql` — indexes on `proof_ledger.chain_tx_hash` and `notarization_status` |
| Web | `journal_repository.dart` → conditional export (`journal_repository_stub.dart` / `journal_repository_io.dart`) so `sqlite3`/`dart:ffi` are not compiled on web |
| Compile fix | `seal_ledger_repository.dart` — removed invalid `?evmAddress` map syntax |
| Deps | `http: ^1.2.0` for `Web3Client` polling |

### QA regression (fixed)

**Symptom:** Capture succeeds locally but badge shows **"1 item pending sync"** indefinitely; Edge Function logs show **HTTP 500**.

**Cause:** Deployed `anchor-relay` v3 returned `500 Relayer environment not configured` when Polygon secrets were unset. Client `_dispatchPolygonRelay` **swallows all errors** → `pendingSync` stays true; retry scheduler loops silently.

**Fix:** Restore blueprint behavior — sim hash + `finalize_polygon_notarization` when secrets missing. Redeploy with `supabase functions deploy anchor-relay --no-verify-jwt`.

### Ops checklist (hosted `jqvnwtslmoxjwzusmtxs`)

```bash
# From repo root — .env.local must have SUPABASE_ACCESS_TOKEN, SUPABASE_DB_PASSWORD
source .env.local
export SUPABASE_ACCESS_TOKEN
supabase link --project-ref jqvnwtslmoxjwzusmtxs --password "$SUPABASE_DB_PASSWORD" --yes
supabase db push                                    # polygon_tx_indexing migration
supabase functions deploy anchor-relay --no-verify-jwt

# Optional live mainnet (same wallet as prooflock_production):
supabase secrets set ALCHEMY_API_URL=https://... RELAYER_PRIVATE_KEY=0x...
```

**Flutter Web QA:** `cd factlockcam_app && flutter run -d web-server --web-port 3001 --dart-define-from-file dart_defines.json`

**Secrets note:** `sb_publishable_*` / `sb_secret_*` keys are **not** CLI deploy tokens. Deploy requires `sbp_*` Personal Access Token in `SUPABASE_ACCESS_TOKEN`.

### Relay contract (client ↔ Edge Function)

| Field | Direction |
|-------|-----------|
| Request body | `{ asset_hash, owner_signature, device_signature }` |
| Auth | User JWT in `Authorization: Bearer` (not anon key alone) |
| Response 200 | `{ transactionHash, status: "pending" \| "already_notorized" }` |
| Sim hash format | `0x` + hex of UTF-8 `polygon-sim:<asset_hash>` (padded to 64 hex chars) |

## Provenance Tracking

* *Code*: `supabase/functions/anchor-relay/index.ts`, `vault_blockchain_handler.dart`, `chain_notarizer.dart`, `notarization_monitor_service.dart`, `app_config.dart`, `journal_repository*.dart`, `20260523000000_polygon_tx_indexing.sql` (2026-05-22).
* *Reference*: `prooflock_production/POLYGON_INTEGRATION_EXTRACT.md`, `prooflock_production/supabase/functions/anchor-relay/index.ts`.
* *QA*: User-confirmed seventh pass after sim-fallback deploy + stuck row repair.

## Related Notes

* [[Polygon_Saga_Live]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[Polygon_Try1_Postmortem]]
* [[iOS_Device_Development_Workflow]]
* [[glossary]]
