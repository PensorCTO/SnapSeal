# SKILL: App Store Compliant Archive Subscription Tiers

## Description

A procedural toolkit to implement a three-tiered, local-first metered subscription architecture that strictly adheres to App Store Guideline 3.1.1 and zero-knowledge data sovereignty principles.

## Prerequisites

- Read `wiki/index.md`, `wiki/overview.md`, and `raw/compliant_subscription_architecture.md`.
- Existing byte layer: `supabase/migrations/20260602120000_archive_quotas_and_tiers.sql`.
- Flutter module: `factlockcam_app/lib/features/archive_quota/`.

## Step 1: Supabase Schema Generation

1. Run `supabase migration new archive_tiers_compliant_labels` (or equivalent).
2. Add `max_single_capture_bytes` to `archive_tiers` if missing; seed free tier at 52428800.
3. Update display names: Sovereign Free Baseline, Core Pro Tier, Sovereign Archivist.
4. Extend `get_my_archive_quota()` to return `max_single_capture_bytes`.
5. Keep strict RLS on `archive_quotas`; mutations only via SECURITY DEFINER RPCs.
6. End migration with `NOTIFY pgrst, 'reload schema';`

## Step 2: Client-Side Local Enforcement

1. Add `VaultDatabase.sumLocalByteLength()`.
2. Implement `LocalArchiveQuotaGate` using SQLite sum + cached tier limits.
3. Wire `ensureArchiveQuotaForSeal` before camera seal and inside `VaultService.sealAndStoreCapture`.
4. Do not rely on server rejections as the primary gate.

## Step 3: Graceful Camera Intercepts

1. For `free` tier video mode, poll recording size while `_isRecording`.
2. At >= `max_single_capture_bytes`, call `stopVideoRecording()` safely.
3. Present `SubscriptionUpgradeView` with `ArchiveQuotaBlockReason.singleCapture`.

## Step 4: Explicit Legal UI

1. Add `archiveSubscriptionTierDisclaimer` to `disclaimers.dart`.
2. Show on `SubscriptionUpgradeView` and `ArchiveSubscriptionOnboardingSheet`.
3. First-run flag via `shared_preferences` after OTP logon.

## Step 5: Terminology Audit

1. Grep user-visible strings under `lib/ui/`, `lib/core/marketing/`, `lib/core/legal/`, `features/archive_quota/presentation/`.
2. Replace **Vault** with **Archive** in UI copy only (not `VaultService` symbols).
3. Extend `marketing_compliance_test.dart`.

## Wiki reconciliation

After implementation: `wiki/log.md`, `wiki/concepts/Archive_Subscription_Tiers_2026.md`, `wiki_ingest.py --validate`.

## Related

- `.cursor/rules/SKILL_Archive_Quota_Telemetry.mdc`
- `wiki/concepts/Archive_Quota_Telemetry_2026-06.md`
