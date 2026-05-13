---
tags: [analysis, architecture, factlockcam, prooflock, system_context]
summary: "Comprehensive architecture breakdown of the current repository state as of 2026-05-10, spanning app runtime, data planes, Supabase operations, and ProofLock gap alignment."
---

# Master Context (10 MAY 2026)

## Core Synthesis

This page is the first-class wiki artifact version of the 10 MAY 2026 architecture review. **For deltas after this date** (notably the **`VaultService.proofLockFile`** pipeline, **`check_proof_status` / `simulate_chain_notarize`**, simulated native **`signHash`**, **`proof_ledger` writes**, and **pending-sync scheduler + UI retry**), see [[Project_Audit_2026-05-11]]. The project remains a dual system: a functional FactLockCam Flutter app plus an LLM-maintained architecture wiki. Current verified product reality is a **local-first secure media wallet** with Supabase-backed proof surfaces and a confirmed logon → capture → **`/vault-dashboard`** happy path on a correctly migrated hosted project.

Architecturally, runtime behavior is split into: (1) Flutter presentation/auth/routing, (2) vault-domain orchestration for sealing and extraction, (3) local data persistence (encrypted files + thumbnails + SQLite + secure key storage), and (4) Supabase auth/ledger/RPC surfaces. The app’s strongest implemented area is the sealing flow (isolate-backed IO/hash behavior, **remote preflight + simulated chain + device-signature step (currently non-production TEE)**, AES-GCM encryption, thumbnail generation, metadata persistence, and pending-sync handling when remote writes fail). Hardening includes compensating local file cleanup if SQLite write fails during sealing and dashboard refresh behavior cleanup when camera is dismissed without a capture result.

On the data/infra side, the repository has moved beyond foundation migrations with targeted repair/backfill work for hosted Supabase drift. New migration surfaces rebuild proof-oriented tables (`simulated_chain_ledger`, `proof_ledger`) and restore RPCs (`check_proof_status`, `simulate_chain_notarize`) with `SECURITY DEFINER`, while a follow-up migration backfills `profiles` rows and missing `wallet_id` values from `auth.users`. Scripted operations have also been reinforced (`migration-list` in the Supabase pipeline script and a local hard-reset script for deterministic environment recovery).

The major architecture gap remains unchanged: **FactLockCam current-state != ProofLock target-state**. ProofLock-class guarantees still require native hardware-backed signing, production Polygon anchoring, C2PA packaging, and stronger verification/courier/reconciliation UX. As of this snapshot, the system is credible as a local-first sealed-media wallet with remote ledger replication, but not yet a full hardware-attested, chain-anchored provenance platform.

### Repository Architecture Map

- Product runtime: `factlockcam_app/`
- Database/migrations: `supabase/`
- Operational automation: `scripts/`
- Knowledge graph and synthesis: `wiki/`
- Immutable source inputs for wiki ingest: `raw/`

### Runtime Architecture (Current)

1. **Auth + Routing**
   - Supabase email OTP (Magic Number, 6-digit verify).
   - GoRouter guards based on session state.
   - Sign-out burns local wallet state before remote sign-out.
2. **Capture + Seal Pipeline**
   - Camera capture → isolate-backed file/hash operations.
   - When online: **`check_proof_status`**, **`signHash`** (native channel — **simulated** today), **`simulate_chain_notarize`** (or future Polygon adapter).
   - SHA-256 fingerprint + AES-GCM encryption + thumbnail generation.
   - Local persistence to filesystem + SQLite metadata update.
   - Supabase **`proof_ledger`** insert on success; failures leave `pending_sync` with backoff + background/UX retry hooks (see [[Project_Audit_2026-05-11]]).
3. **Dashboard + Retrieval**
   - Dashboard renders from local metadata + local thumbnails.
   - Courier extraction primitive verifies hash after decrypt.

### Data Planes

- **Local plane (source of truth for immediate UX):**
  - Encrypted originals, thumbnails, SQLite archive rows, secure vault key.
- **Remote plane (active-wallet ledger + proof scaffolding):**
  - Foundation: `profiles`, `seal_ledger`.
  - Repair-aligned proof surfaces: `simulated_chain_ledger`, `proof_ledger`.
  - RPC status/notarize scaffolding with PostgREST schema reload notification.

### Operations and Deployment Posture

- Supabase operations are script-first via `scripts/factlockcam_supabase_pipeline.sh`.
- `.env.local` loading through scripts avoids common bare-CLI credential drift.
- Local environment disaster recovery path exists in `scripts/supabase_local_hard_reset.sh`.
- Wiki indicates Supabase migration validation is integrated into CI.

### Risk and Gap Summary

- Hosted schema drift remains an operational risk without strict migration hygiene.
- Repair migration for proof tables is destructive for pre-existing legacy rows.
- `pending_sync` can still frustrate users when errors are non-recoverable or silent; **scheduler + “Retry now”** exist but are not a full reconciliation product (see [[Project_Audit_2026-05-11]]).
- Public-read ledger policy posture still needs explicit production review.
- No production Polygon anchoring, native TEE signing path, or C2PA integration yet.
- Automated test depth remains limited on critical crypto/sync/capture failure paths.

### Suggested Sequencing (Architecture-forward)

1. Lock schema/RPC contracts between app and Supabase.
2. Implement retry/reconciliation loop for `pending_sync`.
3. Expand deterministic tests for auth, sealing consistency, and sync edge cases.
4. Land native TEE signing MVP in capture flow.
5. Add Polygon write + persisted proof linkage.
6. Build user-facing verification/courier workflows.
7. Track C2PA as an advanced parallel provenance track.

## Provenance Tracking

* *Wiki navigation and canonical status framing*: Derived from `wiki/index.md`, `wiki/overview.md`, `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`, and `wiki/analyses/FactLockCam_Master_Blueprint.md` (2026-05-10)
* *ProofLock target and delta framing*: Derived from `wiki/sources/ProofLock_Architectural_Manifest.md` and `wiki/analyses/ProofLock_Refactor_Scope.md` (2026-05-10)
* *Recent implementation and ops updates*: Cross-checked against `factlockcam_app/lib/domain/services/vault_service.dart`, `factlockcam_app/lib/data/services/local_vault_storage.dart`, `factlockcam_app/lib/ui/views/vault_dashboard_view.dart`, `factlockcam_app/test/widget_test.dart`, `scripts/factlockcam_supabase_pipeline.sh`, `scripts/supabase_local_hard_reset.sh`, and Supabase migrations under `supabase/migrations/` (2026-05-10)
* *Source companion artifact*: This page mirrors and wiki-normalizes `Master_Context10MAY2026.md` (2026-05-10)

## Related Notes

* [[FactLockCam_Product_Baseline_2026-05]]
* [[FactLockCam_Master_Blueprint]]
* [[ProofLock_Refactor_Scope]]
* [[ProofLock_Architectural_Manifest]]
* [[overview]]
* [[log]]
* [[Project_Audit_2026-05-11]]

