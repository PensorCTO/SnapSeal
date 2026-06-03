---
tags: [concept, factlockcam, key_custody, archive, legal, cloud, burn, lock]
summary: "Canonical custody: keys-only .factlock backup; losing keys loses all encrypted data; Lock vs uninstall vs Burn outcomes."
---

# Data Custody and Backup Model

## Core Synthesis

The **only backup a user can perform** is exporting a password-protected **`.factlock`** file (Account → Export archive keys). That file holds **sovereign decryption keys** (EVM private key + archive AES key)—not photo/video files and not a download of Supabase media.

**Losing keys without a current `.factlock`** means **total loss of access** to every encrypted asset (on-device `.seal` files and blind cloud ciphertext).

Archive AES keys are **stable for the life of an install** (`VaultService._loadOrCreateKeyBytes`); re-export `.factlock` after **Lock prep**, **reinstall prep**, **periodic** discipline, or when you know keys changed—not literally after each capture.

### Storage roles (do not conflate)

| Layer | What it is | User action | Company can decrypt? |
|-------|------------|-------------|----------------------|
| **Local archive** | AES-GCM `.seal` + SQLite in app sandbox | Browse Archive; Download Media / Send Proof when chosen | **No** |
| **`.factlock` key backup** | Encrypted JSON of EVM + archive AES keys | Export archive keys; store offline | **No** — **only** user-managed recovery artifact |
| **Cloud ciphertext** (`factlock_vault`) | Optional post-seal blind upload | Automatic; no dashboard download | **No** — readable only with keys + same account |
| **Courier** (`courier-blobs`) | Send Proof recipient packages | Share sheet | **No** |

### Scenario matrix (authoritative for legal + support)

| Scenario | Local keys | Local `.seal` | Cloud + account | `.factlock` backup |
|----------|------------|---------------|-----------------|-------------------|
| **Normal use** | Present | Present | Present if sync ran | Re-export periodically or before Lock / uninstall |
| **Keys lost** (no `.factlock`) | Gone | **Unreadable** | **Unreadable** | N/A — **permanent loss** |
| **Lock archive** (deliberate brick) | **Purged** (`AppLockCoordinator.lockArchive`) | **Remain on device** | Unchanged on server | **Import** restores keys → local archive readable again |
| **App uninstalled** | Gone (Keychain / sandbox) | Usually gone with app | **Still on server** for same email | **Import after reinstall + sign-in** to decrypt cloud |
| **Burn account** | Purged locally (`burnLocalWallet`) | Wiped locally | **Deleted** (`perform_full_burn` + cascades) | **Useless for that account** — identity and cloud data destroyed |

### Lock vs Burn (critical distinction)

- **Lock** = zero-knowledge brick: keys removed from Secure Storage; **encrypted files stay on device**. Restore with `.factlock` import on `/restore`.
- **Burn** = App Store account deletion: RPC removes linked storage objects and `auth.users`; client wipes local DB, files, and keys. A `.factlock` from **before** burn cannot resurrect **that** Supabase identity or its cloud ciphertext.

### Re-export cadence

1. After first use (before Lock is allowed — `BackupMetadataStore` gate).
2. Before **Lock**, **uninstall**, or when replacing a device.
3. Periodically if you rely on cloud sync after reinstall.
4. **Not** required after every capture (keys do not rotate per seal).

### Implementation anchors

| Behavior | Code / SQL |
|----------|------------|
| Export / import keys | `WalletBackupService`, `FactlockKeystore` |
| Lock purges keys only | `AppLockCoordinator.lockArchive` → `purgeSovereignKeysOnly` |
| Burn remote + local | `perform_full_burn()` → storage loop on `courier_packages`; `auth.users` delete; client `burnLocalWallet` |
| Cloud sync | `VaultSyncCoordinator` → `factlock_vault` paths recorded on `courier_packages` |

### Deprecated legal phrasing (do not use)

- “Back up encrypted assets” / “backing up your encrypted data” without **`.factlock`**
- Implying users export or restore **media** from Supabase
- Treating cloud ciphertext as iCloud Photos–style backup
- Suggesting `.factlock` restores a **burned** account’s cloud archive

### Hosted + in-app legal

| Surface | Path / symbols |
|---------|----------------|
| **Hosted Terms** | `projects/FactLockCam_Site/src/pages/terms.astro` — §6 keys-only, §8 scenario table, §9 Burn irreversible |
| **Privacy / Support** | `privacy.astro` §7; Support FAQs (Lock vs Burn, reinstall, backup) |
| **App disclaimers** | `factlockcam_app/lib/core/legal/disclaimers.dart` — `keyBackupOnlyDisclaimer`, `keyCustodyScenarioSummary`, `lockArchiveDisclaimer`, `accountKeyCustodyBlock`, `archiveOnboardingParagraphs` |
| **UX** | `account_settings_panel.dart`, `burn_account_view.dart`, `restore_archive_view.dart`, `archive_subscription_onboarding_sheet.dart` |
| **Deploy** | `scripts/deploy_factlockcam_site_cf.sh` (payload: `projects/FactLockCam_Site/dist`) |

**Status:** User QA passed 2026-06-03 after hosted deploy + in-app copy alignment.

## Provenance Tracking

* *First QA*: Terms “backup encrypted assets” corrected 2026-06-03.
* *Scenario matrix*: User clarification + twentieth pass 2026-06-03; aligned with Lock/Burn implementation.
* *QA closure*: Device/hosted legal pass 2026-06-03; **82/82** `flutter test`.

## Related Notes

* [[Sovereign_Key_Lifecycle_2026-05]]
* [[Cloud_Vault_Wiring_2026-05]]
* [[Compliance_Refactor_2026-06]]
* [[Identity_Lifecycle_And_Data_Lineage]]
* [[Send_Proof_Courier_2026-05]]
* [[FactLockCam_Product_Baseline_2026-05]]
