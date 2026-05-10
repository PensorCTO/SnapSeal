# Master Context — 10 MAY 2026

## 1) Project identity and intent

`ProofLockCleanup` currently hosts a Flutter product named **SnapSeal**, positioned as a **tamper-evident** local media vault (authenticity heuristics and risk reduction—not claims of absolute proof-of-truth) for authenticated media capture, local sealing, and ledger replication. The repository also contains an LLM wiki used as the canonical synthesis layer for architecture, constraints, and ongoing alignment with a stricter future-state target called **ProofLock**.

At a high level:

- **SnapSeal (current reality):** local-first secure media handling + Supabase-backed active-wallet ledger.
- **ProofLock (target architecture):** hardware-backed signing, pre-flight proof-status RPC, Polygon anchoring, C2PA, and stronger courier/verification guarantees.

The canonical status anchor as of May 2026 is:
- `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md`

---

## 2) Repository architecture map

Primary top-level concerns:

- `snapseal_app/` — Flutter mobile app (core product runtime).
- `supabase/` — database schema, migrations, and local/remote Supabase project assets.
- `scripts/` — repeatable operational wrappers for Supabase and environment workflows.
- `wiki/` — LLM-maintained architecture knowledge base and decision context.
- `raw/` — immutable source material for wiki ingestion.

Conceptually, this repo is a **product + architecture-knowledge dual system**:

1. Build and operate the app/database.
2. Continuously synthesize and track architecture truth in the wiki.

---

## 3) Current system architecture (runtime view)

### 3.1 End-to-end user flow (verified happy path)

1. User logs in via Supabase email OTP ("Magic Number", 6-digit code).
2. User navigates to camera and captures media.
3. App runs sealing pipeline (hash -> encrypt -> thumbnail -> SQLite -> Supabase attempt).
4. User returns to dashboard where the new item appears.
5. If remote insert failed, item persists locally with `pending_sync = true`.

This workflow is explicitly validated in the May baseline page and remains the current product truth.

### 3.2 Runtime architecture slices

- **Presentation layer (Flutter UI + routing):**
  - Logon flow, dashboard, camera capture view.
  - GoRouter auth-gated navigation and Riverpod-driven state.

- **Domain/service layer:**
  - `VaultService` orchestrates sealing/extraction workflows.
  - Enforces cryptographic and consistency operations around assets.

- **Data/local persistence layer:**
  - Local encrypted asset files + thumbnails on device storage.
  - SQLite metadata for archive listing/state.
  - Secure key material in platform secure storage.

- **Remote sync/ledger layer (Supabase):**
  - Auth sessions and profile/wallet model.
  - Active-wallet ledger writes and proof-related RPC/table surfaces.

---

## 4) Flutter application architecture (current state)

### 4.1 Platform stack

- Framework: Flutter + Dart.
- State management: Riverpod.
- Navigation: GoRouter.
- Auth/session backend: Supabase.

### 4.2 App initialization and configuration

- Supabase initialization is compile-time define driven (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
- Unconfigured mode still allows shell rendering with auth guidance, preserving local dev usability.

### 4.3 Auth architecture

- Email OTP send via Supabase (`signInWithOtp`).
- OTP verify (6-digit `OtpType.email`) establishes session.
- Auth state changes drive route access.
- Sign-out path performs local wallet burn before ending remote session.

### 4.4 Capture and sealing architecture

The capture pipeline is performance-constrained and security-constrained:

- Camera acquisition in dedicated camera view.
- High-frequency visual operations are expected to be repaint-bounded.
- File IO and heavy operations offloaded with isolates.
- SHA-256 fingerprinting.
- AES-GCM encryption of originals.
- Thumbnail generation.
- Local persistence and metadata indexing.
- Supabase ledger sync attempt (non-blocking for local completion).
- Temp capture cleanup.

### 4.5 Dashboard architecture

- Reads archive list from SQLite, not from decrypted originals.
- Uses local thumbnail file paths.
- Displays abbreviated fingerprint and pending sync indicator.

Recent behavior hardening:
- Camera dismissal now avoids unnecessary dashboard provider invalidation/refetch.
- Widget coverage was added for this no-refresh-on-dismiss behavior.

### 4.6 Data consistency behavior

A compensating cleanup was added in vault flow:
- If SQLite upsert fails after asset files are written, encrypted and thumbnail files are deleted to keep local state coherent.

This improves local consistency semantics and narrows partial-write residue.

---

## 5) Data architecture

### 5.1 Local data model

Local state is split by concern:

- Encrypted originals and thumbnails on filesystem.
- Archive metadata in SQLite (`pending_sync` included).
- Encryption key in secure storage.

The local layer remains source-of-truth for immediate UX rendering.

### 5.2 Remote data model (Supabase)

Current + evolving relational surfaces include:

- `profiles` (user profile + wallet identity mapping).
- `seal_ledger` (foundation active-wallet ledger surface from early SnapSeal migration).
- `simulated_chain_ledger` + `proof_ledger` (repair-aligned ProofLock-style surfaces in newer migration path).

Important architectural reality:
- There is historical schema drift risk across hosted projects.
- New migrations were introduced to force canonical proof surface alignment and backfill profile/wallet gaps.

### 5.3 RPC architecture status

The repo now includes proof-status/notarize RPC definitions in repair migration:

- `check_proof_status(p_file_hash text)` -> ownership status string.
- `simulate_chain_notarize(p_file_hash text, p_device_signature text)` -> simulated tx hash.

These are `SECURITY DEFINER` and include post-migration schema reload notification for PostgREST metadata refresh.

---

## 6) Supabase operations architecture

### 6.1 Scripted workflow pattern

Operational practice is script-first rather than ad-hoc CLI:

- `scripts/snapseal_supabase_pipeline.sh` centralizes:
  - login/link/start/reset/lint
  - push-dry-run/push
  - config-push
  - app-run
  - migration-list (new command)

Reason:
- Wrapper loads repo `.env.local`, ensuring required remote DB credentials are present for migration operations.

### 6.2 Local environment recovery

`scripts/supabase_local_hard_reset.sh` was added for deterministic local reset:

- Verifies Docker/CLI.
- Stops stack without backup.
- Removes lingering containers/volumes with project naming patterns.
- Restarts stack and resets DB.
- Prints status for validation.

This is an ops reliability tool for broken local Supabase states.

### 6.3 CI posture

Wiki and scripts indicate migration validation exists in CI for Supabase-related changes, with optional/manual deployment pathing.

---

## 7) Knowledge architecture (LLM wiki system)

This repository uses a Karpathy-style LLM Wiki operating model:

- `raw/` immutable sources.
- `wiki/sources/` source summaries.
- `wiki/concepts/` stable concept pages.
- `wiki/analyses/` deep-dive architecture analysis.
- `wiki/index.md` as navigation root.
- `wiki/log.md` as append-only evolution trail.

Current architectural source-of-truth ordering for product state:

1. `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md` (current status anchor).
2. `wiki/analyses/SnapSeal_Master_Blueprint.md` (full current capability map).
3. `wiki/analyses/ProofLock_Refactor_Scope.md` (gap-to-target roadmap).
4. `wiki/sources/ProofLock_Architectural_Manifest.md` (target manifest synthesis).

`System_Context_Audit_2026-05-09` is now archived/superseded by the baseline concept page.

---

## 8) Security and integrity architecture snapshot

### 8.1 What is solid today

- Local file hashing + encrypted-at-rest media workflow.
- Secure-storage key usage.
- Off-main-thread heavy IO pathing.
- Basic wallet burn path.
- Auth-gated app routing.

### 8.2 What remains incomplete for "ProofLock-grade" guarantees

- Hardware-backed signing path not yet implemented in runtime.
- No production Polygon notarization writes from app path.
- No C2PA generation/embedding pipeline.
- `pending_sync` retry/reconciliation loop not implemented.
- Test depth still thin on crypto/capture/sync failure modes.

---

## 9) Architectural constraints and invariants

Current repo-level constraints reflected across rules/wiki/code:

- High-frequency capture/seal visuals should avoid jank (repaint boundaries).
- Heavy IO/crypto should stay off UI thread (`Isolate.run` pattern).
- "Seal completed" integrity semantics require both local and remote commits for full external notarization claims.
- If remote fails, local record should remain and be marked `pending_sync` until reconciled.
- Proof status and signing hardening are pre-flight concerns for future externally notarized guarantees.

---

## 10) Gap analysis: current state vs target state

### 10.1 Current architecture class

**Local-first secure media wallet with best-effort remote proof replication.**

### 10.2 Target architecture class (ProofLock)

**Hardware-attested capture-to-ledger proof system with chain anchoring and standards-compliant provenance packaging.**

### 10.3 Largest gap clusters

1. **Trust root gap:** software-only capture path vs native TEE-backed proof signing.
2. **Durable proof gap:** simulated or DB-only proof surfaces vs Polygon anchoring.
3. **Interoperability gap:** no C2PA artifact lifecycle.
4. **Reliability gap:** no retry worker/reconciliation UX for pending sync.
5. **Verification gap:** limited user-facing proof verification/courier workflows.
6. **Assurance gap:** insufficient automated coverage across critical paths.

---

## 11) Current risks and operational cautions

- Hosted Supabase schema drift can break RPC/table expectations across environments.
- Repair migration that recreates proof tables is destructive for prior legacy rows.
- Ledger `SELECT` was tightened to wallet-scoped authenticated reads (`supabase/migrations/20260510120000_tighten_ledger_select_rls.sql`); continue explicit privacy/security review for RPCs (`check_proof_status`), grants, and any verification UX.
- Partial failure windows still exist outside newly added local compensating cleanup logic.
- Product messaging must not overclaim hardware-backed provenance until native signing and attestation paths exist.

---

## 12) Practical architecture roadmap (from current baseline)

Recommended sequence based on current repo shape:

1. Stabilize schema contract naming and RPC semantics across app + DB.
2. Implement pending-sync retry/reconciliation worker and user affordances.
3. Expand deterministic tests for capture, local consistency, sync, and auth transitions.
4. Add native TEE signing MVP and bind it into capture pipeline.
5. Implement Polygon write + persistence + failure handling.
6. Add verification and courier user flows.
7. Integrate C2PA as a parallel advanced provenance track.

---

## 13) Executive summary

As of 10 MAY 2026, SnapSeal is a functioning local-first sealed-media wallet with Supabase-backed ledger replication and a verified logon->capture->dashboard happy path on migrated infrastructure. The architecture has matured in consistency and operations (compensating file cleanup, migration repair/backfill, scripted env workflows), but it remains pre-viability relative to the stricter ProofLock security bar. The core trajectory is clear: harden reliability, raise trust roots with hardware signing, and complete durable public proof/verification pathways.

