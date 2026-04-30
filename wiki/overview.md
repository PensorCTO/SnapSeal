---
tags: [overview, synthesis, llm_wiki]
summary: "Evolving high-level synthesis of the wiki's accumulated knowledge."
---

# Overview

## Core Synthesis

This wiki now tracks both the Karpathy-style LLM Wiki workflow and the emerging SnapSeal application. SnapSeal is a Flutter mathematical certainty wallet for authenticated media capture, local sealing, and active-wallet proof replication through Supabase, with Polygon still planned as the durable proof layer.

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

## Provenance Tracking

* *Initial architecture*: Derived from `raw/sample_llm_wiki_source.md` (2026-04-26)
* *SnapSeal application state*: Derived from `wiki/analyses/SnapSeal_Master_Blueprint.md` (2026-04-30)

## Related Notes

* [[Sample_Source]]
* [[LLM_Wiki_Pattern]]
* [[SnapSeal_Master_Blueprint]]
