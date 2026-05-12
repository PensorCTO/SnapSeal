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
| SnapSeal | Flutter tamper-evident media vault: seal and verify captures with local AES-GCM vaulting and Supabase ledger replication (risk reduction framing — see [[SnapSeal_Master_Blueprint]]). | [[SnapSeal_Master_Blueprint]] |
| SnapSeal product baseline (2026-05) | Verified logon→hub→archive/capture workflow plus compressed Supabase repair/backfill pointers; canonical status entry. | [[SnapSeal_Product_Baseline_2026-05]] |
| Active-Wallet Ledger | Supabase replica of proof rows for assets still connected to active app wallets. | [[SnapSeal_Master_Blueprint]] |
| Pending Sync | Local SQLite state marking a sealed asset whose remote proof path (`proof_ledger` / RPC pipeline) has not completed; cleared by retry/sync or marked deferred with backoff. | [[SnapSeal_Master_Blueprint]] |
| Courier Payload | Service-layer export of decrypted media after SHA-256 re-verification. | [[SnapSeal_Master_Blueprint]] |
| ProofLock (manifest) | Target architecture and viability bar: TEE-backed signing, Polygon, C2PA, RPC-first ledger/courier; ingested as a wiki source. | [[ProofLock_Architectural_Manifest]] |
| Project audit source (2026-05-11) | Immutable `raw/project_audit_2026-05-11.md`; summary [[Project_Audit_2026-05-11_Source]]; compiled analysis [[Project_Audit_2026-05-11]]. | [[Project_Audit_2026-05-11_Source]] |
| Magic Number (auth) | Supabase email OTP flow using a 6-digit code (`OtpType.email`) in the SnapSeal logon UI. | [[SnapSeal_Master_Blueprint]] |
| Simulated device signature | Base64 payload returned by iOS/Android `signHash` handlers until Secure Enclave / Keystore signing replaces `SIMULATED_DEV|...` placeholders. | [[Project_Audit_2026-05-11]], [[ProofLock_Refactor_Scope]] |
| dart_defines.json (SnapSeal) | Filtered JSON from `scripts/write_flutter_dart_defines.py` / `scripts/sync_flutter_dart_defines.sh` for `flutter run --dart-define-from-file` (typically `SUPABASE_URL` + `SUPABASE_ANON_KEY` only). | [[SnapSeal_Product_Baseline_2026-05]], `snapseal_app/README.md` |
| Pending sync scheduler | `PendingSyncScheduler` (~3 minute interval) triggers `DashboardController.syncPendingInBackground`. | [[Project_Audit_2026-05-11]], [[SnapSeal_Master_Blueprint]] |
| AcquisitionMode | Dart enum (`snapseal_app/lib/ui/views/camera/acquisition_mode.dart`) that distinguishes photo vs video capture intent; threaded through `/camera?mode=photo\|video` and consumed by `CameraView` to toggle audio + recording shutter behavior. | [[Master_Context_11MAY2026]], [[SnapSeal_Master_Blueprint]] |
| Four-panel vault UX | Authenticated UI split into `/vault-home` hub (Archive / Picture / Video), `/archive` Photos/Videos tabs, photo camera, and video camera; replaces the prior mixed `/vault-dashboard` grid. | [[Master_Context_11MAY2026]], [[SnapSeal_Master_Blueprint]] |
| Dual-mode capture (Photo + Video) | **Picture** and **Video** hub actions both flow through the same `VaultService.proofLockFile` seal pipeline, with `video/*` rows rendering native frame thumbnails and a play-arrow badge overlay in the archive. | [[Master_Context_11MAY2026]], [[SnapSeal_Product_Baseline_2026-05]] |
| Archive delete (local) | Per-item archive action that deletes the local SQLite row plus encrypted/thumbnail files from the device; it does not erase remote `proof_ledger` rows. | [[SnapSeal_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| Owner-side verified viewing | Full-size photo viewing (`ArchivePhotoView`) and video playback (`ArchiveVideoView`) decrypt through `VaultService.extractForCourier`, re-verifying the SHA-256 before rendering the original bytes. | [[SnapSeal_Master_Blueprint]], [[Master_Context_11MAY2026]] |
| Cold-build dart-defines rule | Compile-time `--dart-define` values (e.g. `SUPABASE_URL`, `SUPABASE_ANON_KEY`) only refresh on a cold Flutter build; Dart hot-restart keeps stale defines and surfaces "Supabase is not configured yet…". Use `bash scripts/snapseal_supabase_pipeline.sh app-run` (or `flutter run --dart-define-from-file dart_defines.json`) after any `.env.local` / `dart_defines.json` change. | [[Master_Context_11MAY2026]], [[SnapSeal_Product_Baseline_2026-05]] |

## Provenance Tracking

* *Initial terminology*: Derived from `raw/sample_llm_wiki_source.md` (2026-04-26)
* *SnapSeal application terminology*: Derived from `wiki/analyses/SnapSeal_Master_Blueprint.md` and `wiki/concepts/SnapSeal_Product_Baseline_2026-05.md` (2026-04-30; updated 2026-05-09; tamper-evident framing 2026-05-10; audit terms 2026-05-11 via [[Project_Audit_2026-05-11]]; dual-mode capture + cold-build defines added 2026-05-11 via [[Master_Context_11MAY2026]]; four-panel vault UX, archive delete, and owner-side verified viewing added 2026-05-11)
* *ProofLock terminology*: Derived from `wiki/sources/ProofLock_Architectural_Manifest.md` and `wiki/analyses/ProofLock_Refactor_Scope.md` (2026-05-03)

## Related Notes

* [[LLM_Wiki_Pattern]]
* [[SnapSeal_Product_Baseline_2026-05]]
* [[SnapSeal_Master_Blueprint]]
* [[ProofLock_Architectural_Manifest]]
* [[ProofLock_Refactor_Scope]]
* [[Project_Audit_2026-05-11]]
* [[Project_Audit_2026-05-11_Source]]
* [[Master_Context_11MAY2026]]
