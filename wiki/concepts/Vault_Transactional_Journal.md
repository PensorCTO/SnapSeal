---
tags: [concept, factlockcam, sqlite, journal, integrity, sprint2]
summary: "Sprint 2 local vault integrity: WAL journal DB, prepare/commit/rollback, boot recovery, and sqflite archive single-flight."
---

# Vault Transactional Journal (Sprint 2)

## Core Synthesis

FactLockCam now treats **sealed asset persistence** as a two-database saga on mobile:

1. **`factlockcam_journal.db`** (`sqlite3` + WAL) — `journal_log` (prepare → commit / rolled_back) and `asset_manifest` (final paths after commit).
2. **`factlockcam_vault.db`** (`sqflite`) — `archive_items` UI metadata (unchanged schema v5).

`TransactionalVaultPersister` writes encrypted bytes to **staging `*.part` paths**, atomically renames to vault finals (locking a **sidecar `*.part.lock`** — never open staging payloads with `FileMode.write` or promote truncates to 0 bytes), then commits the journal and **`upsertArchiveItem`**. On failure it purges staging/final/sidecar paths and marks the journal row rolled back.

**Vault I/O (May 2026):** Multi-MB ciphertext **writes and reads run on the caller isolate** (`writeAsBytesSync` / `readAsBytes`); crypto stays in `Isolate.run`. Do not copy sealed payloads through worker isolates — truncation caused decrypt/thumbnail QA failures.

**Boot recovery** runs in `main.dart` **before** `configureDependencies()` / `runApp()`: `BootRecoveryService` rolls back any `prepared` journal rows and deletes orphan staging/final files from interrupted seals.

**Concurrency hardening (May 2026 QA):** `VaultDatabase` uses single-flight `openDatabase`; DI eagerly opens vault + journal on native targets so hub list + capture upsert do not race. `upsertArchiveItem` retries on SQLite busy/locked.

## Key surfaces

| Artifact | Path |
|----------|------|
| Journal factory (WAL PRAGMAs) | `factlockcam_app/lib/core/journal/journal_database_factory_io.dart` |
| Repository | `factlockcam_app/lib/core/journal/journal_repository.dart` |
| Persister | `factlockcam_app/lib/core/journal/transactional_vault_persister.dart` |
| Boot runner | `factlockcam_app/lib/core/journal/boot_recovery_runner_io.dart` |
| Storage staging | `factlockcam_app/lib/data/services/local_vault_storage_io.dart` |
| DI wiring | `factlockcam_app/lib/core/di/injection.dart` |
| Tests | `factlockcam_app/test/journal_wal_recovery_test.dart`, `locked_rename_test.dart` |

Web targets skip the journal layer (`TransactionalVaultPersister` is null on web).

**Sprint 4 (reactive UI):** `TransactionalVaultPersister` calls `IsolateLockCoordinator.lock`/`unlock` around each transaction; see [[Isolate_Lock_Coordinator]].

## Provenance Tracking

* *Design and implementation*: Conversation + branch `cursor/wiki-supabase-local-reset-audit` (2026-05-21); QA-verified capture + Polygon insert on physical iPhone after SQLite race fix.

## Related Notes

* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[FactLockCam_Master_Blueprint]]
* [[Isolate_Lock_Coordinator]]
* [[Polygon_Saga_Live]]
* [[Polygon_Try1_Postmortem]]
