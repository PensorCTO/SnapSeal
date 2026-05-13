---
tags: [source_summary, prooflock, architecture]
summary: "Source summary for the ProofLock viability manifest and target system architecture."
---

# ProofLock Architectural Manifest

## Core Synthesis

This source is an architectural manifest for **ProofLock** viability and system design. It argues the product is viable only if **biometric/virtual-camera injection** is addressed: **software-only hashing in pure Flutter is explicitly rejected** as insufficient for enterprise and spoofing resistance. The approved direction pairs **Flutter with native platform channels** so **Secure Enclave (iOS) / hardware-backed Keystore (Android)** can sign or bind proofs derived from media hashes, improving defensibility (the text cites FRE 901 framing). A **dual-layer** durable story combines **Polygon anchoring** with **C2PA** via FFI for industry-standard portable metadata, accepting larger binaries and Rust-to-Dart bridging cost.

The target **C4-style flow** is: UI (Riverpod) feeds isolates for SHA-256 hashing, native TEE signs the hash, the client calls Supabase **RPC** for pre-flight and ledger writes, and the client anchors on **Polygon** then records the transaction back through RPC. The implementation spec sketches **Postgres** objects (`proof_ledger`, `courier_packages`), **indexes**, **RLS** (including **no direct SELECT** on courier tables—RPC-only reads via `SECURITY DEFINER`), and a **`check_proof_status`** RPC returning ownership states (`new`, `anonymous`, `owned_by_me`, `owned_by_other`). It also proposes a **layered Flutter tree** (`presentation/capture`, fingerprinting UI with `RepaintBoundary`, notarization, verification) and a **`proofLockFile`**-style pipeline: isolate hash → RPC pre-flight → hardware sign → Polygon notarize → encrypt to vault → insert ledger → delete cleartext original.

**Note:** The manifest’s example vault encryption (“XOR + SHA256” / `VaultEncryptionHandler`) is a **spec-level placeholder** and does **not** match the current FactLockCam implementation (AES-GCM + local secure storage). The wiki treats that line as manifesto intent, not as current repo fact—see [[ProofLock_Refactor_Scope]].

## Provenance Tracking

* *Claims and structure*: Derived from `raw/prooflock_architectural_manifest.md` (2026-05-03)

## Related Notes

* [[ProofLock_Refactor_Scope]]
* [[FactLockCam_Master_Blueprint]]
* [[overview]]
* [[glossary]]
