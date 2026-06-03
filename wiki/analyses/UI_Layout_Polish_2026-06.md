---
tags: [analysis, factlockcam, ui, archive, hub, qa, 2026-06]
summary: "Twenty-first QA pass (2026-06-03): responsive Heavy Metal layouts on hub, archive omni, inspector, and account settings; Archive copy audit; device QA passed."
---

# UI Layout Polish (June 2026)

## Core Synthesis

**Twenty-first device QA pass (2026-06-03)** — presentation-only polish for landscape and small viewports on the archive hub shell. **User QA passed** on physical iPhone (landscape Account panel overflow fixed in follow-up).

### Shell mapping (current code)

| Surface | Widget | Tab index |
|---------|--------|-----------|
| Hub launcher | `HapticHubPanel` | 0 |
| Picture / Video | `buildCapturePanel` | 1 / 2 |
| Archive omni | `UnifiedArchiveViewport` (grid + chronology) | 3 |
| Account & Settings | `AccountSettingsPanel` | 4 |

Legacy blueprint names (`VaultHomeView`, `ChronologyViewport`) map to `ArchiveHomeView` and chronology mode inside `UnifiedArchiveViewport` ([[Compliance_Refactor_2026-06]]).

### Responsive layout

- **Hub:** Pending-sync UI inside scroll; compact 2×2 tile grid when `maxHeight < 440` or landscape aspect.
- **Archive omni:** `LayoutBuilder` dense headers when `maxHeight < 520` — 72px logo, compact egress/pending rows, hidden `QuotaTelemetryWidget`, 48px control bar; `chronologyLayoutMetrics()` scales card height; scrollable empty state.
- **Inspector:** Landscape `Wrap` action matrix; **BACK TO ARCHIVE**; hash ellipsis on info strip.
- **Account:** Single `SingleChildScrollView` for legal tiles + actions (removes pinned footer overflow); same dense header rules; `HeavyMetalHubTile(compact: true)` in landscape.

### Nomenclature

- User-visible **Archive** only in presentation layer; structural `vaultServiceProvider` / DB names unchanged.
- Curated literals: `archive_presentation_copy.dart` + `marketing_compliance_test.dart`; guard: `presentation_archive_copy_test.dart`.

### Skill & tests

- **Skill:** `docs/skills/SKILL_FORENSIC_UI_REFINEMENT.md`
- **Tests:** `unified_archive_viewport_test`, `asset_inspector_layout_test`, `haptic_hub_panel_layout_test`, `account_settings_panel_layout_test`, `presentation_archive_copy_test`, `helpers/layout_test_helpers.dart`
- **`flutter test` 90/90** after account follow-up

## Provenance Tracking

* *Session*: Cursor agent forensic UI layout polish 2026-06-03; device QA overflow on `account_settings_panel.dart:288` resolved same day.
* *Code*: `haptic_hub_panel.dart`, `unified_archive_viewport.dart`, `chronology_card.dart`, `asset_inspector_screen.dart`, `account_settings_panel.dart`, `omni_control_bar.dart`, `egress_pass_badge.dart`.

## Related Notes

* [[UI_Polish_Hub_Archive_2026-05]]
* [[Heavy_Metal_Design_System]]
* [[Compliance_Refactor_2026-06]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[Archive_Quota_Telemetry_2026-06]]
