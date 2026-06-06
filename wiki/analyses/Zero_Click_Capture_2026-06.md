---
tags: [analysis, factlockcam, mobile, secure_communications, capture, qa, 2026-06]
summary: "Twenty-eighth QA pass (2026-06-06): Zero-Click Secure Comm capture on iPhone — pre-warm, hot lens swap, Archive seal, Access Control transmit; 115/115 tests; user QA passed."
---

# Zero-Click Secure Comm Capture (June 2026)

## Core Synthesis

**Twenty-eighth device QA pass (2026-06-06)** — user-confirmed **Secure Comm capture stable** after replacing the legacy two-step asset picker (`CourierDispatchView`) with capture-first **`SecureCommCaptureView`**.

The flow aligns mobile origination with the web **Secure Communications Console** ([[Secure_Communications_Console_2026-06]]): record → seal to local Archive → configure courier access → **TRANSMIT PROOF** via system share sheet (no in-app messaging).

### Phase machine (`SecureCommCapturePhase`)

| Phase | UX | Backend / domain |
|-------|-----|------------------|
| `livePreview` | Framed 9:16 viewport, telemetry HUD, lens flip, record/stop | `SecureCommCameraPool` or fresh `CameraController` |
| `anchoringArchive` | Looping preview + **Anchoring to Archive…** | `VaultService.sealAndStoreCapture` + transactional persister |
| `reviewAndDispatch` | Access Control overlay + consumption panel | `dispatchConsoleProvider` params → `sendProofProvider` |

State: `secureCommCaptureProvider` (`secure_comm_capture_state.dart`).

### Hardware pre-warm

- **`SecureCommCameraPool`** (GetIt, `!kIsWeb`): hub idle warms **front** camera with `enableAudio: true`.
- **`HapticHubPanel`**: post-frame `warmFrontCamera()`; **`release()`** when Picture/Video mount; re-warm on hub return.
- **`adoptController()`** hands off to Secure Comm without cold-start jank.

### Hot lens swap

- During active recording: **`CameraController.setDescription()`** — never dispose/re-init mid-record (audio preserved).
- Visual: blur + 120–180ms crossfade + light haptic; preview in **`RepaintBoundary`**.

### Post-capture seal

1. **`stopVideoRecording()`** → release camera immediately (UI thread protection).
2. Copy preview to temp cache → **`VideoPlayerController`** loop (muted).
3. Read bytes via top-level **`_readSecureCommCaptureBytes`** inside **`Isolate.run`** — **sync** `readAsBytesSync` only (async `readAsBytes` return values are illegal isolate messages).
4. **`sealAndStoreCapture(XFile, bufferedBytes)`** → **`assetFingerprint`** stored for transmit.

### Access Control Panel

Shared widget **`ArchiveAccessControlPanel`**:

| Control | RPC param |
|---------|-----------|
| Recipient Key | courier unlock password (via `SendProofRequest`) |
| Link Lifespan | `linkTtlDays` (1 \| 7 \| 30) |
| Exposure Limit | `maxDownloads` (1 \| 3 \| 5) |

Migration **`20260606140000_dispatch_package_params.sql`** — optional params on `get_or_create_courier_package`.

### Consumption / quota UX

- **`SecureCommConsumptionPanel`**: PROOFS gas gauge + **`QuotaTelemetryWidget`** below framed viewport.
- Recipient Key field hidden until **`capture.canTransmit`** (avoids keyboard during anchoring).
- Free-tier video cap: quota poll during record (same gate as Picture/Video).

### Hub shell (restored)

- Post-login landing: **`HapticHubPanel`** index 0 (five tiles).
- **`DispatchPrimitiveNavBar`** deprecated — not mounted in production ([[FactLockCam_Product_Baseline_2026-05]]).
- **`CourierDispatchView`** retained for legacy widget tests only.

### Device QA verified (2026-06-06)

- Hub → Secure Comm → record → stop → seal completes (no isolate error banner).
- Lens flip before/during record; framed viewport + quota panel visible.
- Access Control → **TRANSMIT PROOF** → share sheet path.
- Keyboard dismisses cleanly after anchoring.

### Tests

**115/115** `flutter test` — includes `secure_comm_capture_view_test.dart`, `hub_secure_comm_nav_test.dart`, `courier_dispatch_view_test.dart`.

### Skills & rules

| Artifact | Purpose |
|----------|---------|
| `docs/skills/SKILL_Zero_Click_Capture_Architecture.md` | Implementation checklist |
| `docs/skills/SKILL_Dispatch_Primitive.md` | Tasks 1–3 RPC / UGC foundation |
| `.cursor/rules/factlockcam-hub-refactor.mdc` | Hub tile map + Secure Comm mount |
| `.cursor/rules/courier-origination.mdc` | Share sheet only; `WEB_ARCHIVE_BASE_URL` |

## Provenance Tracking

* *Implementation + QA*: Agent session 2026-06-06; isolate fix (`readAsBytesSync` in top-level helper); user QA passed same day.
* *Code anchors*: `secure_comm_capture_view.dart`, `secure_comm_camera_pool.dart`, `archive_access_control_panel.dart`, `haptic_hub_panel.dart`, `archive_home_view.dart`.

## Related Notes

* [[Secure_Communications_Console_2026-06]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[Send_Proof_Courier_2026-05]]
* [[Archive_Quota_Telemetry_2026-06]]
* [[UGC_Safety_Reporting_2026-06]]
