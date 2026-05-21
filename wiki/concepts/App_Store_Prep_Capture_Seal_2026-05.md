---
tags: [concept, factlockcam, app_store, capture, vault, qa, sprint5]
summary: "Fifth QA pass (2026-05-21): App Store prep bundle, multi-shot capture hardening, vault I/O fixes, and archive delete/view polish."
---

# App Store Prep & Capture Seal Hardening (2026-05)

## Core Synthesis

**Fifth device QA pass (2026-05-21)** — user-confirmed after iterative fixes to thumbnails, decrypt/view, and delete on physical iPhone.

### App Store & legal

| Deliverable | Location |
|-------------|----------|
| Bundled Terms of Service | `factlockcam_app/assets/legal/TermsOfService.md` |
| Bundled Privacy Policy | `factlockcam_app/assets/legal/PrivacyPolicy.md` |
| Native legal viewer | `factlockcam_app/lib/ui/mobile/settings/legal_document_view.dart` |
| Account panel links | `account_settings_panel.dart` — Legal + Help & Support (`AppConfig.supportWebsiteUrl`) |
| Location permission copy | iOS `Info.plist`, Android `AndroidManifest.xml` (camera geolocation HUD) |

User-facing terminology shift: hub **Vault** tile → **Archive** (internal class names unchanged).

### Capture & multi-shot UX

- **Eager `readAsBytes()`** before background seal — prevents camera temp-file reuse races on rapid shots.
- **`sealAndStoreCapture`** hashes buffered bytes in-memory (no `media.bin` staging); serialized via `_enqueueCaptureSeal`.
- **Camera stays live** after photo; **`ImageFormatGroup.jpeg`** for photo mode; GPS/UTC telemetry on HUD.
- **Nav bar** `shouldFullyObstruct: true` so telemetry is not clipped under Cupertino bar.

### Vault persistence fixes (root causes of QA failures)

1. **MIME sniffing** — magic bytes beat file extension (`HEIC` in `.jpg` temp paths).
2. **HEIC thumbnails** — `ui.instantiateImageCodec` on main isolate → JPEG thumb bytes.
3. **Vault file I/O** — multi-MB ciphertext writes/reads stay on caller isolate (avoid `Isolate.run` payload truncation).
4. **Staging promote** — `AdvisoryFileLock` must **not** open staging payloads with `FileMode.write` (truncates to 0 B before rename). Renames lock a **sidecar** `*.part.lock` file instead ([[Isolate_Lock_Coordinator]]).
5. **Post-persist verify** — decrypt + SHA-256 round-trip on canonical `.seal` path after commit.
6. **Thumbnail cache** — resolves vault paths before disk read (`thumbnail_cache_provider.dart`).
7. **Delete** — `deleteArchiveItem` force-unlocks, purges staging/final/sidecar paths + journal manifest; chronology long-press + inspector **DELETE FROM DEVICE**.

### Send Proof & certificates

- **Proof bundle zip** — `ProofBundleExportService` → temp dir → `SharePlus`.
- **Certificate** — chain tx hash cache in `CertificateExportService`; hash byte decode cache in `WalletService`.

### Key surfaces

| Area | Path |
|------|------|
| Seal pipeline | `factlockcam_app/lib/domain/services/vault_service_io.dart` |
| Locked promote | `factlockcam_app/lib/core/lock/locked_io_runner.dart` |
| Sidecar lock helper | `factlockcam_app/lib/core/lock/advisory_file_lock_io.dart` |
| Vault storage I/O | `factlockcam_app/lib/data/services/local_vault_storage_io.dart` |
| Full-screen viewer | `asset_inspector_screen.dart` (`instantiateImageCodec` for HEIC/JPEG) |
| Tests | `cipher_engine_roundtrip_test.dart`, `locked_rename_test.dart` |

## Provenance Tracking

* *Implementation + QA*: Conversation session 2026-05-21; user-confirmed QA pass after sidecar-lock promote fix.

## Related Notes

* [[FactLockCam_Product_Baseline_2026-05]]
* [[Vault_Transactional_Journal]]
* [[Isolate_Lock_Coordinator]]
* [[FactLockCam_Master_Blueprint]]
* [[iOS_Device_Development_Workflow]]
