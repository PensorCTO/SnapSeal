---
tags: [concept, snapseal, baseline, supabase, product_status]
summary: "Authoritative May 2026 baseline: verified primary workflow and compressed Supabase repair/backfill narrative with migration pointers."
---

# SnapSeal Product Baseline (2026-05)

## Core Synthesis

As of this baseline, the **primary product workflow is verified end-to-end** on a correctly migrated hosted Supabase project: **logon** (email OTP) → **choose capture** → **take picture** → **return to dashboard** with the sealed asset listed as completed (local vault + ledger path when sync succeeds). Detail beyond this snapshot lives in [[SnapSeal_Master_Blueprint]]; ProofLock-class gaps and phased work remain in [[ProofLock_Refactor_Scope]].

### Verified workflow (happy path)

1. Authenticate via Magic Number (6-digit email OTP) when Supabase is configured with Dart defines.
2. Navigate to capture; capture media; **ProofLock-shaped** sealing runs when online: **`check_proof_status`** preflight (`new` only), **device signature** via `NativeEnclaveChannel` (currently **simulated** on iOS/Android — not production Secure Enclave/Keystore yet), **`simulate_chain_notarize`** via `SimulatedChainNotarizer` (unless `USE_POLYGON_NOTARIZER` is enabled — **Polygon adapter is still unsupported**), local **AES-GCM** vault write + SQLite, then **`proof_ledger`** insert when remote steps succeed; `pending_sync` remains when remote work cannot complete.
3. Land on **`/vault-dashboard`** with the new archive row visible (thumbnail + fingerprint; pending when the remote path is incomplete). **Background pending-sync retries** (timer + dashboard lifecycle) and a **“Retry now”** banner attempt to clear pending rows when connectivity/auth returns.

### Supabase / database baseline (compressed)

- **Remote drift (May 2026):** Hosted databases could diverge from repo migrations (legacy `proof_ledger` shapes, missing `simulated_chain_ledger`, missing or mismatched RPCs such as `simulate_chain_notarize` / `check_proof_status`). **Repair:** `supabase/migrations/20260509160000_repair_remote_prooflock_schema.sql` drops and recreates the canonical simulated-chain + `proof_ledger` surface and RPCs to match `20260503120000_prooflock_simulated_chain.sql`. **Destructive:** prior rows in old `proof_ledger` tables are not preserved across that repair.
- **Profiles gap:** Historic `auth.users` rows sometimes had no `public.profiles` row (trigger timing/failures), blocking `wallet_id` and ledger/RPC paths. **Repair:** `supabase/migrations/20260509200000_backfill_profiles_from_auth_users.sql` inserts missing profiles and ensures non-null `wallet_id`.
- **Flutter runtime:** `snapseal_app/lib/main.dart` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from **compile-time** `--dart-define` values (`AppConfig`). Optional defines include `USE_POLYGON_NOTARIZER` and `REQUIRE_HARDWARE_ATTESTATION` (the latter is **not yet wired** into control flow). **`scripts/write_flutter_dart_defines.py`** + **`scripts/sync_flutter_dart_defines.sh`** emit **filtered** `snapseal_app/dart_defines.json` so CLI-only secrets are not embedded; IDE launch can run sync pre-debug (see `snapseal_app/README.md`).
- **CLI / ops:** Bare `supabase` CLI does not load repo root `.env.local`; use `scripts/snapseal_supabase_pipeline.sh` (or source `.env.local`) for linked push and consistent env when operating against remote projects.

### Still not product-complete (pointers)

- **Polygon:** no working on-chain adapter; keep `USE_POLYGON_NOTARIZER=false`.
- **Hardware-backed signing:** native channel returns **developer-simulated** signatures until Secure Enclave / Keystore work lands.
- **Courier / verification UX:** service-layer extraction exists; manifest-style RPC-only courier surfaces are not implemented.
- **C2PA** and full **ProofLock manifest** assurance: see [[ProofLock_Refactor_Scope]] and [[ProofLock_Architectural_Manifest]].
- Automated tests improved (retry, dashboard, enclave channel) but remain **thinner than a production bar** on capture/crypto/sync edge cases.

Post-baseline reconciliation: [[Project_Audit_2026-05-11]].

## Provenance Tracking

* *Verified workflow and ops*: Confirmed against app routing and vault flow (`snapseal_app/lib/app/router/app_router.dart`, `snapseal_app/lib/ui/views/camera/camera_view.dart`, `snapseal_app/lib/domain/services/vault_service.dart`) (2026-05-09; seal + sync paths re-audited 2026-05-11, [[Project_Audit_2026-05-11]])
* *Database repairs*: Derived from `supabase/migrations/20260509160000_repair_remote_prooflock_schema.sql`, `supabase/migrations/20260509200000_backfill_profiles_from_auth_users.sql`, and `scripts/snapseal_supabase_pipeline.sh` (2026-05-09)

## Related Notes

* [[SnapSeal_Master_Blueprint]]
* [[ProofLock_Refactor_Scope]]
* [[ProofLock_Architectural_Manifest]]
* [[overview]]
* [[Project_Audit_2026-05-11]]
