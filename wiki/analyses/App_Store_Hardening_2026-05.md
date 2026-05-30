---
tags: [analysis, factlockcam, app_store, security, native, qa, 2026-05]
summary: "Fifteenth QA pass (2026-05-30): architectural manifest remediation — compile-time gates, hardware signing MVP, sync/delete hardening, DI cleanup, 55/55 tests."
---

# App Store Hardening (May 2026)

## Core Synthesis

**Fifteenth device QA pass (2026-05-30)** — user-confirmed after implementing the **FactLockCam Architectural Remediation** blueprint (configuration boundary, platform-channel semantics, native TEE signing, test harness).

This pass closes audit gaps called out for **App Store ingestion**: no simulated device signatures in production native targets, no treating `MissingPluginException` as recoverable network deferrals, and no empty Supabase compile-time defines after a stub `generated_dart_defines.dart` reset.

### Configuration boundary

| Define / artifact | Role |
|-------------------|------|
| `ENABLE_PROOF_LINKS` | Compile-time gate for Send Proof / `createCourierPackage`; default **`false`** for submission until archive TLS verified |
| `WEB_ARCHIVE_BASE_URL` | Unchanged canonical courier origin (`AppConfig.webArchiveBaseUrl`) |
| `POLYGON_RPC_URL` | `AppConfig.polygonRpcUrl` uses `GeneratedDartDefines` fallback **debug only**; release/profile return null if unset |
| `generated_dart_defines.dart` | Gitignored; populated by `scripts/sync_flutter_dart_defines.sh` from `.env.local` |
| `generated_dart_defines.stub.dart` | Committed safe empty Supabase fallbacks for clean clones |
| `factlockcam_app/run_device.sh` | Sync + `flutter run --dart-define-from-file=dart_defines.json` |

**Device login pitfall:** Plain `flutter run` without sync leaves empty `SUPABASE_URL` / `SUPABASE_ANON_KEY` in generated fallbacks → logon shows config notice. Fix: run sync or `./run_device.sh`, then **full restart** (compile-time constants).

### Sync and delete semantics (`vault_service_io.dart`)

- `_isRecoverableRemoteFailure`: `MissingPluginException` → **terminal** (no `pending_sync` deferral).
- `deleteArchiveItem`: SQLite row delete → journal `purgeAsset` → disk `purgePaths` (DB-first consistency).
- `reloadVaultKey`: reads and decodes sovereign AES key; throws if missing after `.factlock` restore.

### Dependency injection

- `VaultService` constructor injects `KeyCustodyService`, `IsolateLockCoordinator`, `JournalRepository` (no `getIt` in domain methods).
- UI bridges: `walletBackupServiceProvider`, `backupMetadataStoreProvider`, `appLockCoordinatorProvider`, `platformChannelCoordinatorProvider`, `courierRepositoryProvider` in `service_providers.dart`.

### Native hardware signing (I2)

| Platform | Implementation |
|----------|----------------|
| iOS | [`EnclaveSigner.swift`](../../factlockcam_app/ios/Runner/EnclaveSigner.swift) — P-256 Secure Enclave, ECDSA over SHA-256 hex digest, base64 signature |
| Android | [`DeviceEnclaveSigner.kt`](../../factlockcam_app/android/app/src/main/kotlin/com/factlockcam/app/DeviceEnclaveSigner.kt) — `AndroidKeyStore` secp256r1, StrongBox when available |

`SIMULATED_DEV|...` payloads **removed** from native release paths. `REQUIRE_HARDWARE_ATTESTATION` rejects simulated signatures in release/profile when enabled.

`anchor-relay` still validates **owner** EIP-191 signature; `device_signature` is stored for forensic continuity — server-side P-256 verify is follow-up work.

### Tests and rules

- `flutter test` **55/55** (adds MissingPlugin, delete-order, video platform mock tests).
- `.cursor/rules/factlock-remediation.mdc` — secrets, `MissingPluginException`, DI, async naming guardrails.

### Submission checklist (incremental)

1. `./scripts/sync_flutter_dart_defines.sh` — `ENABLE_PROOF_LINKS=false` until archive live.
2. `./scripts/verify_web_archive_deploy.sh` — then flip `ENABLE_PROOF_LINKS=true`.
3. Xcode Organizer → Generate Privacy Report after enclave Keychain work.
4. Physical device QA: seal, retry, restore, burn (iOS + Android).

## Provenance Tracking

* *Blueprint*: User architectural manifest + remediation plan session 2026-05-30.
* *Code*: `app_config.dart`, `vault_service_io.dart`, `EnclaveSigner.swift`, `DeviceEnclaveSigner.kt`, `service_providers.dart`, `run_device.sh`, `write_flutter_dart_defines.py`.
* *QA*: User-confirmed device pass after Swift `try` fix and Supabase defines sync.

## Related Notes

* [[App_Store_Remediation_2026-05]]
* [[Production_Transition_2026-05]]
* [[ProofLock_Refactor_Scope]]
* [[Polygon_Mainnet_Wiring_2026-05]]
* [[Sovereign_Key_Lifecycle_2026-05]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[log]]
