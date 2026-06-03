# App Store Compliant Three-Tiered Archive Subscription Architecture

**Status:** Product specification for Phase 1 foundation (June 2026).  
**Guideline:** Apple App Store 3.1.1 — subscriptions are utility bandwidth tiers, not data recovery or key escrow.

## Principles

1. **Local-first enforcement:** Asset sizes are computed from on-device SQLite (`byte_length` on `archive_items`) before seal, Supabase push, or Polygon notarization. The client must not rely on server-side quota rejection as the primary gate (billing anomaly risk).
2. **Zero-knowledge sovereignty:** Higher tiers expand storage and egress pipelines only. Purchasing a tier does **not** grant FactLockCam access to decryption keys, lost-device recovery, or archive restoration.
3. **Archive nomenclature:** User-facing copy uses **Archive** only; **Vault** is deprecated in UI and marketing.
4. **Dual metering:** Byte caps (`archive_quotas`) coexist with credit metering (`subscription_cycles` / pro proofs / verification credits). Phase 1 wires byte pre-flight; credits remain unchanged.

## Tier catalog (stable `tier_id`)

| tier_id | Display name (Phase 1) | Storage | Monthly egress | Price |
|---------|------------------------|---------|----------------|-------|
| `free` | Sovereign Free Baseline | 50 MB | 3 GB | $0 |
| `picture` | Core Pro Tier | 5 GB | 25 GB | $1/mo |
| `video` | Sovereign Archivist | 50 GB | 200 GB | $10/mo |

### Per-tier capture limits

| tier_id | `max_single_capture_bytes` | Notes |
|---------|---------------------------|-------|
| `free` | 52,428,800 (50 MB) | Video recording must stop safely at this cap with upsell UI |
| `picture` | null (tier storage cap) | — |
| `video` | null (tier storage cap) | — |

## Client enforcement surfaces

1. **Pre-seal:** `LocalArchiveQuotaGate` — `SUM(byte_length)` + incoming bytes ≤ `storage_limit_bytes`.
2. **Video (free):** Poll recording size; auto `stopVideoRecording()` at 50 MB; present paywall (`singleCapture` reason).
3. **Send Proof:** Egress pre-flight before courier upload.
4. **Post-seal telemetry:** `increment_archive_storage` async; failures non-blocking.

## Legal copy (required on paywall + first-run onboarding)

> Higher tiers provide larger bandwidth pipelines, but zero data recovery. FactLockCam cannot restore lost keys or decrypt your archive.

## Billing (Phase 1)

- Mock gateway (`MockSubscriptionBillingGateway`) calls `set_archive_tier` RPC.
- Production StoreKit / receipt validation is Phase 2; do not alter `Info.plist` or Podfile destructively for IAP scaffolding.

## Supabase

- Tables: `archive_tiers`, `archive_quotas` (existing migration `20260602120000`).
- RLS: users SELECT own `archive_quotas` only; mutations via SECURITY DEFINER RPCs.
- Phase 1 delta: compliant display names + `max_single_capture_bytes` on `archive_tiers`, exposed in `get_my_archive_quota()` JSON.
