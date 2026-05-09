---
tags: [analysis, audit, project_status, snapseal, prooflock]
summary: "Comprehensive system context map of repository health, implementation status, infrastructure posture, and prioritized risks as of 2026-05-09."
---

# System Context Audit (2026-05-09)

## Core Synthesis

This repository is currently healthy and coherent across three coupled layers: (1) a Karpathy-style LLM Wiki knowledge system, (2) a Flutter SnapSeal app that is functionally usable for local-first sealing flows, and (3) a Supabase schema/pipeline that supports active-wallet replication plus early ProofLock simulation paths. The git working tree is clean on `main`, wiki validation passes, and the current Flutter tests pass.

The product state is "operational foundation, not market-complete provenance." The local capture pipeline is real and implemented (camera capture, isolate-backed hashing/file operations, AES-GCM encryption, local thumbnail + SQLite archive index, burn and extraction paths). Supabase-backed auth and ledger writes are in place, including ProofLock-oriented pre-flight and simulated chain RPCs. However, enterprise-grade claims remain gated by unfinished items: durable Polygon anchoring, richer retry/reconciliation for pending sync, stronger end-to-end test coverage, and complete UX/workflows around verification/courier export.

### Repository Health Snapshot

- **Branch/status:** `main` tracking `origin/main`, no uncommitted changes at audit time.
- **Recent trajectory:** commits show active work in OTP auth, ProofLock refactor direction, and Supabase setup.
- **Knowledge system:** `manifest.md` has all listed raw sources marked `COMPILED`.
- **Validation:** `python3 scripts/wiki_ingest.py --validate` returns all wiki pages `[OK]`.
- **App tests:** `flutter test` in `snapseal_app` passes both current tests.

### System Topology (Current)

- **Wiki control plane:** `raw/` immutable inputs -> `manifest.md` ingestion state -> `wiki/` synthesized knowledge graph.
- **App runtime:** `snapseal_app/lib/main.dart` conditionally initializes Supabase from Dart defines and mounts Riverpod app shell.
- **Auth + routing:** OTP authentication drives GoRouter redirects among `/logon`, `/dashboard`, `/camera`.
- **Capture + vault path:** camera capture -> isolate hash/read -> native signature attempt -> simulated notarization/RPC insert path -> AES-GCM local storage + SQLite metadata + pending sync bookkeeping.
- **Backend plane:** Supabase `profiles`, `seal_ledger`, `simulated_chain_ledger`, and `proof_ledger` tables with RLS and RPC helpers.

### Implementation Status Map

#### 1) Flutter App

- **Working now**
  - Config-aware Supabase bootstrap with graceful non-configured local shell behavior.
  - 6-digit Magic Number (email OTP) send/verify flow.
  - Dashboard list from SQLite archive metadata and local thumbnail files.
  - Camera capture and seal flow with repaint boundaries in camera/sealing layers.
  - Local burn flow removing SQLite rows, vault files, and secure key material.
  - Service-level decrypted extraction with SHA-256 re-verification.

- **Partially complete**
  - Pending remote sync flag exists and is set on recoverable failures.
  - ProofLock conflict handling exists (`check_proof_status` pre-flight + conflict exception).
  - Native enclave bridge is defined (`MethodChannel`) and test-injectable, but production native handlers/attestation details are still maturing.

- **Missing or incomplete**
  - No end-user retry/reconciliation workflow for `pending_sync`.
  - No full courier/export UI; extraction is currently service-layer only.
  - No full transactional rollback across local file writes + SQLite upsert if later steps fail.
  - Test suite is still narrow (2 tests, mostly smoke-level).

#### 2) Supabase + Data Model

- **Working now**
  - `profiles` table with opaque generated `wallet_id`.
  - Active-ledger and ProofLock simulation tables with indexes and RLS enabled.
  - RPCs implemented for `check_proof_status` and `simulate_chain_notarize`.
  - Pipeline script supports local stack lifecycle, lint, reset, push dry-run/push, config push, and app-run with Dart defines.

- **Partially complete**
  - ProofLock-like semantics are simulated via Supabase RPC/table flow rather than true chain anchoring.
  - Public-read policies exist for some ledgers; this matches transparency intent but still needs deployment-time privacy/security validation.

- **Missing or incomplete**
  - Real Polygon write path is not yet integrated.
  - Final courier/RPC-only unlock model from target architecture is not fully implemented.
  - Production-grade operational playbook for retries/monitoring is not yet encoded in code/workers.

#### 3) Wiki + Knowledge Graph

- **Working now**
  - Core wiki schema is followed across existing pages.
  - Relevant analyses already capture blueprint and ProofLock gap landscape.
  - Index, overview, glossary, and log are maintained and coherent.

- **Needs ongoing upkeep**
  - Keep blueprint and this audit synchronized with rapid app/schema changes.
  - Add future source ingests to `manifest.md` before synthesis passes.

### Architecture Alignment vs ProofLock Target

- **Aligned today**
  - Local-first vault workflow.
  - Isolate usage in expensive crypto/file operations.
  - Pre-flight status checking and non-destructive conflict handling surface.
  - TEE bridge abstraction introduced in app architecture.

- **Not yet aligned**
  - Durable public proof finality via Polygon.
  - Complete hardware-backed provenance hardening and attestation-grade claims.
  - End-to-end operational guarantees for eventual remote consistency after offline capture.

### Risk Register (Prioritized)

1. **Proof finality gap:** without live Polygon anchoring, durable-proof claims remain provisional.
2. **Sync debt risk:** assets can stay `pending_sync` indefinitely without retry worker/manual reconcile UX.
3. **Integrity edge cases:** local persistence is sequential; partial local failures may leave inconsistent artifacts.
4. **Security posture drift risk:** broad read policies require intentional deployment governance and regular review.
5. **Regression risk:** limited test breadth on capture/crypto/sync paths increases change fragility.

### Immediate Priority Backlog (Recommended)

1. Implement pending-sync reconciliation loop (background or explicit retry action) and surface status in UI.
2. Introduce atomic local transaction strategy (or compensating rollback) across file + DB writes.
3. Expand tests for auth controller, vault pipeline, sync edge cases, and Supabase repository behavior.
4. Finalize native signing integration details and platform-specific secure key lifecycle.
5. Replace simulated notarization path with staged Polygon integration and recorded transaction proof.

## Provenance Tracking

* *Repository and git status*: Derived from `git status --short --branch` and `git log --oneline -n 12` (2026-05-09)
* *Wiki health and structure*: Derived from `manifest.md`, `wiki/index.md`, `wiki/overview.md`, `wiki/log.md`, and `python3 scripts/wiki_ingest.py --validate` (2026-05-09)
* *App architecture and behavior*: Derived from `snapseal_app/lib/main.dart`, `snapseal_app/lib/app/router/app_router.dart`, `snapseal_app/lib/ui/controllers/auth_controller.dart`, `snapseal_app/lib/ui/views/logon_view.dart`, `snapseal_app/lib/ui/views/dashboard_view.dart`, `snapseal_app/lib/ui/views/camera/camera_view.dart`, `snapseal_app/lib/domain/services/vault_service.dart`, `snapseal_app/lib/core/crypto/cipher_engine.dart`, `snapseal_app/lib/data/local/vault_database.dart`, and `snapseal_app/lib/data/services/local_vault_storage.dart` (2026-05-09)
* *Supabase schema and operations*: Derived from `supabase/migrations/20260428013509_snapseal_foundation.sql`, `supabase/migrations/20260503120000_prooflock_simulated_chain.sql`, `supabase/README.md`, and `scripts/snapseal_supabase_pipeline.sh` (2026-05-09)
* *Test status*: Derived from `flutter test` and files under `snapseal_app/test/` (2026-05-09)
* *Historical synthesis context*: Derived from `wiki/analyses/SnapSeal_Master_Blueprint.md` and `wiki/analyses/ProofLock_Refactor_Scope.md` (2026-05-09)

## Related Notes

* [[SnapSeal_Master_Blueprint]]
* [[ProofLock_Refactor_Scope]]
* [[ProofLock_Architectural_Manifest]]
* [[overview]]
* [[glossary]]
