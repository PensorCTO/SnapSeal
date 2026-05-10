---
tags: [concept, snapseal, baseline, supabase, product_status]
summary: "Authoritative May 2026 baseline: verified primary workflow and compressed Supabase repair/backfill narrative with migration pointers."
---

# SnapSeal Product Baseline (2026-05)

## Core Synthesis

As of this baseline, the **primary product workflow is verified end-to-end** on a correctly migrated hosted Supabase project: **logon** (email OTP) → **choose capture** → **take picture** → **return to dashboard** with the sealed asset listed as completed (local vault + ledger path when sync succeeds). Detail beyond this snapshot lives in [[SnapSeal_Master_Blueprint]]; ProofLock-class gaps and phased work remain in [[ProofLock_Refactor_Scope]].

### Verified workflow (happy path)

1. Authenticate via Magic Number (6-digit email OTP) when Supabase is configured with Dart defines.
2. Navigate to capture; capture still image; sealing pipeline runs (hash, encrypt, thumbnail, SQLite, Supabase attempts).
3. Land on dashboard with the new archive row visible (thumbnail + fingerprint; `(pending)` only if remote sync did not complete).

### Supabase / database baseline (compressed)

- **Remote drift (May 2026):** Hosted databases could diverge from repo migrations (legacy `proof_ledger` shapes, missing `simulated_chain_ledger`, missing or mismatched RPCs such as `simulate_chain_notarize` / `check_proof_status`). **Repair:** `supabase/migrations/20260509160000_repair_remote_prooflock_schema.sql` drops and recreates the canonical simulated-chain + `proof_ledger` surface and RPCs to match `20260503120000_prooflock_simulated_chain.sql`. **Destructive:** prior rows in old `proof_ledger` tables are not preserved across that repair.
- **Profiles gap:** Historic `auth.users` rows sometimes had no `public.profiles` row (trigger timing/failures), blocking `wallet_id` and ledger/RPC paths. **Repair:** `supabase/migrations/20260509200000_backfill_profiles_from_auth_users.sql` inserts missing profiles and ensures non-null `wallet_id`.
- **Flutter runtime:** `snapseal_app/lib/main.dart` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from **compile-time** `--dart-define` values (`AppConfig`), not from checking repo `.env.local` by default.
- **CLI / ops:** Bare `supabase` CLI does not load repo root `.env.local`; use `scripts/snapseal_supabase_pipeline.sh` (or source `.env.local`) for linked push and consistent env when operating against remote projects.

### Still not product-complete (pointers)

- No production Polygon anchoring; simulated chain remains a stand-in.
- No user-facing `pending_sync` retry/reconciliation loop.
- Thin automated tests on capture/crypto/sync paths.
- ProofLock manifest bar (TEE signing, C2PA, courier hardening): see [[ProofLock_Refactor_Scope]] and [[ProofLock_Architectural_Manifest]].

## Provenance Tracking

* *Verified workflow and ops*: Confirmed against app routing and vault flow (`snapseal_app/lib/app/router/app_router.dart`, `snapseal_app/lib/ui/views/camera/camera_view.dart`, `snapseal_app/lib/domain/services/vault_service.dart`) (2026-05-09)
* *Database repairs*: Derived from `supabase/migrations/20260509160000_repair_remote_prooflock_schema.sql`, `supabase/migrations/20260509200000_backfill_profiles_from_auth_users.sql`, and `scripts/snapseal_supabase_pipeline.sh` (2026-05-09)

## Related Notes

* [[SnapSeal_Master_Blueprint]]
* [[ProofLock_Refactor_Scope]]
* [[ProofLock_Architectural_Manifest]]
* [[overview]]
