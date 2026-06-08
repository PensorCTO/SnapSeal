---
tags: [analysis, factlockcam, certificate_studio, product_pivot, qa_2026-06]
summary: "Twenty-ninth pass (2026-06-08): Unified Archive Studio pivot — four-tile hub, Certificate Studio, courier decommission, hub backdrop auto-play; user QA passed; 98/98 tests."
---

# Unified Archive Studio (June 2026)

## Core Synthesis

**Twenty-ninth device QA pass (2026-06-08)** — user-confirmed **application stable** after pivoting owner workflow from Send Proof / Secure Comm origination to a **local-first Certificate Studio** and restoring the canonical **four-tile hub**.

### Product pivot

| Surface | Before (pass 28) | After (pass 29) |
|---------|------------------|-----------------|
| Hub tiles | Five (incl. Secure Comm) | **Four** — Archive, Picture, Video, Account & Settings |
| Asset actions | View, Download, Send Proof, Delete | View, Download, **Print Certificate**, Delete |
| Owner export | Courier URL + certificate PDF share sheet | **Certificate Studio** — local metadata + live PDF preview + print/share PDF |
| Web `/courier` | Phased Secure Communications Console | **Redirects to gate** — unlock UI decommissioned from routing |
| `enableProofLinks` | Debug gate for Send Proof | Defaults **false** — no in-app courier origination |

Supabase courier tables and RPCs **unchanged** (backend retained for data; no mobile/web unlock paths).

### Certificate Studio

- **`CertificateStudioView`** — debounced title/description edit via `assetMetadataProvider` (SQLite only; **never** mutates `proof_ledger`).
- Live **`PdfPreview`** (`printing` package) streams compiled PDF as user types.
- **`CertificateExportService`** supplies Polygon hash, timestamp, thumbnail, branding.
- Print + Share PDF via system sheet — utility export only (no in-app messaging).

### Hub backdrop fix

**Root cause:** `_panelWhenSelected` disposes `HapticHubPanel` when leaving hub index 0; remount re-inits video **paused on frame 0** with no auto-play.

**Fix (`HeavyMetalBackdropMixin`):**
- `onBackdropReady()` hook — `HapticHubPanel` overrides to call `playBackdropFromStart()` on every hub mount (return from sub-panels).
- End-of-playback: `SystemSound.play(SystemSoundType.click)` (native) + `HapticFeedback.lightImpact()`; seek to frame 0; `_endHandled` prevents duplicate signals.

### Orphaned source (retained, unmounted)

- `SecureCommCaptureView`, `SecureCommCameraPool`, dispatch console modules, `send_proof_provider.dart`, web courier unlock views — not routed from production shell.

### Validation

- **`flutter test`:** **98/98** passing (courier/Secure Comm widget suites `@Skip` or short-circuited).
- **`python3 scripts/wiki_ingest.py --validate`**
- Skill: `docs/skills/SKILL_UNIFIED_ARCHIVE_STUDIO.md`

## Provenance Tracking

* *Structural pass + QA*: Derived from implementation in `factlockcam_app/` (2026-06-08); user QA passed same date.
* *Superseded flows*: [[Zero_Click_Capture_2026-06]], [[Secure_Communications_Console_2026-06]], [[Send_Proof_Courier_2026-05]] (historical; decommissioned from active surfaces).

## Related Notes

* [[FactLockCam_Product_Baseline_2026-05]]
* [[Compliance_Refactor_2026-06]]
* [[Web_Deployment_Architecture_2026-05]]
* [[Production_Transition_2026-05]]
* [[Archive_Owner_UX_2026-05]]
* [[Zero_Click_Capture_2026-06]]
* [[Send_Proof_Courier_2026-05]]
