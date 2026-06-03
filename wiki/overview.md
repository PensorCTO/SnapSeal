---
tags: [overview, synthesis, factlockcam, llm_wiki]
summary: "Big-picture view of ProofLockCleanup: FactLockCam product runtime, Supabase ledger/RPC surfaces, and this Karpathy-style LLM Wiki as canonical architecture memory."
---

# Overview

## Core Synthesis

`ProofLockCleanup` is a **dual** workspace: (1) the **FactLockCam** Flutter application (`factlockcam_app/`) with **local-first** encrypted media archive behavior and optional **Supabase** auth and proof ledger replication; (2) a **Karpathy-style LLM Wiki** (`wiki/`) that compiles durable architecture truth from `raw/` sources and ongoing reconciliation.

**Open work (2026-06-03):** None blocking custody/legal or presentation QA — hosted Terms deployed ([[Data_Custody_And_Backup_Model_2026]]); archive hub shell layout polish device-verified ([[UI_Layout_Polish_2026-06]]). Continue App Store / TestFlight cadence per [[Production_Transition_2026-05]].

For **product status and verified workflow**, start at [[FactLockCam_Product_Baseline_2026-05]] (twenty-first pass **2026-06-03**: responsive Heavy Metal hub/archive/inspector/account layouts, **90/90** tests — [[UI_Layout_Polish_2026-06]]; twentieth pass same day: key custody scenario matrix — [[Data_Custody_And_Backup_Model_2026]] — keys-only `.factlock`, Lock/Burn distinction, hosted legal + in-app disclaimers, **82/82** tests; nineteenth pass: subscription foundation — [[Archive_Subscription_Tiers_2026]] — local SQLite quota pre-flight, free-tier video cap, onboarding/paywall disclaimer; eighteenth pass: compliance refactor — [[Compliance_Refactor_2026-06]] — `/archive`, `disclaimers.dart`; seventeenth pass **2026-06-02**: **dual-layer Archive quota** — byte storage/egress telemetry + credit pro proofs/verification credits, camera gas gauge, Egress Pass badge, device QA **72/72** — [[Archive_Quota_Telemetry_2026-06]]; sixteenth QA **2026-05-30**: **archive owner UX** — Download Media, Send Proof certificate metadata from asset, View/Play labels, debug `ENABLE_PROOF_LINKS` — [[Archive_Owner_UX_2026-05]]; fifteenth QA **2026-05-30**: **App Store hardening** — Secure Enclave / Keystore `signHash`, `ENABLE_PROOF_LINKS` gate, sync/delete/DI remediation, `run_device.sh`, **55/55** tests — [[App_Store_Hardening_2026-05]]; fourteenth QA **2026-05-29**: **decoupled public web** — Astro sales pitch at `factlockcam.com`, courier-only Flutter gate at `archive.factlockcam.com`, browser capture disabled, Cloudflare Pages deploy scripts, **52/52** tests — [[Web_Deployment_Architecture_2026-05]]; thirteenth QA same day: **sovereign multi-key lifecycle** — `.factlock` export/import (EVM + archive AES), zero-knowledge lock, `/restore` gate, typed burn confirmation, decoupled compliance URLs — [[Sovereign_Key_Lifecycle_2026-05]]; twelfth QA **2026-05-27**: **cloud archive wiring** — `factlock_vault` bucket, `VaultSyncCoordinator` post-seal sync, smoke test + owner QA pass — [[Cloud_Vault_Wiring_2026-05]]; eleventh QA **2026-05-24**: **UI polish** — shared logo banner, Account heavy-metal tiles, chronology scroll clarity, **41/41** tests — [[UI_Polish_Hub_Archive_2026-05]]; tenth QA same day: **App Store remediation** — `WEB_ARCHIVE_BASE_URL`, courier archive indices pushed, TestFlight-first posture — [[App_Store_Remediation_2026-05]]; ninth QA same day: production dart-defines, courier lookup migrations, iOS privacy/export, **40/40** tests — [[Production_Transition_2026-05]]; eighth QA **2026-05-22**: **live Polygon mainnet on physical iPhone** — [[Polygon_Mainnet_Wiring_2026-05]]; seventh QA same day: relay wiring + pending-sync fix; sixth QA **2026-05-21**: identity lifecycle + wallet lineage — [[Identity_Lifecycle_And_Data_Lineage]]; fifth QA same day: App Store legal bundle, multi-shot capture seal hardening — [[App_Store_Prep_Capture_Seal_2026-05]]; fourth QA: Sprint 4 UI lock coordination; third QA: Sprint 2 journal + SQLite fix; second QA **2026-05-20**: proof progress, certificate tx hash, Polygon saga, app icon). For **Send Proof / courier** (certificate PDF + share sheet, production **`WEB_ARCHIVE_BASE_URL`**, Ngrok OK for TestFlight, live-host gate before App Store review), see [[Send_Proof_Courier_2026-05]]. For **local seal crash-safety**, see [[Archive_Transactional_Journal]]; for **archive UI during writes**, see [[Isolate_Lock_Coordinator]]. For **dated narrative architecture**, use [[MASTER_CONTEXT16MAY2026]] (archived snapshot — see index). For **layered technical breakdown** (routing, DI, `VaultService.proofLockFile`, RPC mapping, archive contract), use [[FactLockCam_Blueprints_14May2026]] (mirrors repo root `FactLockCam_Blueprints14May2026.md`). For **physical iOS device dev** (build/install when `flutter run` attach fails), use [[iOS_Device_Development_Workflow]]. For **Polygon async saga (live mainnet)**, use [[Polygon_Saga_Live]] and [[Polygon_Mainnet_Wiring_2026-05]]; Try 1 history in [[Polygon_Try1_Postmortem]]. For **gap-to-target** relative to the ProofLock manifest, see [[ProofLock_Refactor_Scope]].

Primary navigation: [[index]] · [[glossary]] · [[log]]

## Provenance Tracking

* *Page intent*: Standing orientation for humans and agents reading the wiki; updated 2026-06-03 after UI layout polish QA pass + key custody matrix.

## Related Notes

* [[UI_Layout_Polish_2026-06]]
* [[Data_Custody_And_Backup_Model_2026]]
* [[Archive_Subscription_Tiers_2026]]
* [[Compliance_Refactor_2026-06]]
* [[Archive_Quota_Telemetry_2026-06]]
* [[App_Store_Hardening_2026-05]]
* [[Web_Deployment_Architecture_2026-05]]
* [[Sovereign_Key_Lifecycle_2026-05]]
* [[Cloud_Vault_Wiring_2026-05]]
* [[UI_Polish_Hub_Archive_2026-05]]
* [[App_Store_Remediation_2026-05]]
* [[Production_Transition_2026-05]]
* [[Send_Proof_Courier_2026-05]]
* [[index]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[MASTER_CONTEXT16MAY2026]]
* [[FactLockCam_Blueprints_14May2026]]
* [[FactLockCam_Master_Blueprint]]
* [[iOS_Device_Development_Workflow]]
* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[Identity_Lifecycle_And_Data_Lineage]]
* [[Archive_Transactional_Journal]]
* [[Isolate_Lock_Coordinator]]
* [[Polygon_Mainnet_Wiring_2026-05]]
* [[Polygon_Saga_Live]]
* [[Polygon_Try1_Postmortem]]
* [[ProofLock_Refactor_Scope]]
* [[glossary]]
* [[log]]
