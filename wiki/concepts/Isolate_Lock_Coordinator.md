---
tags: [concept, factlockcam, sprint4, vault, ui, isolates, concurrency]
summary: "Sprint 4: UI lock stream and advisory file locks keep archive tiles coherent while transactional vault writes run off the UI thread."
---

# Isolate Lock Coordinator (Sprint 4)

## Core Synthesis

While `TransactionalVaultPersister` stages `*.part` files and atomically renames to vault finals ([[Vault_Transactional_Journal]]), the archive must not read half-written bytes or show broken thumbnails. Sprint 4 adds a **main-isolate lock coordinator** and **Riverpod overlays** without violating the no-`bloc` / no-direct-Supabase-in-UI rules.

| Layer | Responsibility |
|-------|----------------|
| `IsolateLockCoordinator` | `lock`/`unlock` around persister transactions; optional `SendPort` maps from workers; `lockStream` + `isFileLocked` cache |
| `AssetLockNotifier` | `assetLockStateProvider` — watched from `FactLockCamApp` |
| `AssetSecuringOverlay` | Chronology + omni grid tiles show **SECURING FILE…** while locked |
| `AdvisoryFileLock` | `RandomAccessFile.lockSync(FileLock.exclusive)` in crypto isolates (POSIX-backed on iOS) |
| `syncLocksFromPreparedJournal` | After DI journal open, re-locks UI for any surviving `prepared` rows (post–`BootRecoveryService`) |
| `AssetFileLockedException` | Domain reads with `assetFingerprint` fail fast while locked |

**Design choice:** Persister holds one UI lock for the full prepare→commit window; isolate workers only enforce file locks (no per-chunk port unlock flicker).

## Key surfaces

| Artifact | Path |
|----------|------|
| Coordinator | `factlockcam_app/lib/core/lock/isolate_lock_coordinator.dart` |
| Journal sync | `factlockcam_app/lib/core/lock/lock_journal_sync.dart` |
| Advisory lock (IO) | `factlockcam_app/lib/core/lock/advisory_file_lock_io.dart` |
| Locked isolate I/O | `factlockcam_app/lib/core/lock/locked_io_runner.dart` |
| Riverpod bridge | `factlockcam_app/lib/ui/providers/asset_lock_provider.dart` |
| Overlay widget | `factlockcam_app/lib/ui/mobile/vault/widgets/asset_securing_overlay.dart` |
| DI | `factlockcam_app/lib/core/di/injection.dart` |
| Tests | `factlockcam_app/test/isolate_lock_coordinator_test.dart` |
| App Store / QA | `docs/app_store_submission_checklist.md`, `ios/Runner/PrivacyInfo.xcprivacy` |

Web: coordinator registers globally; transactional storage/locks are mobile-only.

## Provenance Tracking

* *Implementation + fourth QA pass*: Branch `cursor/wiki-supabase-local-reset-audit` (2026-05-21); user-confirmed Sprint 4 QA pass before commit.

## Related Notes

* [[Vault_Transactional_Journal]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[ProofLock_Refactor_Scope]]
