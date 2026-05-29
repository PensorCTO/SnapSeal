---
tags: [analysis, factlockcam, cryptography, key_custody, qa, 2026-05]
summary: "Thirteenth QA pass (2026-05-29): multi-key .factlock backup, zero-knowledge lock, restore gate, hardened burn UX, decoupled compliance URLs."
---

# Sovereign Multi-Key Lifecycle (May 2026)

## Core Synthesis

**Thirteenth device QA pass (2026-05-29)** — user-confirmed export → lock → restore round-trip on physical iPhone, plus Account panel layout polish.

### Multi-key custody model

Both sovereign keys travel together through backup, brick, and restore:

| Key | FlutterSecureStorage | Role |
|-----|----------------------|------|
| EVM private key | `factlockcam:evm_private_key` | Identity + Polygon signing |
| Archive AES key | `factlockcam:vault_key` | Local `.seal` decryption |

Bricking only the EVM key leaves archive bytes decryptable from Keychain; restoring only the EVM key leaves historical `.seal` files unreadable.

### `.factlock` export format

- **Inner payload** (AES-GCM encrypted): `{ version, evm_key, vault_key }`.
- **Outer envelope**: PBKDF2 (100k iter) + AES-GCM + HMAC-SHA256 MAC over `salt || iv || ciphertext`.
- **Export UX**: Account → Export archive keys → share sheet (`share_plus`).
- **Import UX**: `/restore` bricked shell → native document picker (`pickFactlockBackupBytes`) → password → rehydrate both keys.

### Zero-knowledge lock (brick)

- Pre-flight: `BackupMetadataStore` requires at least one successful export on device.
- `AppLockCoordinator.lockArchive()` deletes both keys with retry; no SharedPreferences brick flag.
- Supabase session remains; `keyCustodyProvider` + stable `GoRouter` `refreshListenable` redirect to `/restore`.

### Burn UX hardening

- Dedicated **`BurnAccountView`**: acknowledgment checkbox + typed **`OBLITERATE`** before RPC.
- `performFullBurn()` → `perform_full_burn` RPC → `burnLocalWallet()` → `KeyCustodyService.purgeAllLocalKeys()`.

### Account & Settings layout (post-QA polish)

- Legal & Support tiles scroll above fixed bottom action stack (Log out, Export, Lock, Burn).
- `HeavyMetalLogoBanner(includeTopSafeArea: false)` when below `VaultPanelNavigationBar` — removes duplicate status-bar gap.

### Compliance routing (same release train)

- Bundled legal HTML removed; Terms/Privacy/Guide open via **`ComplianceNavigation`** + compile-time URLs (`AppConfig.termsUrl`, etc.).
- Cursor rule: `.cursor/rules/factlockcam-key-lifecycle.mdc`, `.cursor/rules/decoupled-web-routing.mdc`.

### Code anchors

- `factlockcam_app/lib/core/ghost_key/` — `KeyCustodyService`, `FactlockKeystore`, `WalletBackupService`, `AppLockCoordinator`
- `factlockcam_app/lib/ui/mobile/settings/burn_account_view.dart`, `restore_archive_view.dart`
- `factlockcam_app/lib/ui/controllers/key_custody_provider.dart`
- `factlockcam_app/lib/app/router/app_router.dart` — `AppRouterRefreshNotifier`

### Tests

- **`flutter test` 52/52** — adds `factlock_keystore_test`, `key_custody_service_test`, `app_lock_coordinator_test`, `burn_account_view_test`.

## Provenance Tracking

* *Session*: Cursor agent sovereign key lifecycle implementation + QA fixes 2026-05-29.
* *Rule*: `.cursor/rules/factlockcam-key-lifecycle.mdc`

## Related Notes

* [[Identity_Lifecycle_And_Data_Lineage]]
* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[UI_Polish_Hub_Archive_2026-05]]
* [[Production_Transition_2026-05]]
* [[Heavy_Metal_Design_System]]
