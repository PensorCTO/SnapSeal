---
tags: [source_summary, subscription, app_store, archive]
summary: "Source summary for App Store 3.1.1 compliant three-tier Archive subscription and local-first quota enforcement."
---

# Compliant Subscription Architecture Source

## Core Synthesis

Defines three stable tiers (`free`, `picture`, `video`) with byte storage/egress limits, local SQLite pre-flight before network, free-tier 50 MB single-capture video cap, subscription disclaimers (no data recovery), and mock billing for Phase 1.

## Key Claims

- Tier display names: Sovereign Free Baseline, Core Pro Tier, Sovereign Archivist.
- `max_single_capture_bytes` = 50 MB on free tier for in-recording stop.
- Client gates before Supabase/Polygon; server RPCs are telemetry/reconcile only.
- StoreKit deferred; preserve iOS privacy manifest baseline.

## Provenance Tracking

* *Specification*: Derived from `raw/compliant_subscription_architecture.md` (2026-06-03)

## Related Notes

* [[Archive_Subscription_Tiers_2026]]
* [[Archive_Quota_Telemetry_2026-06]]
* [[FactLockCam_Product_Baseline_2026-05]]
