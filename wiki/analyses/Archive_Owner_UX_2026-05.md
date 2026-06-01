---
tags: [analysis, factlockcam, archive, ux, send_proof, qa, 2026-05]
summary: "Sixteenth QA pass (2026-05-30): Download Media, certificate metadata from asset, unified View/Play labels, debug Send Proof gate."
---

# Archive Owner UX (May 2026)

## Core Synthesis

**Sixteenth device QA pass (2026-05-30)** — user-confirmed after archive interaction refinements: owner-side **Download Media**, Send Proof certificate fields sourced from stored metadata, and consistent **View/Play media** labeling across picture and video.

### Download Media (plaintext owner export)

| Surface | Entry |
|---------|--------|
| Action sheet (grid tap, chronology **⋯**) | Primary row **Download Media** (`MediaActionType.export`) |
| Asset inspector | **DOWNLOAD MEDIA** tile (mobile only) |
| Web | Hidden — `extractForCourier` is mobile-only |

Flow: `VaultService.extractForCourier` → temp file with MIME extension (`archive_media_extension.dart`) → iOS share sheet (`shareDecryptedArchiveMedia` in `archive_media_download_io.dart`). No `proof_ledger` mutation; no permanent unencrypted archive copy.

### Send Proof certificate metadata

- Dialog collects **recipient password only** (title/description fields removed).
- PDF uses `ArchiveItem.title` / `description` via `CertificateExportService._resolveTitle` / `_resolveDescription` (no `titleOverride` on send path).
- `showSendProofDialog` resolves fresh metadata from `dashboardControllerProvider` before `SendProofRequest`.

### Unified view labels

- Toolbar: **View/Play media** for photos and videos (`universal_asset_toolbar.dart`).
- Inspector: **VIEW/PLAY MEDIA** (replaces “View Full Asset”).
- Hub **Picture** / **Video** capture tiles unchanged (acquisition only).

### Chronology discoverability

Default archive mode is **chronology** (tap card → inspector). Sixteenth QA adds a top-left **⋯** on `ChronologyCard` to open the same action sheet as grid view (Send Proof, Download Media, etc.).

### `ENABLE_PROOF_LINKS` debug QA fix

Submission builds keep `ENABLE_PROOF_LINKS=false` in `dart_defines.json`. **Debug** device runs enable Send Proof when `WEB_ARCHIVE_BASE_URL` is configured, even if the define is `false` — avoids blocking QA while App Store gate stays off in release/profile.

Explicit `ENABLE_PROOF_LINKS=true` always enables; release/profile honor `false` until archive verification.

### Tests

- `flutter test` **55/55** (`archive_asset_actions_test` expects Download Media + View/Play media).

## Provenance Tracking

* *Owner request*: Archive UX plan session 2026-05-30 (download, certificate metadata, label parity).
* *Code*: `archive_item_actions.dart`, `asset_inspector_screen.dart`, `chronology_card.dart`, `universal_asset_toolbar.dart`, `asset_action_registry.dart`, `send_proof_provider.dart`, `app_config.dart`, `archive_media_download*.dart`.
* *QA*: User-confirmed pass after Send Proof gate fix and Download Media visibility on chronology + inspector.

## Related Notes

* [[Send_Proof_Courier_2026-05]]
* [[UI_Polish_Hub_Archive_2026-05]]
* [[App_Store_Hardening_2026-05]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[overview]]
