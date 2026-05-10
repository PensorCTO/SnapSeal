---
tags: [overview, synthesis, llm_wiki]
summary: "Evolving high-level synthesis of the wiki's accumulated knowledge."
---

# Overview

## Core Synthesis

This wiki now tracks both the Karpathy-style LLM Wiki workflow and the emerging SnapSeal application. SnapSeal is a Flutter mathematical certainty wallet for authenticated media capture, local sealing, and active-wallet proof replication through Supabase, with Polygon still planned as the durable proof layer. **For the current verified product workflow and a short Supabase repair narrative, start with [[SnapSeal_Product_Baseline_2026-05]].** A separate **ProofLock** architectural manifest ([[ProofLock_Architectural_Manifest]]) captures a **stricter target** (hardware-backed signing, Polygon + C2PA, RPC-first ledger/courier); [[ProofLock_Refactor_Scope]] maps that target to the current codebase and estimates refactor phases.

## Current Themes

- Source-first knowledge compilation.
- LLM-maintained Markdown synthesis.
- Explicit provenance and related-note links.
- Cursor-native workflows for ingest, query, and lint.
- SnapSeal local-first media sealing with encrypted originals, thumbnails, SQLite metadata, and Supabase active-ledger sync.

## Open Questions

- How should Polygon proof submission and verification be integrated into the current local vault and Supabase active-ledger model?
- What retry/reconciliation model should clear `pending_sync` rows after offline or failed Supabase sync?
- Which user-facing export or courier workflow should expose verified decrypted media without weakening local privacy guarantees?
- When adopting ProofLock-class guarantees, what is the minimum viable **native TEE signing** and **capture pipeline** change set before marketing hardware-backed provenance?

## Provenance Tracking

* *Initial architecture*: Derived from `raw/sample_llm_wiki_source.md` (2026-04-26)
* *SnapSeal application state*: Derived from `wiki/analyses/SnapSeal_Master_Blueprint.md` and `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md` (2026-04-30; baseline updated 2026-05-09)
* *ProofLock target architecture and refactor scope*: Derived from `wiki/sources/ProofLock_Architectural_Manifest.md` and `wiki/analyses/ProofLock_Refactor_Scope.md` (2026-05-03)

## Related Notes

* [[Sample_Source]]
* [[LLM_Wiki_Pattern]]
* [[SnapSeal_Product_Baseline_2026-05]]
* [[SnapSeal_Master_Blueprint]]
* [[ProofLock_Architectural_Manifest]]
* [[ProofLock_Refactor_Scope]]
