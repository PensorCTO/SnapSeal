---
tags: [glossary, terminology, llm_wiki]
summary: "Terminology reference for the LLM Wiki."
---

# Glossary

## Terms

| Term | Definition | Related Notes |
| :--- | :--- | :--- |
| LLM Wiki | A Markdown knowledge base maintained by an LLM from immutable raw sources. | [[LLM_Wiki_Pattern]] |
| Raw Source | Original input material stored in `raw/` and treated as immutable. | [[Sample_Source]] |
| Compiled Wiki | Durable synthesized knowledge stored under `wiki/`. | [[LLM_Wiki_Pattern]] |
| Provenance | Explicit source tracking for important claims. | [[Sample_Source]] |
| FactLockCam | Flutter tamper-evident media archive: seal and verify captures with local AES-GCM archiveing and Supabase ledger replication (risk reduction framing — see [[FactLockCam_Master_Blueprint]]). | [[FactLockCam_Master_Blueprint]] |
| FactLockCam product baseline (2026-05) | Verified logon→hub→archive/capture workflow plus compressed Supabase repair/backfill pointers; canonical status entry. Seventeenth pass (2026-06-02): dual-layer Archive quota. | [[FactLockCam_Product_Baseline_2026-05]] |
| Archive quota (byte layer) | Per-user `archive_quotas` row + `archive_tiers` catalog; meters storage/egress bytes via RPCs; `QuotaTelemetryWidget` progress bars; paywall via `ensureArchiveQuotaForSeal` / `ensureArchiveQuotaForSendProof`. | [[Archive_Quota_Telemetry_2026-06]] |
| LocalArchiveQuotaGate | Client-first seal gate: `SUM(byte_length)` from SQLite + incoming bytes vs tier limit; used by camera, `VaultService`, and paywall interceptors. | [[Archive_Subscription_Tiers_2026]] |
| Sovereign Free Baseline | `free` tier display name; 50 MB storage, 50 MB single-capture video cap with in-recording stop. | [[Archive_Subscription_Tiers_2026]] |
| Core Pro Tier | `picture` tier display name; 5 GB storage / 25 GB egress. | [[Archive_Subscription_Tiers_2026]] |
| Sovereign Archivist | `video` tier display name; 50 GB storage / 200 GB egress. | [[Archive_Subscription_Tiers_2026]] |
| archiveSubscriptionTierDisclaimer | Legal copy: higher tiers expand bandwidth only; zero data recovery / no key escrow. | [[Archive_Subscription_Tiers_2026]], `disclaimers.dart` |
| Pro proof (credit) | Monthly included remote seal/notarization allowance; default **50**/cycle in `subscription_cycles.base_allocation`; debited on successful seal; shown as `PROOFS: remaining/base` in camera HUD. | [[Archive_Quota_Telemetry_2026-06]] |
| Verification Credit | Consumable egress credit debited on heavy `extractForCourier` paths (verify, export, Download Media); default **12** on new cycles; pre-flight modal in `UniversalAssetToolbar`. | [[Archive_Quota_Telemetry_2026-06]] |
| Egress Pass | User-facing label for verification credit balance; `EgressPassBadge` pill in `UnifiedArchiveViewport` header. | [[Archive_Quota_Telemetry_2026-06]] |
| Dense header (UI) | When viewport height &lt; 520, archive/account panels use 72px logo, hide byte quota telemetry, and compact pending-sync / control chrome. | [[UI_Layout_Polish_2026-06]] |
| SKILL_FORENSIC_UI_REFINEMENT | Agent skill for presentation-only Heavy Metal layout polish without touching domain/crypto. | `docs/skills/SKILL_FORENSIC_UI_REFINEMENT.md`, [[UI_Layout_Polish_2026-06]] |
| quotaStateProvider | Riverpod sync notifier for credit metering; optimistic debit + `record_metered_consumption` reconcile; polled on app resume and archive entry. | [[Archive_Quota_Telemetry_2026-06]] |
| get_current_quota_status | Supabase RPC returning pro-proof and verification-credit counters for authenticated user. | [[Archive_Quota_Telemetry_2026-06]] |
| Active-Wallet Ledger | Supabase replica of proof rows for assets still connected to active app wallets. | [[FactLockCam_Master_Blueprint]] |
| Pending Sync | Local SQLite state marking a sealed asset whose remote proof path (`proof_ledger` / RPC pipeline) has not completed; cleared by retry/sync or marked deferred with backoff. | [[FactLockCam_Master_Blueprint]] |
| Courier Payload | Service-layer export of decrypted media after SHA-256 re-verification. | [[FactLockCam_Master_Blueprint]] |
| ProofLock (manifest) | Target architecture and viability bar: TEE-backed signing, Polygon, C2PA, RPC-first ledger/courier; ingested as a wiki source. | [[ProofLock_Architectural_Manifest]] |
| Project audit source (2026-05-11) | Immutable `raw/project_audit_2026-05-11.md`; summary [[Project_Audit_2026-05-11_Source]]; compiled analysis [[Project_Audit_2026-05-11]]. | [[Project_Audit_2026-05-11_Source]] |
| Magic Number (auth) | Supabase email OTP flow using a 6-digit code (`OtpType.email`) in the FactLockCam logon UI. | [[FactLockCam_Master_Blueprint]] |
| Device signature (hardware) | Base64 ECDSA signature from P-256 Secure Enclave (iOS) or Android Keystore over SHA-256 hex digest via `com.factlockcam.app/enclave` `signHash`. **`SIMULATED_DEV` removed** fifteenth QA. | [[App_Store_Hardening_2026-05]] |
| ENABLE_PROOF_LINKS | Compile-time dart-define; `AppConfig.enableProofLinks` gates Send Proof. Release/profile: **false** until archive verified. Debug: enabled when `WEB_ARCHIVE_BASE_URL` is set even if define is false. | [[Archive_Owner_UX_2026-05]], [[App_Store_Hardening_2026-05]], [[Send_Proof_Courier_2026-05]] |
| Download Media | Owner action: decrypt via `extractForCourier`, write temp file, system share sheet (`archive_media_download_io.dart`). Inspector tile + action sheet + chronology **⋯**. | [[Archive_Owner_UX_2026-05]] |
| View/Play media | Unified archive label for viewing or playing decrypted photo/video (toolbar, inspector). | [[Archive_Owner_UX_2026-05]] |
| run_device.sh | `factlockcam_app/run_device.sh` — runs `sync_flutter_dart_defines.sh` then `flutter run --dart-define-from-file=dart_defines.json`. Preferred physical-device QA entry. Set `FACTLOCKCAM_ENV_FILE` to `.env.qa.local` when using the QA env file. | [[App_Store_Hardening_2026-05]], [[iOS_Device_Development_Workflow]] |
| .env.qa.local | Gitignored QA Supabase + Send Proof defines copied from `.env.qa.example`. Selected via `FACTLOCKCAM_ENV_FILE` for sync and VS Code **iOS (QA Tunnel)**. | `docs/skills/SKILL_QA_Env_Boot.md`, [[iOS_Device_Development_Workflow]] |
| FACTLOCKCAM_ENV_FILE | Shell override for `scripts/sync_flutter_dart_defines.sh` env source (default: repo-root `.env.local`; QA: `.env.qa.local`). | `.vscode/tasks.json`, [[iOS_Device_Development_Workflow]] |
| SKILL_QA_Env_Boot | Agent skill for safe interactive QA device cold-start without exposing Supabase secrets in chat/terminal. | `docs/skills/SKILL_QA_Env_Boot.md` |
| dart_defines.json (FactLockCam) | Filtered JSON from `scripts/write_flutter_dart_defines.py` / `scripts/sync_flutter_dart_defines.sh` for `flutter run --dart-define-from-file` (Supabase URL/key, `USE_POLYGON_NOTARIZER`, `POLYGON_RPC_URL`, **`WEB_ARCHIVE_BASE_URL`**, `ENABLE_PROOF_LINKS`, `APP_ENVIRONMENT`, `SUPPORT_URL`). Gitignored at repo root of app. | [[App_Store_Hardening_2026-05]], [[App_Store_Remediation_2026-05]], [[Production_Transition_2026-05]] |
| APP_ENVIRONMENT | Compile-time define (`production` in ninth QA); `AppConfig.isProduction` guardrails. | [[Production_Transition_2026-05]] |
| SUPPORT_URL | Compile-time help link (`https://factlockcam.com/support`); Account & Settings **HeavyMetalHubTile** row. | [[Production_Transition_2026-05]], [[UI_Polish_Hub_Archive_2026-05]] |
| GeneratedDartDefines | Compile-time fallback in `generated_dart_defines.dart` (committed empty template; sync from `.env.local` overwrites locally — do not commit after sync). Stub reference: `generated_dart_defines.stub.dart`. | `app_config.dart`, [[FactLockCam_Product_Baseline_2026-05]] |
| Archive transactional journal | Sprint 2 `factlockcam_journal.db` (sqlite3 WAL) + **`TransactionalArchivePersister`** (formerly `TransactionalVaultPersister`): prepare → stage `*.part` → atomic rename → commit journal + `archive_items` upsert; boot recovery rolls back `prepared` rows. | [[Archive_Transactional_Journal]], [[App_Store_Remediation_2026-05]] |
| Sidecar staging lock | Advisory lock file `{stagingPath}.lock` used during promote/rename so the payload `*.part` file is never opened with `FileMode.write` (which would truncate staged ciphertext/thumbnails to 0 bytes). | [[Isolate_Lock_Coordinator]], [[App_Store_Prep_Capture_Seal_2026-05]] |
| sealAndStoreCapture | Buffered in-memory capture path: `_hashBytesInIsolate` → `_proofLockBytes*` → `_persistSealedBytes`; serialized by `_enqueueCaptureSeal` for rapid multi-shot. | [[App_Store_Prep_Capture_Seal_2026-05]], `vault_service_io.dart` |
| Archive (user-facing) | Canonical product nomenclature for hub, routes, and UI copy (`/archive`, Archive tile). Internal `ArchiveService` / `ArchiveDatabase` with deprecated `Vault*` typedef shims; PR9 deferred: `factlock_vault` bucket, SQL `vault_key`. | [[Compliance_Refactor_2026-06]], [[UGC_Safety_Reporting_2026-06]] |
| Content Report | Recipient or owner submission via `report_courier_package` RPC; stored in `courier_content_reports`; never returns `owner_id`. | [[UGC_Safety_Reporting_2026-06]] |
| Sender Block | Server-side block of courier origin via `block_courier_sender`; `owner_id` resolved from `package_id` only on server. | [[UGC_Safety_Reporting_2026-06]] |
| Moderation Queue | `courier_moderation_queue` + `courier-content-scan` Edge Function; async scan off capture hot path; `moderation_status` on `courier_packages`. | [[UGC_Safety_Reporting_2026-06]] |
| SKILL_Compliance_Architecture | Procedural toolkit: lexicon enforcement, UGC safety, RLS audit, patent exhibit. | `docs/skills/SKILL_Compliance_Architecture.md` |
| Zero-trust communication primitive | Product positioning: frictionless local capture + post-distribution safety on courier surfaces; no identity gate on camera lens. | [[UGC_Safety_Reporting_2026-06]], [[Zero_Trust_RLS_Audit_2026-06]] |
| HeavyMetalLogoBanner | Titanium brand plinth at top of hub/logon/archive; default child `factlockcam_logoheader.jpg` (`kHeavyMetalLogoHeaderAsset`). | [[UI_Polish_Hub_Archive_2026-05]], [[Heavy_Metal_Design_System]] |
| HeavyMetalHubTile | Shared hub-style titanium gradient tile (icon, uppercase label, subtitle, chevron); used on hub launcher and Account legal/support rows. | [[UI_Polish_Hub_Archive_2026-05]] |
| Chronology scroll (archive) | Scroll-driven scale/fan on `ChronologyCard`; opacity dimming removed eleventh QA; **⋯** opens asset action sheet sixteenth QA. | [[UI_Polish_Hub_Archive_2026-05]], [[Archive_Owner_UX_2026-05]] |
| LegalDocumentView | Native bundled ToS/Privacy renderer (`assets/legal/*.md`) from Account & Settings. | [[App_Store_Prep_Capture_Seal_2026-05]] |
| ProofBundleExportService | Zips proof artifacts to temp dir; **not** used on Send Proof path (May 2026). | [[Send_Proof_Courier_2026-05]] |
| SendProof (notifier) | Riverpod `SendProof`: certificate PDF + courier package + iOS share sheet; **no in-app email**. | [[Send_Proof_Courier_2026-05]] |
| WEB_ARCHIVE_BASE_URL (courier) | Compile-time origin in shared Send Proof links. Production default: `https://archive.factlockcam.com`. Serves **courier-only** Flutter web (`/courier?pkg=…` + gate at `/`). Ngrok OK for TestFlight. | [[Web_Deployment_Architecture_2026-05]], [[Send_Proof_Courier_2026-05]] |
| WEB_BASE_URL (marketing) | Compile-time apex marketing origin. Production default: `https://factlockcam.com` (Astro sales pitch + compliance pages). Used by `WebArchiveGateView` “Learn more” link. | [[Web_Deployment_Architecture_2026-05]] |
| WebArchiveGateView | Flutter web root on archive subdomain: courier-only notice; redirects all non-`/courier` web paths. Not a mobile logon surface. | [[Web_Deployment_Architecture_2026-05]] |
| factlockcam-archive (Pages) | Cloudflare Pages project for Flutter courier SPA; deploy via `scripts/deploy_web_archive_cf.sh`. | [[Web_Deployment_Architecture_2026-05]] |
| WEB_VAULT_BASE_URL (deprecated) | Former compile-time courier origin key; superseded by **`WEB_ARCHIVE_BASE_URL`**. `AppConfig.webVaultBaseUrl` is a deprecated Dart alias only. | [[App_Store_Remediation_2026-05]] |
| courier lookup index | Migration `20260524130000`: `unlock_code` + `status` on `courier_packages` with `(unlock_code, status)` index; trigger `20260524140000` keeps columns synced. | [[Production_Transition_2026-05]] |
| setupTestDependencies | Shared Flutter test bootstrap: sqflite FFI, platform plugin mocks, DI reset; skips Supabase/polygon scheduler in tests. | [[Production_Transition_2026-05]], `test/test_dependencies.dart` |
| courier-unlock | Edge Function: RPC password gate + signed Storage URL for web recipients. | [[Send_Proof_Courier_2026-05]] |
| Send Proof utility rule | App Store: utility not messaging app — no outbound email from FactLockCam. | [[Send_Proof_Courier_2026-05]] |
| Isolate lock coordinator | Sprint 4 `IsolateLockCoordinator` + `assetLockStateProvider`: mirrors in-flight vault writes to **SECURING FILE…** overlays; sidecar advisory lock on promote; payload writes on caller isolate. | [[Isolate_Lock_Coordinator]] |
| PrivacyInfo.xcprivacy | Apple-required privacy manifest bundled with iOS Runner; must align with App Store Connect nutrition labels. | `ios/Runner/PrivacyInfo.xcprivacy`, `docs/app_store_submission_checklist.md` |
| SECURING FILE… | Sprint 4 archive overlay copy while an asset fingerprint is lock-coordinator–protected (not blockchain pending copy). | [[Isolate_Lock_Coordinator]], `asset_securing_overlay.dart` |
| Lazy panel mount | `ArchiveHomeView` builds camera, archive, and account panels only when their `IndexedStack` index is active. | [[FactLockCam_Master_Blueprint]], `archive_home_view.dart` |
| Pending sync scheduler | `PendingSyncScheduler` (~3 minute interval) triggers `DashboardController.syncPendingInBackground`. | [[Project_Audit_2026-05-11]], [[FactLockCam_Master_Blueprint]] |
| AcquisitionMode | Dart enum (`factlockcam_app/lib/ui/mobile/camera/acquisition_mode.dart`) distinguishing photo vs video capture; consumed by `CameraView` in `ArchiveHomeView` to toggle audio and recording shutter behavior. | [[FactLockCam_Master_Blueprint]] |
| Shutter Iris | Mechanical iris capture control rendered by `ShutterIrisPainter`: titanium outer ring, six animated aperture blades, Kinetic Green active recording fill, and Verified Neon seal-complete flash. | [[Heavy_Metal_Design_System]] |
| Titanium Deep | Primary heavy-metal UI background token (`#121212`) used to avoid pure-black flatness while keeping the app visually industrial and high contrast. | [[Heavy_Metal_Design_System]] |
| Verified Neon | Completed locked/verified green token (`#39FF14`), reserved for successful verification, locked states, and primary trust calls to action. | [[Heavy_Metal_Design_System]] |
| Kinetic Green | Active/in-progress green token (`#00D26A`) used for recording, active lock motion, and other live process states. | [[Heavy_Metal_Design_System]], [[Master_Context_11MAY2026]] |
| ShutterButtonPainter | **DEPRECATED** — Legacy original custom camera shutter painter: white 2 px stroked outer ring, transparent center at rest, 150 ms white photo snap, and Kinetic Green fill while video recording. Superseded by `ShutterIrisPainter`. | [[Master_Context_11MAY2026]], [[FactLockCam_Master_Blueprint]], [[Heavy_Metal_Design_System]] |
| Lazy camera mount | **Deprecated narrow term** — use **Lazy panel mount** (cameras + archive + account). Originally PR0 for cameras only (2026-05-20). | [[Polygon_Try1_Postmortem]] |
| Hub-first archive shell | Authenticated shell at **`/archive`** (`ArchiveHomeView`; legacy **`/vault-home`** redirects): `IndexedStack` index 0 = `HapticHubPanel`; 1–2 = lazy-mounted `CameraView`; 3 = archive omni; 4 = account. Panel back → hub. Internal services retain `VaultService` naming. | [[FactLockCam_Master_Blueprint]], [[Polygon_Try1_Postmortem]] |
| Compliance copy (2026-06) | Shared disclaimers in `disclaimers.dart`: epistemic integrity (file not scene truth), sovereign key non-recovery, Polygon no-SLA; `marketing_compliance_test.dart` guards `marketingBanList`. | `wiki/log.md` 2026-06-03 |
| Hosted ToS/Privacy task (open) | Mirror in-app compliance on **factlockcam.com** Terms + Privacy (sovereign keys, epistemic boundary, Polygon SLA). Tracked 2026-06-03; separate from Flutter build. | `wiki/log.md` 2026-06-03 |
| Four-panel vault UX | **Deprecated term** — use **Hub-first archive shell**. Historically described `ProfessionalNavBar` bottom tabs; current tree uses hub tiles + panel back navigation only. | [[FactLockCam_Master_Blueprint]] |
| Dual-mode capture (Photo + Video) | **Picture** and **Video** hub actions both flow through the same `VaultService.proofLockFile` seal pipeline, with `video/*` rows rendering native frame thumbnails and a play-arrow badge overlay in the archive. | [[Master_Context_11MAY2026]], [[FactLockCam_Product_Baseline_2026-05]] |
| Archive delete (local) | Per-item archive action that deletes the local SQLite row plus encrypted/thumbnail files from the device; it does not erase remote `proof_ledger` rows. | [[FactLockCam_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| Owner-side verified viewing | Full-size photo viewing (`ArchivePhotoView`) and video playback (`ArchiveVideoView`) decrypt through `VaultService.extractForCourier`, re-verifying the SHA-256 before rendering the original bytes. | [[FactLockCam_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| Cold-build dart-defines rule | Compile-time `--dart-define` values (e.g. `SUPABASE_URL`, `SUPABASE_ANON_KEY`) only refresh on a cold Flutter build; Dart hot-restart keeps stale defines and surfaces "Supabase is not configured yet...". Use `bash scripts/factlockcam_supabase_pipeline.sh app-run` (or `flutter run --dart-define-from-file dart_defines.json`) after any `.env.local` / `dart_defines.json` change. | [[Master_Context_11MAY2026]], [[FactLockCam_Product_Baseline_2026-05]] |
| Domain Interaction Contract | Archive action architecture that maps each asset's `mediaType` / SQLite `mime_type` to allowed `MediaActionType`s through `AssetActionRegistry`, then renders them via `UniversalAssetToolbar` and executes service work through the `AssetAction` Riverpod notifier. | [[FactLockCam_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| UniversalAssetToolbar | Cupertino action-sheet widget for media assets; delegates view/verify/delete/share/export affordances to `AssetActionRegistry` instead of hardcoding delete/play/verify buttons per archive view. | [[FactLockCam_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| MIME-aware video thumbnail fallback | `VaultService` behavior that preserves video format hints when regenerating thumbnails from decrypted bytes by using temp-file extensions such as `.mov`, `.webm`, and `.mp4` based on `mimeType`. | [[FactLockCam_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| AES-GCM | Authenticated encryption algorithm used by `CipherEngine` / `VaultEncryptionHandler` for local archive encryption of sealed media. | [[FactLockCam_Master_Blueprint]], [[ProofLock_Refactor_Scope]] |
| C2PA | Coalition for Content Provenance and Authenticity -- an open standard for cryptographically signing media provenance metadata. Referenced as a future ProofLock viability track; not yet implemented. | [[ProofLock_Refactor_Scope]], [[ProofLock_Architectural_Manifest]] |
| PolygonChainNotarizer | `ChainNotarizer` implementation when `USE_POLYGON_NOTARIZER=true`: EIP-191 owner sign via `PolygonWalletService`, then `PolygonBlockchainHandler.notarizeFileHash` → `anchor-relay`. | `chain_notarizer.dart`, [[Polygon_Saga_Live]], [[Polygon_Mainnet_Wiring_2026-05]] |
| polygon-sim hash | **Legacy (removed eighth QA):** Deterministic fake `chain_tx_hash` from UTF-8 `polygon-sim:<asset_hash>`. Client rejects if returned. Old ledger rows may still contain sim-encoded hashes. | [[Polygon_Mainnet_Wiring_2026-05]] |
| POLYGON_RPC_URL | Optional dart-define for client-side `Web3Client` receipt polling in `PolygonNotarizationMonitorService`; synced via `write_flutter_dart_defines.py`. | `app_config.dart`, [[Polygon_Mainnet_Wiring_2026-05]] |
| journal_repository (web stub) | Conditional export: web uses `journal_repository_stub.dart` (no sqlite3); IO uses `journal_repository_io.dart`. Enables Flutter Web compile. | [[Polygon_Mainnet_Wiring_2026-05]] |
| anchor-relay | Supabase Edge Function: JWT + EIP-191 verify → live Polygon `notarize()` broadcast → `finalize_polygon_notarization`. Requires `ALCHEMY_API_URL` + `RELAYER_PRIVATE_KEY` secrets. Deploy: `supabase functions deploy anchor-relay --no-verify-jwt`. | `supabase/functions/anchor-relay/`, [[Polygon_Mainnet_Wiring_2026-05]] |
| relayer hot wallet | Funded EVM account whose private key is `RELAYER_PRIVATE_KEY` in Supabase secrets; pays gas for on-chain notarization. Distinct from user `profiles.evm_address` (signs only). | [[Polygon_Mainnet_Wiring_2026-05]] |
| Polygon saga | Capture pipeline when `USE_POLYGON_NOTARIZER=true`: pending `proof_ledger` row → **await** `anchor-relay` → local `chain_tx_hash` + `pending_sync` clear. Camera overlay: **Generating Proof…**. Flag defaults true via dart-defines sync. | [[Polygon_Saga_Live]], `.cursor/rules/polygon-saga-architecture.mdc` |
| chain_tx_hash (local) | SQLite column on `archive_items` (DB v5) mirroring finalized `proof_ledger.chain_tx_hash`; written on relay success; certificate reads local first, then remote fetch. | `vault_database_io.dart`, [[Polygon_Saga_Live]] |
| Generating Proof… | User-facing Polygon in-progress copy (not "Waiting for Blockchain Tx"); shown on camera sealing overlay and vault pending badges via `ProofState.processingLabel`. | `.cursor/rules/polygon-saga-architecture.mdc`, [[Polygon_Saga_Live]] |
| CertificateExportService | Certificate draft + PDF export (`pdf` package); Polygonscan link when `chain_tx_hash` present. | [[Send_Proof_Courier_2026-05]], `certificate_export_service.dart` |
| ProofSyncNotifier | Domain event bus: fires when relay finalization clears local `pending_sync`; invalidates archive dashboard via Riverpod. | `proof_sync_notifier.dart` |
| notarization_status | `proof_ledger` column: `pending_notarization` \| `notarized` \| `failed`. Drives saga + Realtime monitor. | migration `20260520120000_polygon_saga_proof_ledger.sql` |
| ProofLockConflictException | Custom exception thrown by `VaultService.proofLockFile` when `check_proof_status` RPC returns a status other than `new` (i.e., the hash already exists in the ledger). | [[FactLockCam_Master_Blueprint]], [[FactLockCam_Blueprints_14May2026]] |
| proof_ledger | Supabase table storing sealed asset proof rows: `asset_hash`, `device_signature`, `chain_tx_hash`, and wallet linkage. The primary remote proof surface after the simulated-chain migration. | [[FactLockCam_Blueprints_14May2026]], [[FactLockCam_Master_Blueprint]] |
| REQUIRE_HARDWARE_ATTESTATION | Dart compile-time define; when true in release/profile, `_validatedDeviceSignature` rejects `SIMULATED_DEV` payloads. Native handlers no longer emit simulated signatures (fifteenth QA). | [[App_Store_Hardening_2026-05]], [[ProofLock_Refactor_Scope]] |
| RLS (Row Level Security) | PostgreSQL feature used on all Supabase tables (`proof_ledger`, `seal_ledger`, `courier_packages`, storage buckets) to scope data access by `auth.uid()`. | [[FactLockCam_Blueprints_14May2026]], [[MASTER_CONTEXT13MAY2026]] |
| RPC (Remote Procedure Call) | Supabase PostgREST function calls (`rpc()`) used for gating sensitive operations like `check_proof_status`, `simulate_chain_notarize`, `attempt_courier_unlock`, and `get_or_create_courier_package`. | [[FactLockCam_Blueprints_14May2026]], [[MASTER_CONTEXT13MAY2026]] |
| SealLedgerRepository | Dart repository class (`data/supabase/seal_ledger_repository.dart`) wrapping Supabase RPC and table operations for proof preflight, notarization simulation, ledger inserts, and courier blob uploads. | [[FactLockCam_Blueprints_14May2026]], [[FactLockCam_Master_Blueprint]] |
| SHA-256 | Cryptographic hash algorithm used by `VaultService` to fingerprint original media bytes (via `Isolate.run`) for integrity verification, duplicate detection (`check_proof_status`), and chain anchoring. | [[FactLockCam_Blueprints_14May2026]], [[FactLockCam_Master_Blueprint]] |
| SimulatedChainNotarizer | Fallback `ChainNotarizer` when `USE_POLYGON_NOTARIZER=false`; delegates to `simulate_chain_notarize` RPC. When flag is **true**, async Polygon saga replaces this path — [[Polygon_Saga_Live]]. | `chain_notarizer.dart`, [[ProofLock_Refactor_Scope]] |
| flutter_launcher_icons | Dev dependency generating iOS/Android/web launcher icons from `assets/images/FactLockCamAppIcon.png`. Regenerate after icon art changes: `dart run flutter_launcher_icons`. | `pubspec.yaml`, [[FactLockCam_Product_Baseline_2026-05]] |
| FactLockCam app icon | Branded camera/lock artwork (#0D1B3A navy background) applied to iOS AppIcon, Android adaptive launcher, and web PWA icons. | [[FactLockCam_Product_Baseline_2026-05]] |
| wallet_history | Supabase table archiving prior `profiles.evm_address` values on rotation; `owner_id → profiles.id ON DELETE CASCADE`. | [[Identity_Lifecycle_And_Data_Lineage]] |
| Historical archive placeholder | UI state when local `wallet_address != profiles.evm_address`; missing local file shows `RestoreArchiveBanner`. | [[Identity_Lifecycle_And_Data_Lineage]], `archive_grid_item.dart` |
| ProofCourierService | JIT courier blob upload: isolate byte copy + Supabase Storage inside iOS `beginBackgroundTask` scope. | [[Identity_Lifecycle_And_Data_Lineage]], `proof_courier_service.dart` |
| factlock_vault (bucket) | Private Supabase Storage bucket for **optional blind ciphertext** after seal (`{uid}/{packageId}.enc`). Not a consumer “download your photos” backup; requires same-account keys. Distinct from Send Proof **`courier-blobs`**. See [[Data_Custody_And_Backup_Model_2026]]. | [[Cloud_Vault_Wiring_2026-05]] |
| .factlock key backup | Password-encrypted export of EVM + archive AES keys via Account → Export archive keys. **Only** user-managed backup; does not export media from Supabase. Re-export periodically or before Lock/uninstall—not per capture. | [[Data_Custody_And_Backup_Model_2026]], [[Sovereign_Key_Lifecycle_2026-05]] |
| Lock archive (brick) | `AppLockCoordinator.lockArchive` purges sovereign keys from Secure Storage; local `.seal` files remain; restore via `.factlock` import on `/restore`. | [[Data_Custody_And_Backup_Model_2026]], [[Sovereign_Key_Lifecycle_2026-05]] |
| Burn account | `perform_full_burn` + `burnLocalWallet` — deletes auth identity, linked cloud storage, local DB/files, and keys. Prior `.factlock` cannot restore that account. | [[Data_Custody_And_Backup_Model_2026]], [[Sovereign_Key_Lifecycle_2026-05]] |
| VaultSyncCoordinator | Post-notarization orchestrator: `get_or_create_courier_package` → `Isolate.run` + `CourierCrypto.encrypt` → `IPlatformChannelCoordinator` background upload. | [[Cloud_Vault_Wiring_2026-05]], `vault_sync_coordinator.dart` |
| SupabaseVaultService | Upload-only cloud archive client; ciphertext in, updates `courier_packages.storage_path` / `file_size_bytes`. | [[Cloud_Vault_Wiring_2026-05]], `supabase_vault_service.dart` |
| PlatformChannelCoordinator | MethodChannel `com.factlockcam.app/platform` for background tasks and iOS backup restore picker. | [[Identity_Lifecycle_And_Data_Lineage]] |
| perform_full_burn | RPC deleting courier storage blobs then `auth.users` row; cascade purges profile-linked tables (App Store 5.1.1). | [[Identity_Lifecycle_And_Data_Lineage]], migration `20260521120000_identity_lifecycle.sql` |
| .factlock | Password-encrypted JSON keystore exporting both `factlockcam:evm_private_key` and `factlockcam:vault_key`; PBKDF2 + AES-GCM envelope. | [[Sovereign_Key_Lifecycle_2026-05]], `factlock_keystore.dart` |
| KeyCustodyService | Singleton read/write/purge for both sovereign secure-storage keys; used by burn, brick, and restore. | [[Sovereign_Key_Lifecycle_2026-05]], `key_custody_service.dart` |
| AppLockCoordinator | Zero-knowledge brick orchestrator; deletes both keys with retry before custody redirect. | [[Sovereign_Key_Lifecycle_2026-05]], `app_lock_coordinator.dart` |
| BackupMetadataStore | SharedPreferences flag `key_backup_completed_at`; brick pre-flight only (not brick state). | [[Sovereign_Key_Lifecycle_2026-05]] |
| keyCustodyProvider | Riverpod gate: bootstraps keys for new accounts; redirects bricked sessions to `/restore`. | [[Sovereign_Key_Lifecycle_2026-05]], `key_custody_provider.dart` |
| ComplianceNavigation | Opens Terms/Privacy/Guide/Support via `url_launcher` in-app browser (`AppConfig` URLs). | [[Sovereign_Key_Lifecycle_2026-05]], `compliance_navigation.dart` |
| ArchiveContentCategory | Dart enum (`image`, `video`, `audio`, `document`, `archive`, `binary`) derived from MIME; consumer app supports **image + video** only. | `archive_content_category.dart`, [[Institution_Grade_Payload_Seal_Backlog]] |
| content_mime_type | Optional `courier_packages` column; consumer Send Proof sets image/video MIME; institution app may set any type. | migration `20260604120000_courier_payload_metadata_foundation.sql` |
| ENABLE_ARBITRARY_FILE_SEAL | Compile-time flag (default **false**); gates `FileArchiveIngress` for institution-grade arbitrary file import. | `app_config.dart`, `write_flutter_dart_defines.py` |

## Provenance Tracking

* *Initial terminology*: Derived from `raw/sample_llm_wiki_source.md` (2026-04-26)
* *FactLockCam application terminology*: Derived from `wiki/analyses/FactLockCam_Master_Blueprint.md` and `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md` (2026-04-30; updated 2026-05-09; tamper-evident framing 2026-05-10; audit terms 2026-05-11 via [[Project_Audit_2026-05-11]]; dual-mode capture + cold-build defines added 2026-05-11 via [[Master_Context_11MAY2026]]; four-panel archive UX, archive delete, owner-side verified viewing, and `ShutterButtonPainter` added 2026-05-11; Domain Interaction Contract and MIME-aware video thumbnail fallback added 2026-05-12; Heavy Metal UI terms added 2026-05-13 via [[Heavy_Metal_Design_System]])
* *ProofLock terminology*: Derived from `wiki/sources/ProofLock_Architectural_Manifest.md` and `wiki/analyses/ProofLock_Refactor_Scope.md` (2026-05-03)
* *Branding + Polygon saga terms*: `flutter_launcher_icons`, app icon, `SimulatedChainNotarizer` fallback clarification (2026-05-20)
* *App Store prep + capture seal terms*: sidecar staging lock, `sealAndStoreCapture`, Archive UX label, legal bundle (2026-05-21) via [[App_Store_Prep_Capture_Seal_2026-05]]
* *Identity lifecycle terms*: `wallet_history`, historical placeholder, `ProofCourierService`, `perform_full_burn` cascade (2026-05-21) via [[Identity_Lifecycle_And_Data_Lineage]]

* *Send Proof / courier terms* (2026-05-24): `SendProof`, utility rule, **`WEB_ARCHIVE_BASE_URL`** gate, `courier-unlock` via [[Send_Proof_Courier_2026-05]]
* *Production transition terms* (2026-05-24): `APP_ENVIRONMENT`, `SUPPORT_URL`, courier lookup migrations, `setupTestDependencies`, ninth QA **40/40** via [[Production_Transition_2026-05]]

## Related Notes

* [[Production_Transition_2026-05]]
* [[Send_Proof_Courier_2026-05]]
* [[LLM_Wiki_Pattern]]
* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[Identity_Lifecycle_And_Data_Lineage]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[FactLockCam_Master_Blueprint]]
* [[ProofLock_Architectural_Manifest]]
* [[ProofLock_Refactor_Scope]]
* [[Project_Audit_2026-05-11]]
* [[Project_Audit_2026-05-11_Source]]
* [[Master_Context_11MAY2026]]
* [[Heavy_Metal_Design_System]]
