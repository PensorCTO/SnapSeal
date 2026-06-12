---
tags: [analysis, factlockcam, camera_hud, quota, subscription, app_store, qa_2026-06]
summary: "Thirtieth / final pre-submission pass (2026-06-12): interactive ProofQuotaHudChip in camera HUD, RepaintBoundary + 3:4 framed cover-cropped camera previews, proof-centric subscription paywall (Intro Week $0.99/25 seals, Weekly $4.99, Annual $49.99/500 proofs), Restore Purchases + Delete Account labels; device reinstall resolved stale binary; 100 tests green; wiki reconciled."
---

# Camera HUD, Quota HUD & Subscription Pricing Polish (June 2026)

## Core Synthesis

**Final device + submission-prep pass (2026-06-12)** after the twenty-ninth Unified Archive Studio baseline. Focused polish on visual authority of the Picture/Video viewports, psychological pressure via an interactive proof counter, and App Store Guideline 3.1.1/5.1.1 compliance in the settings surface. Two concrete QA issues were resolved on-device: (1) elongated full-bleed camera windows; (2) subscription UI still framed around old GB tiers instead of the proof/seal model the user experienced.

### Changes delivered

| Surface | Before | After (final pass) |
|---------|--------|--------------------|
| Camera preview framing | Full-bleed `Positioned.fill` + direct `CameraPreview` (appeared too long/elongated) | Centered `AspectRatio(3/4)` framed window + `FittedBox(BoxFit.cover)` cover-crop of the sensor feed; no stretch |
| Live feed performance | Overlays in `RepaintBoundary`; live preview not isolated | Live `CameraPreview` also wrapped in `RepaintBoundary` so AES-GCM sealing + HUD repaints do not invalidate the feed raster |
| Proof counter in HUD | Static `PROOFS: x/y` line inside `IgnorePointer` `TelemetryOverlay` (non-interactive, no warning state) | New tappable `ProofQuotaHudChip` (top-right of framed viewport, outside IgnorePointer). Reads `quotaStateProvider` (credit layer). Renders `PROOFS REMAINING: n/base` in mono. Pulses (amber/verifiedNeon) when `<=1` remaining and shows "UPGRADE"; taps open the paywall. Own `RepaintBoundary`; animation stopped in normal state |
| Subscription paywall | "Core Pro Tier" / "Sovereign Archivist" GB cards ($1/mo 5 GB, $10/mo 50 GB) | Proof-centric plans: **Intro Week** $0.99 first week (25 seals, badge INTRO), **Weekly** $4.99 (ongoing), **Annual** $49.99 (500 proofs/year, BEST VALUE). Cards and block-reason copy updated to "sealing proofs" language |
| Legal disclaimer | "Higher tiers provide larger bandwidth pipelines, but zero data recovery" | Refined to "Subscriptions provide additional sealing proofs only, with zero data recovery" (compliance test substrings preserved) |
| Account & Settings | "Burn account" only | Prominent **Restore Purchases** button (Guideline 3.1.1) + relabeled **Delete Account** for the typed-OBLITERATE burn flow (still routes to existing `BurnAccountView`) |
| Billing gateway | `upgradeTier` only (mock) | Extended with `restorePurchases()`; `SubscriptionUpgrade` notifier gained `restore()` action that refreshes both quota layers |
| Shell / navigation | Hub-first `IndexedStack` + lazy `_panelWhenSelected` (per `factlockcam-hub-refactor.mdc` + PR0 camera rule) | Unchanged — no `ProfessionalNavBar` reintroduced; camera remains inside the stack |
| Device QA gotcha | App relaunch showed stale binary (edits invisible) | Explicit `flutter build ios --debug --dart-define-from-file=dart_defines.json` + `flutter install -d <iPhoneTanto>` (per [[iOS_Device_Development_Workflow]]) |

Supabase tier enforcement substrate (byte limits + `set_archive_tier` RPC + `LocalArchiveQuotaGate`) was left in place; the paywall is now a **presentation layer** over the proof/seal mental model the consumer sees in the camera HUD.

### Validation

- `flutter test`: **100 passed + 4 intentional skips** (the skips are the decommissioned courier/Secure Comm widget suites, consistent with the twenty-ninth pass).
- `flutter analyze`: clean on all changed paths.
- Forensic viewfinder tests updated: `PROOFS` assertions moved from `TelemetryOverlay` to `ProofQuotaHudChip` tests (normal gauge, warning pulse state, tap opens paywall modal).
- Account/dashboard layout tests updated for the new button labels.
- Wiki validation: `python3 scripts/wiki_ingest.py --validate` (run after edits).

### Provenance Tracking

* *Implementation*: Changes in `factlockcam_app/lib/ui/mobile/camera/camera_view.dart`, `telemetry_overlay.dart`, new `features/archive_quota/presentation/widgets/proof_quota_hud_chip.dart`, `subscription_upgrade_view.dart`, `subscription_billing_gateway.dart` + mock, `subscription_upgrade_provider.dart`, `account_settings_panel.dart`, `disclaimers.dart`, and corresponding test updates. Device reinstall followed the documented iOS workflow.
* *Plan reference*: Executed the attached "Camera HUD Quota Polish" plan plus the two explicit QA corrections (proof pricing, camera framing) on 2026-06-12.
* *Prior baseline*: [[Unified_Archive_Studio_2026-06]] (twenty-ninth pass, 2026-06-08).

## Related Notes

* [[FactLockCam_Product_Baseline_2026-05]]
* [[Unified_Archive_Studio_2026-06]]
* [[Archive_Quota_Telemetry_2026-06]]
* [[Archive_Subscription_Tiers_2026]]
* [[iOS_Device_Development_Workflow]]
* [[Heavy_Metal_Design_System]]
* `docs/skills/SKILL_IMPLEMENT_ARCHIVE_SUBSCRIPTIONS.md` (foundation)
* Cursor rule: `factlockcam-hub-refactor.mdc` (shell preserved)
* Future: real StoreKit integration (the mock gateway + restore scaffolding already exists for the compliance surface)