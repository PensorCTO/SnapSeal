# SKILL: Zero-Click Capture Architecture

## Description

Procedural toolkit for implementing the Zero-Click Capture interface and the Access Control Panel overlay, ensuring seamless front-to-back camera switching and asynchronous Archive anchoring.

## Prerequisites

- `wiki/index.md`, `wiki/log.md`, `wiki/concepts/FactLockCam_Product_Baseline_2026-05.md`
- `docs/skills/SKILL_Dispatch_Primitive.md` (Task 3 RPC params)
- `.cursor/rules/courier-origination.mdc`, `factlockcam-capture-pipeline.mdc`

## Instructions

### 1 — Hardware pre-warm (HapticHubPanel)

- Register `SecureCommCameraPool` in GetIt (`!kIsWeb`); bridge via `secureCommCameraPoolProvider`.
- On hub `initState` post-frame: `warmFrontCamera()` — front lens, `enableAudio: true`.
- `release()` when Picture/Video panels mount; re-warm on return to hub.
- `adoptController()` hands off to `SecureCommCaptureView` on Secure Comm tap.

### 2 — Hot lens swap (audio preserved)

- Use `CameraController.setDescription()` during active recording — never dispose/re-init mid-record.
- Blur + 120–180ms crossfade + `HapticFeedback.lightImpact()` on swap.
- Wrap preview in `RepaintBoundary`.

### 3 — Capture → Archive seal

- On `stopVideoRecording`: quota pre-flight → **release camera** → copy preview to cache → loop `VideoPlayer`.
- Read capture bytes: top-level **`readAsBytesSync`** inside **`Isolate.run`** — never return async `readAsBytes()` futures from isolate callbacks.
- Parallel: `vaultService.sealAndStoreCapture` → `TransactionalArchivePersister` via saga path.
- UI: **"Anchoring to Archive…"** during seal; store `assetFingerprint` on success.

### 4 — Access Control Panel overlay

- Shared `ArchiveAccessControlPanel`: Recipient Key, Link Lifespan (`linkTtlDays`), Exposure Limit (`maxDownloads`).
- Maps to `get_or_create_courier_package` params (`20260606140000_dispatch_package_params.sql`).
- Overlay on looping review preview; Archive lexicon only.

### 5 — Share delivery

- `sendProofProvider.send(SendProofRequest(...))` + `SharePlus` share sheet.
- Quota: `ensureArchiveQuotaForSendProof`; errors: `friendlyCourierDispatchError`.

## Validation

```bash
cd factlockcam_app && flutter test
python3 scripts/wiki_ingest.py --validate
```

## Related skills

- `SKILL_Dispatch_Primitive.md`
- `SKILL_Secure_Comm_Console.md`
