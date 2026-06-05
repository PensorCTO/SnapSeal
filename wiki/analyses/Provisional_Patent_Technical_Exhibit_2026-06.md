---
tags: [analysis, factlockcam, patent, enablement, cryptography, june_2026]
summary: "Technical exhibit for pro se provisional filing: transactional journal, isolate lock coordinator, async Polygon anchoring, ZK courier."
---

# Provisional Patent Technical Exhibit (2026-06)

## Core Synthesis

Enablement-oriented technical summary (35 U.S.C. § 112) of FactLockCam's zero-trust capture and distribution architecture. Not consumer marketing copy.

---

## I. Transactional Journal & Crash-Safety

**Components:** `factlockcam_journal.db` (sqlite3 WAL), `factlockcam_vault.db` (sqflite), `TransactionalArchivePersister`, `BootRecoveryService`.

### Inputs

- `assetFingerprint` (SHA-256 content hash)
- `encryptedBytes`, `thumbnailBytes`, `rawByteLength`, `mimeType`
- Staging paths `*.part` and sidecar `*.part.lock`

### Outputs

- Committed journal row (`committed`)
- Final encrypted files at archive paths
- `archive_items` SQLite row via `upsertArchiveItem`

### Process

1. **Prepare** journal row (`prepared`) with target paths.
2. **Write** ciphertext to staging via `writeAsBytesSync` on caller isolate (never `FileMode.write` on staging payload — prevents truncate-to-zero).
3. **Lock** sidecar `*.part.lock` with POSIX exclusive advisory lock.
4. **Rename** staging → final atomically.
5. **Commit** journal + upsert metadata; on failure **rollback** and purge staging/final/sidecar paths.

`BootRecoveryService` runs before `runApp()`: rolls back all `prepared` rows and deletes orphan files from interrupted seals.

### Expected Failure Modes

| Failure | Behavior |
|---------|----------|
| Mid-write power loss | Boot recovery rolls back `prepared`; partial staging deleted |
| Staging truncate bug | Prevented by sidecar-lock promote pattern |
| SQLite busy | `upsertArchiveItem` retries on locked/busy |
| Web target | Journal layer skipped (`TransactionalArchivePersister` null) |

---

## II. Isolate Lock Coordinator & UI Coherence

**Components:** `IsolateLockCoordinator`, `AssetLockNotifier`, `AssetSecuringOverlay`, `AdvisoryFileLock`, `locked_io_runner.dart`.

### Inputs

- `fileId` (= `assetFingerprint`)
- Worker `SendPort` messages `{fileId, isProcessing}`
- Persister prepare/commit window

### Outputs

- `lockStream` events (`LockState.processing` / `idle`)
- `isFileLocked(fileId)` synchronous cache
- UI overlay **SECURING FILE…** on chronology/omni tiles

### Process

Main-isolate coordinator holds one UI lock for full prepare→commit window. Workers send port notifications; reads throw `AssetFileLockedException` while locked. `syncLocksFromPreparedJournal` re-locks UI after boot recovery for surviving `prepared` rows.

### Expected Failure Modes

| Failure | Behavior |
|---------|----------|
| Concurrent read during write | `AssetFileLockedException` fast-fail |
| Worker port message malformed | Ignored (no state mutation) |
| Duplicate lock | No duplicate stream events |

---

## III. Asynchronous Polygon Mainnet Anchoring

**Components:** `ArchiveService._proofLockFilePolygonSaga`, `PolygonChainNotarizer`, `anchor-relay` Edge Function, `NotarizationMonitorService`.

### Inputs

- Raw media bytes (isolate-hashed SHA-256)
- Device signature (Secure Enclave / Keystore `signHash`)
- EIP-191 EVM owner signature (`PolygonWalletService`)
- JWT-authenticated relay request

### Outputs

- Local AES-GCM encrypted archive + SQLite row
- `proof_ledger` row `pending_notarization` → finalized with `chain_tx_hash`
- Certificate draft includes ledger transaction hash
- UI: **Generating Proof…** overlay (not blockchain jargon)

### State Machine

`Draft` → `pending_notarization` → `Notarized` | `Collision`

### Process

1. `check_proof_status` pre-flight (collision detection).
2. Isolate hash + dual signing.
3. Local persist via transactional journal.
4. `proof_ledger` INSERT.
5. **Await** `anchor-relay` (live Polygon `notarize(bytes32)` when secrets configured).
6. Persist `chain_tx_hash` locally; clear `pending_sync`.
7. `NotarizationMonitorService` Realtime + optional RPC receipt polling.

**Contract (mainnet):** `0x83508c78104b8b58ff844EE5654FaaC06cFFc155`

### Expected Failure Modes

| Failure | Behavior |
|---------|----------|
| Hash collision | `ProofLockConflictException`; no local seal treated as unique |
| Relay unreachable | `pending_sync` retained; retry worker |
| Missing relay secrets | HTTP 500; no sim-hash fallback |
| Receipt polling timeout | Monitor retains `pendingNotarization` badge |

---

## IV. Zero-Knowledge Courier Distribution

**Components:** `ProofCourierService`, `get_or_create_courier_package`, `courier-unlock`, `CourierCrypto.decryptAndVerifyFingerprint`.

### Inputs

- Encrypted `.seal` blob (AES-GCM)
- Verifier password (hashed server-side)
- Encoded archive key (returned only after successful unlock)

### Outputs

- `courier-blobs` storage object at `{owner_id}/{assetHash}.seal`
- Recipient browser decrypt + SHA-256 fingerprint verify
- Courier URL `{WEB_ARCHIVE_BASE_URL}/courier?pkg={uuid}`

### Decoupling

- **Local archive AES key** (device-sovereign) ≠ **courier verifier secret** (share-sheet password).
- Server stores encrypted blob + encoded key; plaintext media never required on server for ZK positioning.

### Expected Failure Modes

| Failure | Behavior |
|---------|----------|
| 5 failed verifier attempts | Package burned; blob deleted |
| Download quota exceeded | RPC lock |
| Quarantined (UGC scan) | Unlock rejected generically |

## Provenance Tracking

* *Sources*: [[Archive_Transactional_Journal]], [[Isolate_Lock_Coordinator]], [[Polygon_Saga_Live]], [[UGC_Safety_Reporting_2026-06]] (2026-06-05).

## Related Notes

* [[ProofLock_Refactor_Scope]]
* [[Polygon_Mainnet_Wiring_2026-05]]
* [[Data_Custody_And_Backup_Model_2026]]
