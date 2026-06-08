---
tags: [analysis, factlockcam, courier, send_proof, app_store, 2026-05]
summary: "Send Proof workflow (historical): certificate PDF + courier link via share sheet; decommissioned 2026-06-08 — use Certificate Studio."
---

# Send Proof & Courier (May 2026)

> **Status (2026-06-08):** Send Proof and courier origination **decommissioned** from active mobile and web surfaces. Owner export is **Certificate Studio** (local PDF print/share). Supabase courier backend retained. See [[Unified_Archive_Studio_2026-06]].

## Core Synthesis

**Send Proof** lets an archive owner deliver tamper-evident proof to a recipient: a **certificate PDF** (asset hash, optional Polygon tx link) plus a **password-protected web link** where the recipient unlocks encrypted media in the browser.

**Product positioning (App Store):** FactLockCam is a **capture-and-archive utility**, not a messaging app. The mobile app **does not send email** (no Resend/SMTP, no server-side outbound mail from the app). Delivery is **owner-side only** via the iOS **share sheet** (Messages, Mail, AirDrop, etc.). The owner shares the PDF and link; the password is communicated **out-of-band** by the owner.

**Production gate:** Recipient links require a **live public HTTPS** Flutter Web deploy at **`WEB_ARCHIVE_BASE_URL`** (production default: `https://archive.factlockcam.com`). The archive host is **courier-only** — not a browser edition of the mobile app ([[Web_Deployment_Architecture_2026-05]]). Deploy via `./scripts/deploy_web_archive_cf.sh`; bind custom domain in Cloudflare Pages. For **TestFlight**, an Ngrok tunnel origin in `.env.local` is acceptable ([[App_Store_Remediation_2026-05]]).

### What works today (fourteenth QA, 2026-05-29)

| Capability | Status |
|------------|--------|
| Seal / archive / view on device | Verified |
| Certificate PDF generation (`CertificateExportService`, `pdf` package) | Implemented |
| Courier package upload + link creation (`createCourierPackage`, Supabase RPC + Storage) | Implemented |
| `SendProof` Riverpod notifier (`send_proof_provider.dart`) | Wired to UI |
| Share sheet: PDF + courier URL text | Default Send Proof UX |
| Recipient opens link in browser and unlocks | **QA passed** — Secure Communications Console on Cloudflare Pages (`/courier?pkg=…`); interim host `main.factlockcam-archive.pages.dev`; custom domain bind required for production URL ([[Secure_Communications_Console_2026-06]]) |

### What does not ship in the app

- In-app or server-triggered **email dispatch** (`dispatch-courier` removed from repo; not called from Flutter).
- **Zip proof bundles** on the Send Proof path (removed — corrupt README byte-length bug; full decrypted video in zip was wrong UX). `ProofBundleExportService` remains for optional export; not used in Send Proof dialog.
- **Ngrok / localhost** as a customer path — **developer QA only** (`scripts/start_qa_env.sh`, ephemeral-environments rule).

### Owner flow (current UI)

1. Set title/description via inspector or **Manage title and description** on the action sheet (sixteenth QA).
2. Archive → **Send Proof** → **recipient password only** (certificate fields come from stored metadata).
3. `SendProof` resolves fresh `ArchiveItem` from dashboard, builds PDF (no title/description overrides), calls `createCourierPackage`.
4. iOS share sheet: attach **factlockcam-certificate.pdf** + paste **courier URL** in share text.
5. Owner tells recipient the password separately.

**Debug QA:** `AppConfig.enableProofLinks` is true when `WEB_ARCHIVE_BASE_URL` is set, even if `dart_defines.json` has `ENABLE_PROOF_LINKS=false`. Release/profile builds still require explicit `true` after `verify_web_archive_deploy.sh` ([[Archive_Owner_UX_2026-05]], [[App_Store_Hardening_2026-05]]).

### Recipient flow (when web archive is live)

1. Tap link: `{WEB_ARCHIVE_BASE_URL}/courier?pkg={uuid}`.
2. Web `CourierUnlockView` → `courier-unlock` edge function (signed blob URL) + local decrypt (`CourierCrypto`).
3. Download quota enforced in DB migration `20260524120000_courier_download_limits.sql` (`max_downloads`, `download_count`, 7-day `expires_at`).

### `WEB_ARCHIVE_BASE_URL` semantics

- **Compile-time** dart-define; cold rebuild required when changed (`vault_service_io.dart` `_effectiveCourierWebArchiveBase`).
- Non-empty define **always wins**; debug-only fallback to `http://localhost:3000` only when define was **not** passed.
- **Release/profile** rejects localhost — recipients on other devices cannot reach it.
- **Production default:** `https://archive.factlockcam.com` in `dart_defines.json` / sync script (tenth QA, [[App_Store_Remediation_2026-05]]). Rebuild with `--dart-define-from-file dart_defines.json`.
- **TestFlight:** Set `WEB_ARCHIVE_BASE_URL` to Ngrok or staging in `.env.local`, re-sync, rebuild IPA — no purchased domain required.
- **App Store review:** Purchased domain + live support URL required.

### Backend (May 2026)

| Artifact | Role |
|----------|------|
| `get_or_create_courier_package` | Owner origination RPC |
| `attempt_courier_unlock` | Password gate + download counter |
| `courier-unlock` edge function | Signed Storage URL for web recipients |
| `courier_download_limits` migration | Egress / abuse limits |
| `optimize_courier_lookups` migration | `unlock_code` / `status` columns + lookup index |
| `optimize_courier_archive` migration | Btree indices on `asset_hash`, `(package_id, expires_at)`, `(owner_id, asset_hash)` — tenth QA |
| `dispatch-courier` | **Removed** — email out of product scope |

### Implementation fixes (same sprint)

- **`ProofCourierService`:** Removed nested `Isolate.run` that captured non-sendable `SupabaseClient` (Send Proof upload crash on device).
- **`CourierRepository`:** Web unlock via `courier-unlock` + signed URL download (not direct anon Storage from client after quota hardening).

### Open decision (owner, 2026-05)

**Finalize Send Proof for App Store when:** `archive.factlockcam.com` custom domain is **Active** in Cloudflare Pages and `./scripts/verify_web_archive_deploy.sh` passes. Marketing at **`factlockcam.com`** deploys separately via `./scripts/deploy_factlockcam_site_cf.sh` ([[Web_Deployment_Architecture_2026-05]]).

## Provenance Tracking

* *Product decisions (no in-app email, defer until web host, stealth pre-App Store)*: Agent session synthesis 2026-05-24; owner confirmation in conversation.
* *Code*: `factlockcam_app/lib/features/archive/presentation/providers/send_proof_provider.dart`, `archive_item_actions.dart`, `certificate_export_service.dart`, `proof_courier_service.dart`, `courier_repository.dart`, `courier-unlock` edge function, `supabase/migrations/20260524120000_courier_download_limits.sql`, `.cursor/rules/archive-courier-origination.mdc`, `.cursor/rules/courier-origination.mdc`.
* *Prior audit*: `FactLockCam_SendProof_Blueprints.md` (repo root, May 2026).

## Related Notes

* [[Secure_Communications_Console_2026-06]]
* [[Archive_Owner_UX_2026-05]]
* [[Web_Deployment_Architecture_2026-05]]
* [[Production_Transition_2026-05]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[Identity_Lifecycle_And_Data_Lineage]]
* [[FactLockCam_Blueprints_14May2026]]
* [[ProofLock_Refactor_Scope]]
* [[overview]]
