---
tags: [analysis, factlockcam, ui, archive, hub, qa, 2026-05]
summary: "Eleventh QA pass (2026-05-24): shared logo banner, Account & Settings heavy-metal polish, chronology scroll clarity fix, archive regression test."
---

# UI Polish — Hub, Archive & Account (May 2026)

## Core Synthesis

**Eleventh device QA pass (2026-05-24)** — user-confirmed after a sprint focused on visual consistency and archive chronology readability ahead of TestFlight.

### Shared brand header

- **`HeavyMetalLogoBanner`** now defaults to `assets/images/factlockcam_logoheader.jpg` via `kHeavyMetalLogoHeaderAsset` in `heavy_metal_backdrop.dart`.
- **Hub**, **logon**, and **Archive** panels all use the same header graphic without duplicating `Image.asset` wiring.

### Account & Settings panel

- **Background:** Same Heavy Metal video backdrop + titanium overlay as logon and hub (`HeavyMetalBackdropMixin`).
- **Logo banner** below panel back navigation.
- **Account actions:** Log out + Burn account remain compact `_ActionButton` controls.
- **Legal & support:** Terms of Service, Privacy Policy, Help & Support, App Web Page (placeholder), User Guide (placeholder) use shared **`HeavyMetalHubTile`** — same titanium gradient hardware tiles as the hub launcher (`heavy_metal_hub_tile.dart`).

### Archive chronology scroll fix

**Problem:** Scroll-driven opacity dimmed cards away from viewport center (down to 25%), so only the first few stacked assets looked “lit up.”

**Fix (minimal, tested):**

- Removed scroll-driven **`Opacity`** dimming; all cards stay fully legible.
- Restored original **`itemExtent`** (425px, 75% overlap) and scroll math.
- **`clipBehavior: Clip.none`** on chronology `ListView` so transforms are not clipped.
- Refactored `ChronologyCard` — transform wraps card body only; zero-viewport guard.

### Tests

- Added **`test/unified_archive_viewport_test.dart`** — verifies chronology titles, non-zero card layout, no opacity dimming; mocks thumbnail + notarization monitor for test isolation.
- Updated **`vault_dashboard_view_test.dart`** for uppercase Account panel labels.
- **`flutter test` 41/41** after logon shell test updated for image logo banner.

## Provenance Tracking

* *Session*: Cursor agent UI polish sprint 2026-05-24 (logo header, Account panel, chronology regression + fix).
* *Code*: `heavy_metal_backdrop.dart`, `heavy_metal_hub_tile.dart`, `haptic_hub_panel.dart`, `account_settings_panel.dart`, `chronology_card.dart`, `unified_archive_viewport.dart`, `test/unified_archive_viewport_test.dart`.

## Related Notes

* [[Heavy_Metal_Design_System]]
* [[App_Store_Remediation_2026-05]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[Isolate_Lock_Coordinator]]
