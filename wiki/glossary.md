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
| FactLockCam | Flutter tamper-evident media vault: seal and verify captures with local AES-GCM vaulting and Supabase ledger replication (risk reduction framing — see [[FactLockCam_Master_Blueprint]]). | [[FactLockCam_Master_Blueprint]] |
| FactLockCam product baseline (2026-05) | Verified logon→hub→archive/capture workflow plus compressed Supabase repair/backfill pointers; canonical status entry. | [[FactLockCam_Product_Baseline_2026-05]] |
| Active-Wallet Ledger | Supabase replica of proof rows for assets still connected to active app wallets. | [[FactLockCam_Master_Blueprint]] |
| Pending Sync | Local SQLite state marking a sealed asset whose remote proof path (`proof_ledger` / RPC pipeline) has not completed; cleared by retry/sync or marked deferred with backoff. | [[FactLockCam_Master_Blueprint]] |
| Courier Payload | Service-layer export of decrypted media after SHA-256 re-verification. | [[FactLockCam_Master_Blueprint]] |
| ProofLock (manifest) | Target architecture and viability bar: TEE-backed signing, Polygon, C2PA, RPC-first ledger/courier; ingested as a wiki source. | [[ProofLock_Architectural_Manifest]] |
| Project audit source (2026-05-11) | Immutable `raw/project_audit_2026-05-11.md`; summary [[Project_Audit_2026-05-11_Source]]; compiled analysis [[Project_Audit_2026-05-11]]. | [[Project_Audit_2026-05-11_Source]] |
| Magic Number (auth) | Supabase email OTP flow using a 6-digit code (`OtpType.email`) in the FactLockCam logon UI. | [[FactLockCam_Master_Blueprint]] |
| Simulated device signature | Base64 payload returned by iOS/Android `signHash` handlers until Secure Enclave / Keystore signing replaces `SIMULATED_DEV|...` placeholders. | [[Project_Audit_2026-05-11]], [[ProofLock_Refactor_Scope]] |
| dart_defines.json (FactLockCam) | Filtered JSON from `scripts/write_flutter_dart_defines.py` / `scripts/sync_flutter_dart_defines.sh` for `flutter run --dart-define-from-file` (typically `SUPABASE_URL` + `SUPABASE_ANON_KEY` only). | [[FactLockCam_Product_Baseline_2026-05]], `factlockcam_app/README.md` |
| Pending sync scheduler | `PendingSyncScheduler` (~3 minute interval) triggers `DashboardController.syncPendingInBackground`. | [[Project_Audit_2026-05-11]], [[FactLockCam_Master_Blueprint]] |
| AcquisitionMode | Dart enum (`factlockcam_app/lib/ui/mobile/camera/acquisition_mode.dart`) distinguishing photo vs video capture; consumed by `CameraView` in `VaultHomeView` to toggle audio and recording shutter behavior. | [[FactLockCam_Master_Blueprint]] |
| Shutter Iris | Mechanical iris capture control rendered by `ShutterIrisPainter`: titanium outer ring, six animated aperture blades, Kinetic Green active recording fill, and Verified Neon seal-complete flash. | [[Heavy_Metal_Design_System]] |
| Titanium Deep | Primary heavy-metal UI background token (`#121212`) used to avoid pure-black flatness while keeping the app visually industrial and high contrast. | [[Heavy_Metal_Design_System]] |
| Verified Neon | Completed locked/verified green token (`#39FF14`), reserved for successful verification, locked states, and primary trust calls to action. | [[Heavy_Metal_Design_System]] |
| Kinetic Green | Active/in-progress green token (`#00D26A`) used for recording, active lock motion, and other live process states. | [[Heavy_Metal_Design_System]], [[Master_Context_11MAY2026]] |
| ShutterButtonPainter | **DEPRECATED** — Legacy original custom camera shutter painter: white 2 px stroked outer ring, transparent center at rest, 150 ms white photo snap, and Kinetic Green fill while video recording. Superseded by `ShutterIrisPainter`. | [[Master_Context_11MAY2026]], [[FactLockCam_Master_Blueprint]], [[Heavy_Metal_Design_System]] |
| Lazy camera mount | `VaultHomeView._cameraPanel()` builds `CameraView` only when its panel index is active; inactive slots use `SizedBox.shrink()`. Prevents dual hidden cameras from initializing on hub load (physical iOS QA). PR0, 2026-05-20 — [[Polygon_Try1_Postmortem]]. | `vault_home_view.dart` |
| Hub-first vault shell | Authenticated shell at `/vault-home`: `IndexedStack` index 0 = `HapticHubPanel` (Vault, Picture, Video, Account & Settings); 1–2 = lazy-mounted photo/video `CameraView`; 3 = archive omni; 4 = account. Panel back → hub. Replaces `ProfessionalNavBar` and standalone `/camera`. | [[FactLockCam_Master_Blueprint]], [[Polygon_Try1_Postmortem]] |
| Four-panel vault UX | **Deprecated term** — use **Hub-first vault shell**. Historically described `ProfessionalNavBar` bottom tabs; current tree uses hub tiles + panel back navigation only. | [[FactLockCam_Master_Blueprint]] |
| Dual-mode capture (Photo + Video) | **Picture** and **Video** hub actions both flow through the same `VaultService.proofLockFile` seal pipeline, with `video/*` rows rendering native frame thumbnails and a play-arrow badge overlay in the archive. | [[Master_Context_11MAY2026]], [[FactLockCam_Product_Baseline_2026-05]] |
| Archive delete (local) | Per-item archive action that deletes the local SQLite row plus encrypted/thumbnail files from the device; it does not erase remote `proof_ledger` rows. | [[FactLockCam_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| Owner-side verified viewing | Full-size photo viewing (`ArchivePhotoView`) and video playback (`ArchiveVideoView`) decrypt through `VaultService.extractForCourier`, re-verifying the SHA-256 before rendering the original bytes. | [[FactLockCam_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| Cold-build dart-defines rule | Compile-time `--dart-define` values (e.g. `SUPABASE_URL`, `SUPABASE_ANON_KEY`) only refresh on a cold Flutter build; Dart hot-restart keeps stale defines and surfaces "Supabase is not configured yet...". Use `bash scripts/factlockcam_supabase_pipeline.sh app-run` (or `flutter run --dart-define-from-file dart_defines.json`) after any `.env.local` / `dart_defines.json` change. | [[Master_Context_11MAY2026]], [[FactLockCam_Product_Baseline_2026-05]] |
| Domain Interaction Contract | Archive action architecture that maps each asset's `mediaType` / SQLite `mime_type` to allowed `MediaActionType`s through `AssetActionRegistry`, then renders them via `UniversalAssetToolbar` and executes service work through the `AssetAction` Riverpod notifier. | [[FactLockCam_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| UniversalAssetToolbar | Cupertino action-sheet widget for media assets; delegates view/verify/delete/share/export affordances to `AssetActionRegistry` instead of hardcoding delete/play/verify buttons per archive view. | [[FactLockCam_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| MIME-aware video thumbnail fallback | `VaultService` behavior that preserves video format hints when regenerating thumbnails from decrypted bytes by using temp-file extensions such as `.mov`, `.webm`, and `.mp4` based on `mimeType`. | [[FactLockCam_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| AES-GCM | Authenticated encryption algorithm used by `CipherEngine` / `VaultEncryptionHandler` for local vault encryption of sealed media. | [[FactLockCam_Master_Blueprint]], [[ProofLock_Refactor_Scope]] |
| C2PA | Coalition for Content Provenance and Authenticity -- an open standard for cryptographically signing media provenance metadata. Referenced as a future ProofLock viability track; not yet implemented. | [[ProofLock_Refactor_Scope]], [[ProofLock_Architectural_Manifest]] |
| PolygonChainNotarizer | Unimplemented `ChainNotarizer` adapter that would submit hashes to Polygon for durable on-chain anchoring. Currently throws `UnsupportedError`; keep `USE_POLYGON_NOTARIZER=false`. | `chain_notarizer.dart`, [[ProofLock_Refactor_Scope]] |
| ProofLockConflictException | Custom exception thrown by `VaultService.proofLockFile` when `check_proof_status` RPC returns a status other than `new` (i.e., the hash already exists in the ledger). | [[FactLockCam_Master_Blueprint]], [[FactLockCam_Blueprints_14May2026]] |
| proof_ledger | Supabase table storing sealed asset proof rows: `asset_hash`, `device_signature`, `chain_tx_hash`, and wallet linkage. The primary remote proof surface after the simulated-chain migration. | [[FactLockCam_Blueprints_14May2026]], [[FactLockCam_Master_Blueprint]] |
| REQUIRE_HARDWARE_ATTESTATION | Dart compile-time define (`--dart-define`) for gating hardware-backed attestation in the seal pipeline. Defined in `AppConfig` but **not yet wired** into control flow. | [[FactLockCam_Master_Blueprint]], [[FactLockCam_Blueprints_14May2026]] |
| RLS (Row Level Security) | PostgreSQL feature used on all Supabase tables (`proof_ledger`, `seal_ledger`, `courier_packages`, storage buckets) to scope data access by `auth.uid()`. | [[FactLockCam_Blueprints_14May2026]], [[MASTER_CONTEXT13MAY2026]] |
| RPC (Remote Procedure Call) | Supabase PostgREST function calls (`rpc()`) used for gating sensitive operations like `check_proof_status`, `simulate_chain_notarize`, `attempt_courier_unlock`, and `get_or_create_courier_package`. | [[FactLockCam_Blueprints_14May2026]], [[MASTER_CONTEXT13MAY2026]] |
| SealLedgerRepository | Dart repository class (`data/supabase/seal_ledger_repository.dart`) wrapping Supabase RPC and table operations for proof preflight, notarization simulation, ledger inserts, and courier blob uploads. | [[FactLockCam_Blueprints_14May2026]], [[FactLockCam_Master_Blueprint]] |
| SHA-256 | Cryptographic hash algorithm used by `VaultService` to fingerprint original media bytes (via `Isolate.run`) for integrity verification, duplicate detection (`check_proof_status`), and chain anchoring. | [[FactLockCam_Blueprints_14May2026]], [[FactLockCam_Master_Blueprint]] |
| SimulatedChainNotarizer | Active default `ChainNotarizer` that delegates to the `simulate_chain_notarize` Supabase RPC, writing to `simulated_chain_ledger`. Stand-in for Polygon until `PolygonChainNotarizer` is implemented. | `chain_notarizer.dart`, [[ProofLock_Refactor_Scope]] |

## Provenance Tracking

* *Initial terminology*: Derived from `raw/sample_llm_wiki_source.md` (2026-04-26)
* *FactLockCam application terminology*: Derived from `wiki/analyses/FactLockCam_Master_Blueprint.md` and `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md` (2026-04-30; updated 2026-05-09; tamper-evident framing 2026-05-10; audit terms 2026-05-11 via [[Project_Audit_2026-05-11]]; dual-mode capture + cold-build defines added 2026-05-11 via [[Master_Context_11MAY2026]]; four-panel vault UX, archive delete, owner-side verified viewing, and `ShutterButtonPainter` added 2026-05-11; Domain Interaction Contract and MIME-aware video thumbnail fallback added 2026-05-12; Heavy Metal UI terms added 2026-05-13 via [[Heavy_Metal_Design_System]])
* *ProofLock terminology*: Derived from `wiki/sources/ProofLock_Architectural_Manifest.md` and `wiki/analyses/ProofLock_Refactor_Scope.md` (2026-05-03)

## Related Notes

* [[LLM_Wiki_Pattern]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[FactLockCam_Master_Blueprint]]
* [[ProofLock_Architectural_Manifest]]
* [[ProofLock_Refactor_Scope]]
* [[Project_Audit_2026-05-11]]
* [[Project_Audit_2026-05-11_Source]]
* [[Master_Context_11MAY2026]]
* [[Heavy_Metal_Design_System]]
