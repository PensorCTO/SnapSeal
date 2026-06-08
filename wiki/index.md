---
tags: [index, navigation, llm_wiki]
summary: "Master catalog for the LLM Wiki."
---

# Wiki Index

Read this page first when answering questions about the wiki.

## Start here (current product)

| Page | When to read |
|------|----------------|
| [[FactLockCam_Product_Baseline_2026-05]] | **Canonical status** — **100% Pre-Connect Submission Ready** + **twenty-ninth QA passed (2026-06-08)**; Unified Archive Studio + Certificate Studio |
| [[Unified_Archive_Studio_2026-06]] | **Twenty-ninth pass QA passed (2026-06-08)** — four-tile hub, Certificate Studio, courier decommission, hub backdrop auto-play; **98/98** tests |
| [[Zero_Click_Capture_2026-06]] | **Twenty-eighth pass (2026-06-06)** — mobile Secure Comm capture; **superseded** by decommission (orphaned source) |
| [[Secure_Communications_Console_2026-06]] | **Twenty-seventh pass (2026-06-05)** — web `/courier` phased console; **superseded** — `/courier` redirects to gate |
| [[Institution_Grade_Payload_Seal_Backlog]] | **Foundation (2026-06-04)** — MIME-agnostic pipeline deferred; consumer stays Picture/Video only |
| [[UI_Layout_Polish_2026-06]] | **Twenty-first pass QA passed (2026-06-03)** — responsive hub/archive/inspector/account layouts; landscape overflow fix; **90/90** tests |
| [[Data_Custody_And_Backup_Model_2026]] | **Twentieth pass QA passed (2026-06-03)** — Keys-only `.factlock`; scenario matrix; hosted Terms deployed; **82/82** tests |
| [[Archive_Subscription_Tiers_2026]] | **Nineteenth pass (2026-06-03)** — local SQLite quota pre-flight, free-tier 50 MB video stop, subscription onboarding + paywall disclaimer, compliant tier labels |
| [[UGC_Safety_Reporting_2026-06]] | **Twenty-fourth pass (2026-06-05)** — Guideline 1.2 reporting/blocking, async `courier-content-scan`, Archive service-layer rename |
| [[Compliance_Refactor_2026-06]] | **Eighteenth pass (2026-06-03)** — `/archive` route, `disclaimers.dart`, Archive UI rename, marketing compliance test, Account key-custody dialog UX |
| [[Archive_Quota_Telemetry_2026-06]] | **Seventeenth pass (2026-06-02)** — dual-layer quota: byte telemetry + credit metering (gas gauge, Egress Pass, verification modal); **72/72** tests; migrations pushed |
| [[Archive_Owner_UX_2026-05]] | **Sixteenth QA (2026-05-30)** — Download Media, Send Proof metadata, View/Play labels, debug proof-links gate |
| [[App_Store_Hardening_2026-05]] | **Fifteenth QA (2026-05-30)** — manifest remediation: hardware signing, ENABLE_PROOF_LINKS gate, sync/delete/DI hardening, 55/55 tests |
| [[Web_Deployment_Architecture_2026-05]] | **Fourteenth QA (2026-05-29)** — factlockcam.com sales pitch + archive courier-only gate; Cloudflare Pages deploy |
| [[Sovereign_Key_Lifecycle_2026-05]] | **Thirteenth QA (2026-05-29)** — multi-key `.factlock` backup/restore, brick mode, burn hardening, 52/52 tests |
| [[Cloud_Vault_Wiring_2026-05]] | **Twelfth QA (2026-05-27)** — `factlock_vault` bucket, post-seal cloud sync, VaultSyncCoordinator, smoke test |
| [[UI_Polish_Hub_Archive_2026-05]] | **Eleventh QA (2026-05-24)** — shared logo banner, Account hub tiles, chronology scroll clarity, 41/41 tests |
| [[App_Store_Remediation_2026-05]] | **Tenth QA (2026-05-24)** — WEB_ARCHIVE_BASE_URL rename, courier archive indices pushed, TestFlight posture |
| [[Production_Transition_2026-05]] | **Ninth QA (2026-05-24)** — production dart-defines, courier lookup migrations, iOS privacy/export, 40/40 tests |
| [[Send_Proof_Courier_2026-05]] | **Send Proof (May 2026)** — PDF + share sheet, production web archive URL, live-host gate |
| [[Polygon_Mainnet_Wiring_2026-05]] | **Eighth QA (2026-05-22)** — live Polygon mainnet on iPhone, secrets, sim fallback removed |
| [[App_Store_Prep_Capture_Seal_2026-05]] | **Fifth QA (2026-05-21)** — App Store legal bundle, multi-shot seal hardening, vault I/O fixes |
| [[Identity_Lifecycle_And_Data_Lineage]] | **Sixth QA (2026-05-21)** — Wallet lineage, EVM key rotation, JIT courier upload, archive placeholders |
| [[FactLockCam_Master_Blueprint]] | Application capabilities, finished vs unfinished, use cases |
| [[Polygon_Saga_Live]] | Live Polygon saga (Try 2): await relay at capture, local `chain_tx_hash`, certificate tx line |
| [[iOS_Device_Development_Workflow]] | Physical iOS build/install when `flutter run` attach fails |

## Sources

- [[Compliant_Subscription_Architecture_Source]] - App Store 3.1.1 three-tier Archive subscription spec (`raw/compliant_subscription_architecture.md`).
- [[Sample_Source]] - Bootstrap source describing the LLM Wiki workflow.
- [[ProofLock_Architectural_Manifest]] - ProofLock viability manifest and target system architecture (ingested raw source summary).
- [[Project_Audit_2026-05-11_Source]] - Immutable 2026-05-11 repo vs wiki audit (`raw/project_audit_2026-05-11.md`); see [[Project_Audit_2026-05-11]].

## Concepts

- [[LLM_Wiki_Pattern]] - The source-to-wiki compilation model.
- [[Web_Deployment_Architecture_2026-05]] - Fourteenth QA: decoupled web (Astro sales + archive courier-only Flutter gate).
- [[Sovereign_Key_Lifecycle_2026-05]] - Thirteenth QA: multi-key `.factlock`, brick/restore, burn UX, compliance URL routing.
- [[Cloud_Vault_Wiring_2026-05]] - Twelfth QA: factlock_vault cloud sync wired into capture seal pipeline.
- [[UI_Layout_Polish_2026-06]] - Twenty-first QA: responsive archive shell layouts, Account landscape scroll fix, Archive copy audit (June 2026).
- [[UI_Polish_Hub_Archive_2026-05]] - Eleventh QA: logo banner, Account heavy-metal tiles, chronology scroll fix.
- [[App_Store_Remediation_2026-05]] - Tenth QA: App Store remediation, WEB_ARCHIVE_BASE_URL, courier archive indices, TestFlight-first.
- [[Production_Transition_2026-05]] - Ninth QA: production config, courier lookup migrations, iOS compliance, test suite.
- [[Data_Custody_And_Backup_Model_2026]] - Canonical backup/custody: device `.seal`, `.factlock` keys, cloud ciphertext (not user media backup).
- [[Archive_Subscription_Tiers_2026]] - Three-tier subscription foundation: local-first gates, 50 MB free video cap, compliant tier names, legal onboarding (June 2026).
- [[Archive_Quota_Telemetry_2026-06]] - Dual-layer Archive metering: byte storage/egress + credit pro proofs/verification credits; gas gauge, Egress Pass badge, paywall (June 2026, device QA).
- [[Archive_Owner_UX_2026-05]] - Sixteenth QA: Download Media, certificate metadata from asset, View/Play labels, chronology actions icon.
- [[Send_Proof_Courier_2026-05]] - Send Proof: certificate PDF + courier link; utility positioning; production web archive URL.
- [[FactLockCam_Product_Baseline_2026-05]] - Verified hub/archive/capture workflow and compressed Supabase baseline (start here for FactLockCam status).
- [[Heavy_Metal_Design_System]] - FactLockCam titanium/mono/iris visual system for secure-hardware UI feel.
- [[Archive_Transactional_Journal]] - Sprint 2 WAL journal, transactional file persist, boot recovery, SQLite open hardening.
- [[Isolate_Lock_Coordinator]] - Sprint 4 cross-isolate UI lock stream, sidecar advisory locks, securing overlays.
- [[App_Store_Prep_Capture_Seal_2026-05]] - Fifth QA: legal bundle, multi-shot capture, vault promote I/O fixes.
- [[Identity_Lifecycle_And_Data_Lineage]] - Sixth QA: wallet history, EVM lineage on ledger, JIT courier, restore placeholders.
- [[Polygon_Mainnet_Wiring_2026-05]] - Eighth QA: live Polygon mainnet on iPhone, relay secrets, sim fallback removed.

## Analyses (active)

- [[Unified_Archive_Studio_2026-06]] — Twenty-ninth pass: Certificate Studio pivot, hub backdrop fix, user QA stable, **98/98** tests (June 2026).
- [[Zero_Click_Capture_2026-06]] — Twenty-eighth pass: Zero-Click mobile Secure Comm capture (June 2026); **superseded** by Unified Archive Studio decommission.
- [[Secure_Communications_Console_2026-06]] — Twenty-seventh pass: phased web courier console, user QA stable (June 2026).
- [[UGC_Safety_Reporting_2026-06]] — Twenty-fourth pass: App Store 1.2 UGC safety, courier report/block, async moderation (June 2026).
- [[Zero_Trust_RLS_Audit_2026-06]] — RLS matrix and AES-GCM key isolation audit (June 2026).
- [[Provisional_Patent_Technical_Exhibit_2026-06]] — Enablement exhibit: journal, isolate locks, Polygon saga (June 2026).
- [[Institution_Grade_Payload_Seal_Backlog]] — Deferred arbitrary-file sealing; foundation schema/Dart contracts (June 2026).
- [[UI_Layout_Polish_2026-06]] — Twenty-first pass: Heavy Metal responsive layouts, device QA on iPhone landscape (June 2026).
- [[Compliance_Refactor_2026-06]] — Eighteenth pass: legal/compliance copy, `/archive` routing, presentation-layer Archive rename, QA Account panel fix (June 2026).
- [[Archive_Owner_UX_2026-05]] - Sixteenth QA: Download Media, Send Proof metadata from asset, View/Play labels, chronology actions icon (May 2026).
- [[App_Store_Hardening_2026-05]] - Fifteenth QA: architectural manifest remediation, Secure Enclave / Keystore signing, compile-time gates (May 2026).
- [[Web_Deployment_Architecture_2026-05]] - Fourteenth QA: public web split, courier-only archive subdomain, Cloudflare deploy scripts (May 2026).
- [[Sovereign_Key_Lifecycle_2026-05]] - Thirteenth QA: `.factlock` multi-key backup, zero-knowledge lock, restore router gate, Account layout (May 2026).
- [[Cloud_Vault_Wiring_2026-05]] - Twelfth QA: post-notarization cloud archive sync, factlock_vault migration, coordinator wiring (May 2026).
- [[UI_Polish_Hub_Archive_2026-05]] - Eleventh QA: shared logo header, Account panel backdrop + hub tiles, chronology opacity fix (May 2026).
- [[App_Store_Remediation_2026-05]] - Tenth QA: compliance remediation, archive URL rename, migration push, TestFlight posture (May 2026).
- [[Production_Transition_2026-05]] - Ninth QA: production dart-defines, courier migrations, iOS privacy/export, 40/40 tests (May 2026).
- [[Send_Proof_Courier_2026-05]] - Send Proof workflow, App Store utility rules, production web archive URL (May 2026).
- [[FactLockCam_Master_Blueprint]] - Current-state application blueprint: hub-first archive shell, archive actions, unfinished work, use cases.
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

## Agent skills (repo)

| Skill | Purpose |
|-------|---------|
| `docs/skills/SKILL_UNIFIED_ARCHIVE_STUDIO.md` | Unified Archive Studio pivot — hub restore, Certificate Studio, courier decommission |
| `docs/skills/SKILL_Dispatch_Primitive.md` | Dispatch Primitive Framework — Tasks 1–5 bite-sized Secure Communications Console refactor (historical) |
| `docs/skills/SKILL_Zero_Click_Capture_Architecture.md` | Zero-Click Secure Comm capture — pre-warm, hot lens swap, Access Control overlay |
| `docs/skills/SKILL_QA_Env_Boot.md` | Safe physical-device QA cold-start (`.env.qa.local`, no secrets in agent context) |
| `docs/skills/SKILL_Secure_Comm_Console.md` | Web courier Secure Communications Console — phase machine, attestation RPC, validation |
| `docs/skills/SKILL_Compliance_Architecture.md` | Zero-trust lexicon, UGC safety, patent exhibit scaffolding |
| `docs/skills/SKILL_FORENSIC_UI_REFINEMENT.md` | Presentation-only Heavy Metal layout polish |
| `docs/skills/SKILL_IMPLEMENT_ARCHIVE_SUBSCRIPTIONS.md` | Three-tier subscription foundation |

## Maintenance

- [[overview]]
- [[glossary]]
- [[log]]
