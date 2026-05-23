---
tags: [index, navigation, llm_wiki]
summary: "Master catalog for the LLM Wiki."
---

# Wiki Index

Read this page first when answering questions about the wiki.

## Start here (current product)

| Page | When to read |
|------|----------------|
| [[Production_Transition_2026-05]] | **Ninth QA (2026-05-24)** — production dart-defines, courier lookup migrations, iOS privacy/export, 40/40 tests |
| [[Send_Proof_Courier_2026-05]] | **Send Proof (May 2026)** — PDF + share sheet, production web vault URL, live-host gate |
| [[FactLockCam_Product_Baseline_2026-05]] | **Canonical status** — verified workflow, Supabase ops, branding, open gaps |
| [[Polygon_Mainnet_Wiring_2026-05]] | **Eighth QA (2026-05-22)** — live Polygon mainnet on iPhone, secrets, sim fallback removed |
| [[App_Store_Prep_Capture_Seal_2026-05]] | **Fifth QA (2026-05-21)** — App Store legal bundle, multi-shot seal hardening, vault I/O fixes |
| [[Identity_Lifecycle_And_Data_Lineage]] | **Sixth QA (2026-05-21)** — Wallet lineage, EVM key rotation, JIT courier upload, archive placeholders |
| [[FactLockCam_Master_Blueprint]] | Application capabilities, finished vs unfinished, use cases |
| [[Polygon_Saga_Live]] | Live Polygon saga (Try 2): await relay at capture, local `chain_tx_hash`, certificate tx line |
| [[iOS_Device_Development_Workflow]] | Physical iOS build/install when `flutter run` attach fails |

## Sources

- [[Sample_Source]] - Bootstrap source describing the LLM Wiki workflow.
- [[ProofLock_Architectural_Manifest]] - ProofLock viability manifest and target system architecture (ingested raw source summary).
- [[Project_Audit_2026-05-11_Source]] - Immutable 2026-05-11 repo vs wiki audit (`raw/project_audit_2026-05-11.md`); see [[Project_Audit_2026-05-11]].

## Concepts

- [[LLM_Wiki_Pattern]] - The source-to-wiki compilation model.
- [[Production_Transition_2026-05]] - Ninth QA: production config, courier lookup migrations, iOS compliance, test suite.
- [[Send_Proof_Courier_2026-05]] - Send Proof: certificate PDF + courier link; utility positioning; production web vault URL.
- [[FactLockCam_Product_Baseline_2026-05]] - Verified hub/archive/capture workflow and compressed Supabase baseline (start here for FactLockCam status).
- [[Heavy_Metal_Design_System]] - FactLockCam titanium/mono/iris visual system for secure-hardware UI feel.
- [[Vault_Transactional_Journal]] - Sprint 2 WAL journal, transactional file persist, boot recovery, SQLite open hardening.
- [[Isolate_Lock_Coordinator]] - Sprint 4 cross-isolate UI lock stream, sidecar advisory locks, securing overlays.
- [[App_Store_Prep_Capture_Seal_2026-05]] - Fifth QA: legal bundle, multi-shot capture, vault promote I/O fixes.
- [[Identity_Lifecycle_And_Data_Lineage]] - Sixth QA: wallet history, EVM lineage on ledger, JIT courier, restore placeholders.
- [[Polygon_Mainnet_Wiring_2026-05]] - Eighth QA: live Polygon mainnet on iPhone, relay secrets, sim fallback removed.

## Analyses (active)

- [[Production_Transition_2026-05]] - Ninth QA: production dart-defines, courier migrations, iOS privacy/export, 40/40 tests (May 2026).
- [[Send_Proof_Courier_2026-05]] - Send Proof workflow, App Store utility rules, production web vault URL (May 2026).
- [[FactLockCam_Master_Blueprint]] - Current-state application blueprint: hub-first vault shell, archive actions, unfinished work, use cases.
- [[FactLockCam_Blueprints_14May2026]] - Layered technical blueprint (routing, DI, `proofLockFile`, Supabase RPC mapping); companion to [[MASTER_CONTEXT16MAY2026]].
- [[Polygon_Saga_Live]] - **Live** async Polygon saga (Try 2): anchor-relay, wallet/handler/monitor, ~2s device QA.
- [[Polygon_Try1_Postmortem]] - May 2026 Try 1 rollback audit, PR0 lazy-camera, Try 2 completion pointer.
- [[iOS_Device_Development_Workflow]] - Physical iOS 26 device QA: build/install vs `flutter run` VM attach failures.
- [[ProofLock_Refactor_Scope]] - Gap analysis from ProofLock manifesto to current FactLockCam implementation.
- [[Project_Audit_2026-05-11]] - Repo vs wiki reconciliation (seal pipeline, sync, native channel, tests, tooling).

## Analyses (archived snapshots)

Historical context only — prefer [[FactLockCam_Product_Baseline_2026-05]] for day-to-day status.

- [[MASTER_CONTEXT16MAY2026]] - Comprehensive snapshot (2026-05-16).
- [[MASTER_CONTEXT13MAY2026]] - Superseded by [[MASTER_CONTEXT16MAY2026]].
- [[Master_Context_11MAY2026]] - Superseded by [[MASTER_CONTEXT13MAY2026]].
- [[Master_Context_10MAY2026]] - Superseded by [[Master_Context_11MAY2026]].
- [[System_Context_Audit_2026-05-09]] - Superseded by [[FactLockCam_Product_Baseline_2026-05]].

## Maintenance

- [[overview]]
- [[glossary]]
- [[log]]
