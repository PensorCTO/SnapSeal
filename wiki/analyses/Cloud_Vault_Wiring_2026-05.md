---
tags: [analysis, factlockcam, cloud_vault, supabase, capture, 2026-05]
summary: "Twelfth QA: post-notarization cloud archive sync — factlock_vault bucket, VaultSyncCoordinator, isolate encrypt + iOS background upload wired into proofLockFile."
---

# Cloud Archive Wiring (May 2026)

## Core Synthesis

**Twelfth QA pass (2026-05-27):** Capture sealing now synchronizes encrypted ciphertext to Supabase Storage **`factlock_vault`** after local WAL persistence and `proof_ledger` anchoring, but **before** the temporary capture source file is deleted. Plaintext never touches Supabase.

### Execution order (capture seal)

| Step | Component | Operation |
|------|-----------|-----------|
| 1 | `VaultService.proofLockFile` | SHA-256 preflight, device sign, chain notarization |
| 2 | `_persistSealedBytes` | Local AES-GCM archive + journal-backed SQLite row |
| 3 | `SealLedgerRepository` | `proof_ledger` insert / Polygon relay |
| 4 | **`VaultSyncCoordinator`** | Provision `courier_packages` → `Isolate.run` encrypt → background upload |
| 5 | `_deleteSourceAfterSeal` | Unlink temporary capture file |

Cloud sync is **best-effort**: failures (quota, network) do **not** roll back a successful local seal.

### Architecture

```
Camera UI → VaultService → VaultSyncCoordinator
              ↓                    ↓
         proof_ledger      CourierCrypto.encrypt (isolate)
              ↓                    ↓
         local .seal         SupabaseVaultService.uploadEncryptedAsset
                                   ↓
                         factlock_vault/{uid}/{packageId}.enc
```

### Backend (migration `20260527120000_vault_storage.sql`)

| Artifact | Role |
|----------|------|
| `factlock_vault` bucket | Private Storage; 50MB object limit; `application/octet-stream` only |
| `courier_packages.file_size_bytes` | Plaintext size metadata for quota / ops |
| Storage RLS | Owner upload scoped to `{auth.uid()}/…`; recipient read gated by unlock + download quota |
| Remote sync | **21/21** migrations (local = remote) after push |

**Distinct from Send Proof:** Owner-initiated courier sharing still uploads pre-sealed `.seal` blobs to **`courier-blobs`** via `ProofCourierService`. Cloud vault backs up **raw capture bytes** (re-encrypted for cloud envelope) for restore-after-rebuild.

### Flutter modules

| Path | Role |
|------|------|
| `lib/application/vault/vault_sync_coordinator.dart` | Orchestrates package RPC → isolate encrypt → `IPlatformChannelCoordinator` background upload |
| `lib/core/cloud/supabase_vault_service.dart` | Ciphertext PUT + `courier_packages` metadata update |
| `lib/core/crypto/courier_crypto.dart` | Added `encrypt()` — SHA-256 password derive → AES-GCM |
| `lib/core/errors/exceptions.dart` | `QuotaExceededException` |
| `lib/domain/services/vault_service_io.dart` | `_attemptCloudVaultSync` after ledger commit |
| `lib/core/di/injection.dart` | GetIt: `SupabaseVaultService`, `VaultSyncCoordinator` |

### Cursor rules

- `.cursor/rules/supabase-cloud-vault.mdc` — zero-knowledge, RLS, egress limits
- `.cursor/rules/factlockcam-wiring.mdc` — sequencing, background task, GetIt-only DI

### Tests

| Test | Status |
|------|--------|
| `test/cloud_vault_e2e_test.dart` | **Pass** — isolate encrypt + upload contract (mocked Storage) |
| `integration_test/cloud_vault_e2e_test.dart` | Delegates to smoke test; device QA: `-d <ios-id>` |
| User QA | **Pass** (owner confirmation 2026-05-27) |

### Verification checklist (device)

1. Capture + seal with Supabase configured and authenticated user.
2. Supabase Dashboard → Storage → `factlock_vault` → `{userId}/{packageId}.enc`.
3. `courier_packages`: `storage_bucket = factlock_vault`, `file_size_bytes` populated.

## Provenance Tracking

* *Implementation*: Agent session 2026-05-27; architectural manifest (C4 context + wiring blueprint) from owner.
* *Code*: `vault_sync_coordinator.dart`, `supabase_vault_service.dart`, `vault_service_io.dart`, `20260527120000_vault_storage.sql`, `courier_crypto.dart`.
* *QA*: Owner-confirmed pass 2026-05-27.

## Related Notes

* [[Send_Proof_Courier_2026-05]]
* [[Production_Transition_2026-05]]
* [[Identity_Lifecycle_And_Data_Lineage]]
* [[Archive_Transactional_Journal]]
* [[FactLockCam_Product_Baseline_2026-05]]
