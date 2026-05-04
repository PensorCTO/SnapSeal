---
tags: [analysis, prooflock, refactor_scope, snapseal]
summary: "Maps the ProofLock architectural manifest to current SnapSeal code and estimates phased refactor effort."
---

# ProofLock Refactor Scope

## Core Synthesis

The **ProofLock manifest** ([[ProofLock_Architectural_Manifest]]) describes a **target architecture** that is **significantly ahead** of the current **SnapSeal** codebase ([[SnapSeal_Master_Blueprint]]). Today’s app already delivers a credible **local-first wallet**: capture → isolate read/hash path → **AES-GCM** vault encryption with a key in secure storage → SQLite + thumbnails → optional **Supabase `seal_ledger` insert** with `pending_sync` on failure. That stack matches part of the manifest’s performance discipline (isolates, repaint boundaries in capture UI) but **does not** implement the manifest’s **viability gate**: **hardware-backed signing**, **Polygon notarization**, **C2PA**, **`check_proof_status` pre-flight RPC**, or the **`proof_ledger` / RPC-only courier** schema.

Refactor effort is therefore **large and multi-track**, not a single feature. A practical sequencing is: (1) **docs and contracts** frozen in wiki + ADR-style notes, (2) **Supabase evolution** (new tables/RPC, RLS, indexes) without breaking existing wallets, (3) **vault pipeline hardening** (atomicity, pending-sync worker), (4) **native enclave channel MVP** (sign hash or bind attestation), (5) **Polygon write path** + persistence of `polygon_tx_hash`, (6) **C2PA** as a parallel track, (7) **verification / public read** UX and tests.

```mermaid
flowchart LR
  subgraph today [SnapSeal_Today]
    Cam[Camera_Capture]
    Iso[Isolate_IO_Hash]
    Vault[VaultService_AESGCM]
    Sql[SQLite_Metadata]
    Led[seal_ledger_Insert]
    Cam --> Iso --> Vault --> Sql --> Led
  end
  subgraph target [ProofLock_Target]
    Pre[RPC_check_proof_status]
    Tee[Native_TEE_Sign]
    Poly[Polygon_Anchor]
    RpcW[RPC_Record_Tx]
    C2pa[C2PA_Metadata]
    Iso2[Isolate_Hash]
    Iso2 --> Pre --> Tee --> Poly --> RpcW
    Tee --> C2pa
  end
  today -.->|refactor_gap| target
```

### Manifest requirement → current surface

| Manifest element | Current repo | Gap |
| :--- | :--- | :--- |
| Isolate SHA-256 + UI perf | `VaultService` uses `Isolate.run` for temp file read/delete; hashing via `CipherEngine` | Align naming/docs with manifest; optional dedicated hash worker file |
| Pre-flight `check_proof_status` | No RPC; duplicate detection is implicit via DB unique + app handling | New migration, client call before seal completes |
| Hardware enclave signing | No `MethodChannel` / Swift / Kotlin signing path | New plugins or `flutter` platform code, key lifecycle, attestation story |
| Polygon notarization | `polygon_tx_hash` column exists; **never written** | Wallet/signing model, RPC or direct chain client, gas/error UX |
| `proof_ledger` vs `seal_ledger` | `seal_ledger` + `profiles` | Migration/rename or parallel table + backfill strategy |
| Courier black-box (`courier_packages`, no SELECT) | `extractForCourier` is local-only; no Supabase courier table | Schema + SECURITY DEFINER RPCs + policy review |
| C2PA FFI | Not present | FFI build, licensing, binary size, CI matrix |
| “Seal complete = SQLite + Supabase” (capture rule) | Local writes succeed even if Supabase fails (`pending_sync`) | Product decision: tighten vs keep offline-first; implement retry worker |

**Security note:** The manifest’s example “XOR + SHA256” vault encryption is **not** implemented in SnapSeal (AES-GCM is). Any future doc or porting from the manifest must **not** treat XOR as current truth.

## Phased effort (indicative)

Rough calendar estimates for a **small team**; actuals depend on chain UX, attestation depth, and App Store review.

| Phase | Scope | Order-of-magnitude |
| :--- | :--- | :--- |
| 1 | Wiki + API contracts + migration naming (`proof_ledger`, RPC signatures) | 0.5–1 day |
| 2 | Supabase: indexes, RLS, `check_proof_status`, courier RPC sketch | 2–4 days + security review |
| 3 | Vault: transactional local writes, `pending_sync` retry/reconciliation | 3–5 days |
| 4 | Native TEE signing MVP (iOS + Android) | 1–2 weeks MVP; more for hardening |
| 5 | Polygon submission + persist hash + failure modes | 1–2 weeks |
| 6 | C2PA / FFI | 1–2+ weeks |
| 7 | Tests (auth, vault, RPC, chain mocks), release checklist | 1+ week |

**Overall:** expect **several weeks to a few months** of focused work to reach manifest parity, not days.

## Provenance Tracking

* *Manifest claims and target flow*: Derived from `raw/prooflock_architectural_manifest.md` via [[ProofLock_Architectural_Manifest]] (2026-05-03)
* *Current implementation mapping*: Derived from `snapseal_app/lib/domain/services/vault_service.dart`, `snapseal_app/lib/data/supabase/seal_ledger_repository.dart`, `snapseal_app/lib/main.dart`, `snapseal_app/lib/ui/controllers/auth_controller.dart`, and `supabase/migrations/20260428013509_snapseal_foundation.sql` (2026-05-03)

## Related Notes

* [[ProofLock_Architectural_Manifest]]
* [[SnapSeal_Master_Blueprint]]
* [[overview]]
* [[glossary]]
