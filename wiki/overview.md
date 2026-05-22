---
tags: [overview, synthesis, factlockcam, llm_wiki]
summary: "Big-picture view of ProofLockCleanup: FactLockCam product runtime, Supabase ledger/RPC surfaces, and this Karpathy-style LLM Wiki as canonical architecture memory."
---

# Overview

## Core Synthesis

`ProofLockCleanup` is a **dual** workspace: (1) the **FactLockCam** Flutter application (`factlockcam_app/`) with **local-first** encrypted media vault behavior and optional **Supabase** auth and proof ledger replication; (2) a **Karpathy-style LLM Wiki** (`wiki/`) that compiles durable architecture truth from `raw/` sources and ongoing reconciliation.

For **product status and verified workflow**, start at [[FactLockCam_Product_Baseline_2026-05]] (seventh QA **2026-05-22**: Polygon mainnet wiring + pending-sync fix — [[Polygon_Mainnet_Wiring_2026-05]]; sixth QA **2026-05-21**: identity lifecycle + wallet lineage — [[Identity_Lifecycle_And_Data_Lineage]]; fifth QA same day: App Store legal bundle, multi-shot capture seal hardening — [[App_Store_Prep_Capture_Seal_2026-05]]; fourth QA: Sprint 4 UI lock coordination; third QA: Sprint 2 journal + SQLite fix; second QA **2026-05-20**: proof progress, certificate tx hash, Polygon saga, app icon). For **local seal crash-safety**, see [[Vault_Transactional_Journal]]; for **archive UI during writes**, see [[Isolate_Lock_Coordinator]]. For **dated narrative architecture**, use [[MASTER_CONTEXT16MAY2026]] (archived snapshot — see index). For **layered technical breakdown** (routing, DI, `VaultService.proofLockFile`, RPC mapping, archive contract), use [[FactLockCam_Blueprints_14May2026]] (mirrors repo root `FactLockCam_Blueprints14May2026.md`). For **physical iOS device dev** (build/install when `flutter run` attach fails), use [[iOS_Device_Development_Workflow]]. For **Polygon async saga (live)**, use [[Polygon_Saga_Live]] and [[Polygon_Mainnet_Wiring_2026-05]]; Try 1 history in [[Polygon_Try1_Postmortem]]. For **gap-to-target** relative to the ProofLock manifest, see [[ProofLock_Refactor_Scope]].

Primary navigation: [[index]] · [[glossary]] · [[log]]

## Provenance Tracking

* *Page intent*: Standing orientation for humans and agents reading the wiki; updated 2026-05-22 after Polygon mainnet wiring + seventh QA pass.

## Related Notes

* [[index]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[MASTER_CONTEXT16MAY2026]]
* [[FactLockCam_Blueprints_14May2026]]
* [[FactLockCam_Master_Blueprint]]
* [[iOS_Device_Development_Workflow]]
* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[Identity_Lifecycle_And_Data_Lineage]]
* [[Vault_Transactional_Journal]]
* [[Isolate_Lock_Coordinator]]
* [[Polygon_Mainnet_Wiring_2026-05]]
* [[Polygon_Saga_Live]]
* [[Polygon_Try1_Postmortem]]
* [[ProofLock_Refactor_Scope]]
* [[glossary]]
* [[log]]
