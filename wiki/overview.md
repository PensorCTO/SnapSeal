---
tags: [overview, synthesis, llm_wiki]
summary: "Evolving high-level synthesis of the wiki's accumulated knowledge."
---

# Overview

## Core Synthesis

This wiki now tracks both the Karpathy-style LLM Wiki workflow and the SnapSeal application. SnapSeal is a Flutter **tamper-evident** local media vault (authenticity heuristics and risk reduction — not claims of absolute proof-of-truth) for authenticated capture, local sealing, and Supabase-backed proof surfaces (`check_proof_status`, simulated chain notarization, **`proof_ledger`** on the happy remote path), with Polygon still **planned** as the durable proof layer. **Capture is now dual-mode (`AcquisitionMode.photo` and `AcquisitionMode.video`)** routed through the same ProofLock-shaped seal pipeline. **For the current verified product workflow and a short Supabase repair narrative, start with [[SnapSeal_Product_Baseline_2026-05]].** For a **repo vs documentation reconciliation** after 2026-05-10 code changes, see [[Project_Audit_2026-05-11]]. For the **current** comprehensive architecture snapshot, see [[Master_Context_11MAY2026]] (the 2026-05-10 snapshot [[Master_Context_10MAY2026]] is retained for historical reference). A separate **ProofLock** architectural manifest ([[ProofLock_Architectural_Manifest]]) captures a **stricter target** (production hardware-backed signing, Polygon + C2PA, RPC-first ledger/courier); [[ProofLock_Refactor_Scope]] maps that target to the current codebase and estimates refactor phases.

## Current Themes

- Source-first knowledge compilation.
- LLM-maintained Markdown synthesis.
- Explicit provenance and related-note links.
- Cursor-native workflows for ingest, query, and lint.
- SnapSeal local-first media sealing for **photos and videos** with encrypted originals, thumbnails, SQLite metadata, Supabase **proof RPCs** (`check_proof_status`, `simulate_chain_notarize`), **`proof_ledger`**, and **pending-sync** reconciliation hooks.

## Open Questions

- How should **Polygon** proof submission replace or complement **`simulate_chain_notarize`** (`PolygonChainNotarizer` is still a stub; `USE_POLYGON_NOTARIZER` must stay false until implemented)?
- How aggressively should **`pending_sync` backoff** and error surfacing evolve now that a **background scheduler + manual “Retry now”** exist?
- Which user-facing **courier / `.plock`** flow should wrap `extractForCourier` / `CourierCrypto` without weakening local privacy guarantees?
- When replacing **simulated** `MethodChannel` signatures with **real** Secure Enclave / Keystore behavior, how should **`REQUIRE_HARDWARE_ATTESTATION`** gate capture or sync?

## Provenance Tracking

* *Initial architecture*: Derived from `raw/sample_llm_wiki_source.md` (2026-04-26)
* *SnapSeal application state*: Derived from `wiki/analyses/SnapSeal_Master_Blueprint.md` and `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md` (2026-04-30; baseline updated 2026-05-09; product wording aligned tamper-evident framing 2026-05-10; audit refresh 2026-05-11 per [[Project_Audit_2026-05-11]]; Phase 2 dual-mode capture snapshot 2026-05-11 per [[Master_Context_11MAY2026]])
* *ProofLock target architecture and refactor scope*: Derived from `wiki/sources/ProofLock_Architectural_Manifest.md` and `wiki/analyses/ProofLock_Refactor_Scope.md` (2026-05-03)

## Related Notes

* [[Sample_Source]]
* [[LLM_Wiki_Pattern]]
* [[SnapSeal_Product_Baseline_2026-05]]
* [[SnapSeal_Master_Blueprint]]
* [[ProofLock_Architectural_Manifest]]
* [[ProofLock_Refactor_Scope]]
* [[Project_Audit_2026-05-11]]
* [[Project_Audit_2026-05-11_Source]]
* [[Master_Context_11MAY2026]]
* [[Master_Context_10MAY2026]]
