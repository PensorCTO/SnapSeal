---
tags: [concept, factlockcam, identity, supabase, archive, polygon]
summary: "Sixth QA (2026-05-21): decouples auth identity from EVM signing keys, tracks wallet lineage, JIT courier uploads, and historical archive placeholders."
---

# Identity Lifecycle & Data Lineage

## Core Synthesis

FactLockCam now treats **Supabase auth identity** (`auth.users` / `profiles.id`) as distinct from **ephemeral EVM signing keys** (`profiles.evm_address`, per-seal `proof_ledger.evm_address`, and `wallet_history`). This closes App Store **5.1.1** burn requirements, supports **multi-wallet rotation** without orphaning ledger rows, and adds **JIT courier upload** scoped to iOS background execution frames.

### Remote schema (`20260521120000_identity_lifecycle.sql`)

| Object | Role |
|--------|------|
| `public.wallet_history` | Append-only lineage when `profiles.evm_address` rotates; `owner_id → profiles.id ON DELETE CASCADE`; RLS `SELECT` for `auth.uid() = owner_id`. |
| `proof_ledger.evm_address` | Signing-origin EVM address captured at seal time (indexed). |
| `archive_rotated_evm_address()` trigger | On `profiles.evm_address` update, archives the prior address into `wallet_history`. |
| `perform_full_burn()` | Purges courier storage objects, then `DELETE FROM auth.users` (cascade through FK graph). |

**Ops:** Applied to hosted project `jqvnwtslmoxjwzusmtxs` via `supabase db push` (2026-05-21 QA).

### Local SQLite (v6)

`archive_items` adds:

- `wallet_address` — EVM address active when the asset was sealed (Polygon path).
- `is_locally_available` — whether encrypted bytes still exist in the app sandbox.

### Domain & application layer

| Component | Path | Responsibility |
|-----------|------|----------------|
| `IArchiveRepository` / `ArchiveRepository` | `lib/features/archive/data/` | Maps rows to `ArchiveAsset`; computes `isLegacyPlaceholder` when `wallet_address != profiles.evm_address`. |
| `currentProfileProvider` | `lib/features/identity/presentation/providers/` | Reads active `profiles.evm_address`. |
| `ProofCourierService` | `lib/features/archive/application/` | JIT upload: `Isolate.run` byte copy + Supabase Storage upload inside background scope. |
| `PlatformChannelCoordinator` | `lib/core/platform/` | iOS `beginBackgroundTask` / `endBackgroundTask`; iOS document picker for restore bytes. |
| `SealLedgerRepository` | `data/supabase/` | Writes `evm_address` on `proof_ledger` insert; `fetchActiveEvmAddress()`. |

`VaultService.createCourierPackage` delegates blob upload to `ProofCourierService` when registered (mobile DI).

### Presentation

- **`ArchiveGridItem`** — If legacy placeholder + missing local file → `RestoreArchiveBanner` (import a **single sealed backup file** for that asset—not a `.factlock` key backup; see [[Data_Custody_And_Backup_Model_2026]]). If legacy but local file present → historical tile (media-type icon, no standard thumbnail pipeline).
- **`OmniGridView`** — Wraps grid cells with `ArchiveGridItem`.

### Cursor rule

`.cursor/rules/prooflock-identity-lifecycle.mdc` — Archive lexicon, multi-wallet UI matrix, burn cascade, JIT isolate restrictions.

### QA (2026-05-21)

- `supabase db push` succeeded; remote lists `identity_lifecycle` migration.
- `flutter build ios --simulator` + simulator launch: **Supabase init completed**, no startup crash.
- `AppDelegate.swift` uses iOS 13–compatible document picker API (`kUTTypeData`) matching deployment target.

### Known gaps

- **Android restore:** platform channel returns `null` for backup picker (iOS only today).
- **Web:** `ArchiveRepository` / `ProofCourierService` not registered in DI (`kIsWeb` guard); web compile still blocked by sqlite3 FFI (pre-existing).
- **Terminology:** User-facing copy uses **Digital Archive**; internal types retain `VaultService` / `VaultDatabase` names per existing refactor convention.

## Provenance Tracking

* *Architecture intent*: Derived from uploaded **System Component Topology & Data Lineage** manifest (2026-05-21 implementation session)
* *Schema*: `supabase/migrations/20260521120000_identity_lifecycle.sql`
* *App code*: `factlockcam_app/lib/features/archive/`, `factlockcam_app/lib/features/identity/`, `factlockcam_app/lib/core/platform/`, `.cursor/rules/prooflock-identity-lifecycle.mdc`
* *QA*: Hosted `db push` + iOS simulator startup verified 2026-05-21

## Related Notes

* [[FactLockCam_Product_Baseline_2026-05]]
* [[Polygon_Saga_Live]]
* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[ProofLock_Refactor_Scope]]
* [[ProofLock_Architectural_Manifest]]
* [[overview]]
