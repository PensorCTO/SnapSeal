---
tags: [concept, polygon, factlockcam, supabase, edge_functions, qa, ios]
summary: "Eighth QA (2026-05-22): live Polygon mainnet on physical iPhone — secrets wired, sim fallback removed, honest relay errors."
---

# Polygon Mainnet Wiring (2026-05)

## Core Synthesis

**Eighth QA pass (2026-05-22)** completes **live Polygon mainnet** on **physical iPhone** against hosted project `jqvnwtslmoxjwzusmtxs`: real `notarize(bytes32)` broadcast, **`chain_tx_hash` visible on Polygonscan**, sync badge clears, user-confirmed pass.

**Seventh QA (same day)** wired the `prooflock_production` relayer pattern, fixed pending-sync regression, and restored Flutter Web compile — see history below.

### Eighth QA — what landed

| Area | Change |
|------|--------|
| Ops | `ALCHEMY_API_URL` + `RELAYER_PRIVATE_KEY` set on hosted Supabase via `supabase secrets set` |
| Edge Function | `anchor-relay` **live-only** — no `polygon-sim:` fallback; missing secrets → **HTTP 500** with `missing` list |
| Client relay | `PolygonBlockchainHandler` rejects legacy sim hashes; surfaces structured relay error bodies |
| Archive | `_dispatchPolygonRelay` **propagates** relay failures (no silent `catch` → pending-sync loop) |
| Config | `POLYGON_RPC_URL` in dart-defines sync + `GeneratedDartDefines` fallback for receipt polling |
| Device QA | **iOS primary** — `flutter run -d <deviceName> --dart-define-from-file dart_defines.json` (not `-d ios`) |

### On-chain topology (verified eighth QA)

| Role | Address | Notes |
|------|---------|-------|
| Notary contract | `0x83508c78104b8b58ff844EE5654FaaC06cFFc155` | Shared with `prooflock_production` |
| Active relayer (FactLockCam) | `0x549670B8170BA5180b95947aDD0b57cfdA2bE31d` | Pays gas; txs visible on Polygonscan |
| Historical relayer | `0xf048eDA73005557421750fe6db82dbd4b702ca7c` | Original prooflock_production payer (~234 prior notarizations) |
| User profile wallet (iPhone) | Per-user `profiles.evm_address` | EIP-191 signs asset hash only; does **not** pay gas |

**Secrets never belong in git.** Store only in Supabase Edge Function secrets (and local gitignored `.env.local` for CLI ops).

### Seventh QA — wiring + regression (same day, earlier)

| Area | Change |
|------|--------|
| Edge Function | `ethers.js` + shared contract; initial sim fallback (later **removed** in eighth QA) |
| Client relay | `PolygonChainNotarizer`; `transactionHash` API contract |
| Monitor | `PolygonNotarizationMonitorService` RPC receipt polling when `POLYGON_RPC_URL` set |
| DB | Migration `20260523000000_polygon_tx_indexing.sql` |
| Web | `journal_repository` stub/io conditional export |
| Compile fix | `seal_ledger_repository.dart` — invalid `?evmAddress` syntax |

### Ops checklist (hosted `jqvnwtslmoxjwzusmtxs`)

```bash
# From repo root — .env.local must have SUPABASE_ACCESS_TOKEN, SUPABASE_DB_PASSWORD
source .env.local
export SUPABASE_ACCESS_TOKEN
supabase link --project-ref jqvnwtslmoxjwzusmtxs --password "$SUPABASE_DB_PASSWORD" --yes
supabase db push
supabase functions deploy anchor-relay --no-verify-jwt

# Live mainnet (required — no sim fallback after eighth QA):
supabase secrets set \
  ALCHEMY_API_URL='https://polygon-mainnet.g.alchemy.com/v2/YOUR_KEY' \
  RELAYER_PRIVATE_KEY='0xYOUR_FUNDED_RELAYER_KEY' \
  --project-ref jqvnwtslmoxjwzusmtxs
```

**iOS device QA (primary):**

```bash
cd factlockcam_app
flutter devices                    # note device name, e.g. iPhoneTanto
flutter run -d iPhoneTanto --dart-define-from-file dart_defines.json
```

Include `POLYGON_RPC_URL` (same Alchemy polygon-mainnet URL) in `dart_defines.json` for client receipt polling — sync via `scripts/sync_flutter_dart_defines.sh` when using `.env.local`.

**Secrets note:** `sb_publishable_*` keys are **not** CLI deploy tokens. Deploy requires `sbp_*` Personal Access Token in `SUPABASE_ACCESS_TOKEN`.

### Relay contract (client ↔ Edge Function)

| Field | Direction |
|-------|-----------|
| Request body | `{ asset_hash, owner_signature, device_signature }` |
| Auth | User JWT in `Authorization: Bearer` |
| Response 200 | `{ transactionHash, status: "pending" \| "already_notorized" }` |
| Response 500 (misconfig) | `{ error, missing, message }` — no fake hash |

### Legacy `polygon-sim:` hashes (removed)

Seventh QA briefly used deterministic `polygon-sim:<asset_hash>` when secrets were unset. **Eighth QA removed this path.** Old rows may still carry sim-encoded `chain_tx_hash` values; new captures require live broadcast.

## Provenance Tracking

* *Code*: `supabase/functions/anchor-relay/index.ts`, `vault_blockchain_handler.dart`, `vault_service_io.dart`, `chain_notarizer.dart`, `notarization_monitor_service.dart`, `app_config.dart`, `write_flutter_dart_defines.py` (2026-05-22).
* *Reference*: `prooflock_production/POLYGON_INTEGRATION_EXTRACT.md`.
* *QA*: Eighth pass — physical iPhone capture, real Polygon tx confirmed; seventh pass — wiring + pending-sync fix.

## Related Notes

* [[Polygon_Saga_Live]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[iOS_Device_Development_Workflow]]
* [[Polygon_Try1_Postmortem]]
* [[glossary]]
