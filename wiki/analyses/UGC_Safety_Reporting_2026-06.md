---
tags: [analysis, factlockcam, ugc, app_store, compliance, june_2026]
summary: "June 2026 UGC safety module: async reporting/blocking for App Store Guideline 1.2 without camera-path gates."
---

# UGC Safety & Reporting (2026-06)

## Core Synthesis

Twenty-fourth structural pass (**2026-06-05**): FactLockCam adds **Asynchronous Reporting & Blocking Protocol** for Send Proof / courier recipient surfaces. Capture remains frictionless — no identity verification gates on `CameraView`. **User QA passed** same day on hosted report/block flows and post-upload content scan.

### Shipped

| Layer | Artifact |
|-------|----------|
| **Flutter module** | `factlockcam_app/lib/features/ugc_safety/` — `SafetyRepository`, `ReportContentSheet`, `BlockSenderDialog`, Riverpod providers |
| **Recipient UI** | `CourierUnlockView` — persistent "Report concerning content" + post-unlock "Report & block sender" |
| **Owner UI** | `ArchiveItemActions.additionalActions` — "Report shared proof" when `get_own_courier_package_id` returns a package |
| **Supabase** | `20260605120000_ugc_safety_infrastructure.sql` — reports, blocks, moderation queue, `moderation_status` on `courier_packages`; **pushed hosted 2026-06-05** |
| **Edge Function** | `courier-content-scan` — async v1 metadata heuristic on encrypted blob paths (zero-knowledge preserved); **deployed hosted 2026-06-05** (`jqvnwtslmoxjwzusmtxs`, `--no-verify-jwt`) |
| **Async hook** | `ArchiveService.createCourierPackage` → fire-and-forget `courier-content-scan` after upload |
| **Skill** | `docs/skills/SKILL_Compliance_Architecture.md` |
| **Tests** | `courier_unlock_reporting_test.dart`; **96/96** `flutter test` |

### RPCs

- `report_courier_package` — anon + authenticated; returns `report_id` only (never `owner_id`)
- `block_courier_sender` — server-side `owner_id` resolution from `package_id`
- `check_sender_blocked_for_reporter` — optional pre-unlock gate
- `get_own_courier_package_id` — authenticated owner lookup by `asset_hash`

### Design constraints

- ML scan operates on **metadata/path heuristics** in v1 — not decrypted plaintext (ZK boundary).
- Quarantined packages rejected in `attempt_courier_unlock` and surfaced as `quarantined` in `check_courier_attempts`.
- Identity verification placeholder: `SafetyRepository.verifyReporterIdentity()` → `notRequired` in v1.

## Provenance Tracking

* *Implementation + QA*: Zero-Trust Compliance Alignment plan (2026-06-05); user-confirmed hosted QA pass same day.

## Related Notes

* [[Zero_Trust_RLS_Audit_2026-06]]
* [[Compliance_Refactor_2026-06]]
* [[Send_Proof_Courier_2026-05]]
* [[FactLockCam_Product_Baseline_2026-05]]
