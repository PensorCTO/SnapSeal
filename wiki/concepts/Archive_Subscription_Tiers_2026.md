---
tags: [concept, factlockcam, archive, subscription, app_store, quota]
summary: "Three-tier Archive subscription foundation: local SQLite pre-flight, free-tier 50 MB video cap, compliant display names, and subscription legal disclaimers (June 2026)."
---

# Archive Subscription Tiers (2026)

## Core Synthesis

Phase 1 wires **App Store 3.1.1–aligned** three-tier metering on top of the existing byte + credit stack ([[Archive_Quota_Telemetry_2026-06]]). Stable `tier_id` values remain `free`, `picture`, `video`; user-facing names and capture caps come from `raw/compliant_subscription_architecture.md`.

| tier_id | Display name | Storage | Egress / month | Price | Single-capture cap |
|---------|--------------|---------|----------------|-------|-------------------|
| `free` | Sovereign Free Baseline | 50 MB | 3 GB | $0 | **50 MB** (video auto-stop) |
| `picture` | Core Pro Tier | 5 GB | 25 GB | $1/mo | tier storage |
| `video` | Sovereign Archivist | 50 GB | 200 GB | $10/mo | tier storage |

### Local-first enforcement

- `VaultDatabase.sumLocalByteLength()` — `SUM(byte_length)` for locally available items.
- `LocalArchiveQuotaGate` — compares local sum + incoming bytes to tier `storage_limit_bytes` (offline fallback: free-tier constants in `archive_tier_defaults.dart`).
- `ensureArchiveQuotaForSeal` / `VaultService._assertLocalQuotaForSeal` — block before seal; **tests fail-open** via `AppConfig.isFlutterTest`.
- `ensureArchiveQuotaForSendProof` — egress gate before courier upload.

### Free-tier video intercept

- While recording (`AcquisitionMode.video`), a ~400 ms timer estimates size at **~1.5 MB/s** (high preset heuristic).
- At ≥ 50 MB on free tier: safe `stopVideoRecording()`, paywall with `ArchiveQuotaBlockReason.singleCapture` (no seal).

### Legal UI

- `archiveSubscriptionTierDisclaimer` in `disclaimers.dart` — higher tiers = bandwidth only, **zero data recovery**.
- `SubscriptionUpgradeView` — disclaimer + proof-centric cards (Intro Week / Weekly / Annual in final pass); old GB tier names retained only for backend `tier_id` values.
- `ArchiveSubscriptionOnboardingSheet` — first run after logon (`shared_preferences` key `archive_subscription_onboarding_seen_v1`).

### Supabase delta

- Migration `20260603120000_archive_tiers_compliant_labels.sql` — display names, `max_single_capture_bytes`, extended `get_my_archive_quota()` JSON.

### Final-pass UI presentation (2026-06-12)

Thirtieth pass ([[Camera_HUD_Quota_Pricing_Polish_2026-06]]) updated the visible paywall and camera HUD to a **proof/seal** mental model (Intro Week $0.99 for 25 seals, Weekly $4.99, Annual $49.99 for 500 proofs/year) with an interactive pulsing `ProofQuotaHudChip`. The byte/storage enforcement substrate (`LocalArchiveQuotaGate`, tier limits, `set_archive_tier`) and backend RPCs were left unchanged; the paywall is now a presentation layer aligned with how users experience "running out of seals" in the viewfinder.

### Deferred (Phase 2+)

- Production StoreKit / receipt validation.
- Async `increment_archive_storage` post-seal telemetry.
- Hosted migration push via `scripts/factlockcam_supabase_pipeline.sh`.

## Provenance Tracking

* *Specification*: `raw/compliant_subscription_architecture.md` (2026-06-03)
* *Implementation*: Nineteenth structural pass; `flutter test` **80/80**

## Related Notes

* [[Archive_Quota_Telemetry_2026-06]]
* [[Compliant_Subscription_Architecture_Source]]
* [[Compliance_Refactor_2026-06]]
* [[FactLockCam_Product_Baseline_2026-05]]
