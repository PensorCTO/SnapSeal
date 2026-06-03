# SKILL: Heavy Metal Forensic UI Polish and Layout Tuning

## Description

A precise protocol to safely iterate on FactLockCam theme layout systems, eliminate `RenderFlex` overflows across portrait/landscape test frames, and verify asset visibility—without altering domain logic, crypto, or StoreKit billing.

## Prerequisites

- Read `wiki/index.md` → [[FactLockCam_Product_Baseline_2026-05]], [[Heavy_Metal_Design_System]].
- Layout anchors: `ArchiveHomeView` (hub shell), `HapticHubPanel`, `UnifiedArchiveViewport` (chronology), `AssetInspectorScreen`.
- Theme tokens: `factlockcam_app/lib/app/theme/app_colors.dart`, `app_typography.dart`.
- Rules: `.cursor/rules/04_forensic_ui_standards.mdc`, `.cursor/rules/factlockcam-capture-pipeline.mdc`, `.cursor/rules/vault-chronology-engine.mdc`, `.cursor/rules/vault-asset-inspector.mdc`.

## Instruction 1: Static Nomenclature Verification

1. Audit **user-visible** copy only: `Text`, `tooltip`, `Semantics.label`, nav titles, dialogs, empty states under `lib/ui/mobile/archive/`.
2. Enforce **Archive** terminology; reject legacy **Vault** in UI strings (structural symbols like `vaultServiceProvider` stay until dedicated rename PRs).
3. Extend `test/marketing_compliance_test.dart` curated list when adding new compliance-facing literals.
4. Run `test/presentation_archive_copy_test.dart` after presentation edits.

## Instruction 2: Theme Layout Decoupling

1. Prefer `LayoutBuilder`, `Flexible`, `Expanded`, `SafeArea`, and `SingleChildScrollView` over fixed-height stacks on variable simulators.
2. Hub: keep four-tile launcher scrollable; use `compact` 2×2 grid in landscape (`HapticHubPanel`).
3. Archive omni-surface: collapse header chrome (logo height, quota telemetry) when `constraints.maxHeight` is tight; keep chronology `ListView` in `Expanded`.
4. Inspector: landscape action matrix via `Wrap` or two-column grid; scroll body for keyboard + rotation.
5. Zero yellow/black overflow stripes on rotation QA.

## Instruction 3: Interactive Tuning

1. Chronology fan: bind `Transform` to scroll offset in `chronology_card.dart`—no `AnimationController`; optional viewport-scaled card height via presentation helpers only.
2. Custom painters (`ShutterIrisPainter`): tune inside camera presentation layers only; do not add hard dependencies on unmerged Riverpod providers.
3. Preserve RepaintBoundary on chronology cards, camera overlays, and iris shutter per capture-pipeline rules.

## Validation (presentation sandbox)

```bash
cd factlockcam_app && flutter test test/unified_archive_viewport_test.dart test/asset_inspector_layout_test.dart test/presentation_archive_copy_test.dart test/marketing_compliance_test.dart
flutter analyze lib/ui/mobile/archive/
```

Use `setupTestDependencies()` in `setUpAll`; mock `thumbnailCacheProvider`, `dashboardControllerProvider`, quota providers—no live Supabase or StoreKit.

## Wiki

After a pass, append `wiki/log.md` under the current date with title **2026-06-03 Pass — UI Layout Polish** (or the active date), record actual `flutter test` count, run `python3 scripts/wiki_ingest.py --validate`. Do not rewrite historical frontmatter pass rates on unrelated wiki pages.
