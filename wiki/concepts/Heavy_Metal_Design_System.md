---
tags: [concept, factlockcam, design_system, ui]
summary: "FactLockCam's heavy-metal UI design system uses titanium surfaces, technical typography, two role-specific greens, and a mechanical iris capture control to make the app feel like secure hardware."
---

# Heavy Metal Design System

## Core Synthesis

The Heavy Metal design system is FactLockCam's visual integration track for making the product feel less like a standard mobile app and more like high-end secure hardware. It anchors primary surfaces in titanium greys (`#121212`, `#1C1C1C`, `#2A2A2A`), reserves Stark White for HUD text and hairline instrumentation, and splits green semantics into two distinct roles: **Kinetic Green** (`#00D26A`) for active/in-progress states such as recording and **Verified Neon** (`#39FF14`) for completed locked/verified states.

Typography pairs readable Inter body copy with Space Mono for hashes, timestamps, ledger identifiers, and camera telemetry. The camera capture control is a `CustomPaint` mechanical iris (`ShutterIrisPainter`) inside a `RepaintBoundary`, preserving the project's zero-jank camera overlay rule while replacing the previous plain shutter ring with a tactile, industrial aperture motif. `HapticService.lock()` wraps `HapticFeedback.heavyImpact()` so capture engage and successful seal events carry a physical hardware feel.

The design system is codified in Flutter theme tokens under `factlockcam_app/lib/app/theme/` and reinforced by `.cursor/rules/04_forensic_ui_standards.mdc` so future forensic UI work uses the same palette, typography, haptics, and mechanical shutter language.

## Provenance Tracking

* *Palette and typography tokens*: Derived from `factlockcam_app/lib/app/theme/app_colors.dart`, `factlockcam_app/lib/app/theme/app_typography.dart`, and `factlockcam_app/lib/app/theme/app_theme.dart` (2026-05-13).
* *Mechanical iris capture control*: Derived from `factlockcam_app/lib/core/ui/painters/shutter_button_painter.dart` and `factlockcam_app/lib/ui/views/camera/camera_view.dart` (2026-05-13).
* *HUD and haptics*: Derived from `factlockcam_app/lib/ui/views/camera/telemetry_overlay.dart` and `factlockcam_app/lib/core/services/haptic_service.dart` (2026-05-13).
* *Hub + archive brand header*: `HeavyMetalLogoBanner` + `HeavyMetalHubTile` shared widgets (2026-05-24, [[UI_Polish_Hub_Archive_2026-05]]; dense-header + landscape rules 2026-06-03, [[UI_Layout_Polish_2026-06]]).
* *Design constraints*: Derived from `.cursor/rules/04_forensic_ui_standards.mdc` and Track 2 implementation request (2026-05-13).

## Related Notes

* [[UI_Layout_Polish_2026-06]]
* [[UI_Polish_Hub_Archive_2026-05]]
* [[MASTER_CONTEXT16MAY2026]]
* [[MASTER_CONTEXT13MAY2026]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[FactLockCam_Master_Blueprint]]
* [[ProofLock_Refactor_Scope]]
