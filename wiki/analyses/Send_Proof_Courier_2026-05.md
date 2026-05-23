---
tags: [analysis, factlockcam, courier, send_proof, app_store, 2026-05]
summary: "Send Proof workflow: certificate PDF + courier link via share sheet; no in-app email; production blocked until public web vault is deployed."
---

# Send Proof & Courier (May 2026)

## Core Synthesis

**Send Proof** lets an archive owner deliver tamper-evident proof to a recipient: a **certificate PDF** (asset hash, optional Polygon tx link) plus a **password-protected web link** where the recipient unlocks encrypted media in the browser.

**Product positioning (App Store):** FactLockCam is a **capture-and-archive utility**, not a messaging app. The mobile app **does not send email** (no Resend/SMTP, no server-side outbound mail from the app). Delivery is **owner-side only** via the iOS **share sheet** (Messages, Mail, AirDrop, etc.). The owner shares the PDF and link; the password is communicated **out-of-band** by the owner.

**Production gate:** Recipient links only work when `WEB_VAULT_BASE_URL` points at a **live public HTTPS** Flutter Web deploy serving `/courier?pkg=…`. Until a permanent web vault is hosted, **end-to-end Send Proof for real recipients is intentionally deferred** — the product stays stealth (no purchased marketing domain required for dev).

### What works today (no public website)

| Capability | Status |
|------------|--------|
| Seal / archive / view on device | Verified |
| Certificate PDF generation (`CertificateExportService`, `pdf` package) | Implemented |
| Courier package upload + link creation (`createCourierPackage`, Supabase RPC + Storage) | Implemented |
| `SendProof` Riverpod notifier (`send_proof_provider.dart`) | Wired to UI |
| Share sheet: PDF + courier URL text | Default Send Proof UX |
| Recipient opens link in browser and unlocks | **Blocked** until public web vault URL exists |

### What does not ship in the app

- In-app or server-triggered **email dispatch** (`dispatch-courier` removed from repo; not called from Flutter).
- **Zip proof bundles** on the Send Proof path (removed — corrupt README byte-length bug; full decrypted video in zip was wrong UX). `ProofBundleExportService` remains for optional export; not used in Send Proof dialog.
- **Ngrok / localhost** as a customer path — **developer QA only** (`scripts/start_qa_env.sh`, ephemeral-environments rule).

### Owner flow (current UI)

1. Archive → **Send Proof** → password (+ optional certificate title/description).
2. `SendProof` builds PDF, calls `VaultService.createCourierPackage`, returns URL + PDF path.
3. iOS share sheet: attach **factlockcam-certificate.pdf** + paste **courier URL** in share text.
4. Owner tells recipient the password separately.

### Recipient flow (when web vault is live)

1. Tap link: `{WEB_VAULT_BASE_URL}/courier?pkg={uuid}`.
2. Web `CourierUnlockView` → `courier-unlock` edge function (signed blob URL) + local decrypt (`CourierCrypto`).
3. Download quota enforced in DB migration `20260524120000_courier_download_limits.sql` (`max_downloads`, `download_count`, 7-day `expires_at`).

### `WEB_VAULT_BASE_URL` semantics

- **Compile-time** dart-define; cold rebuild required when changed (`vault_service_io.dart` `_effectiveCourierWebVaultBase`).
- Non-empty define **always wins**; debug-only fallback to `http://localhost:3000` only when define was **not** passed.
- **Release/profile** rejects localhost — recipients on other devices cannot reach it.
- **Production:** set once to the permanent hosted web origin (e.g. future `https://vault.example.com`) before App Store submission.
- **Pre-launch / stealth:** No domain purchase required for continued app development; defer full Send Proof QA until web host exists. TestFlight does **not** fix broken links unless that build’s define points at a **live** public site.

### Backend (May 2026)

| Artifact | Role |
|----------|------|
| `get_or_create_courier_package` | Owner origination RPC |
| `attempt_courier_unlock` | Password gate + download counter |
| `courier-unlock` edge function | Signed Storage URL for web recipients |
| `courier_download_limits` migration | Egress / abuse limits |
| `dispatch-courier` | **Removed** — email out of product scope |

### Implementation fixes (same sprint)

- **`ProofCourierService`:** Removed nested `Isolate.run` that captured non-sendable `SupabaseClient` (Send Proof upload crash on device).
- **`CourierRepository`:** Web unlock via `courier-unlock` + signed URL download (not direct anon Storage from client after quota hardening).

### Open decision (owner, 2026-05)

**Finalize Send Proof for customers when:** a public Flutter Web vault is deployed at a stable HTTPS origin and the App Store build bakes that URL into `WEB_VAULT_BASE_URL`. Until then, treat courier link E2E as **parked**; continue capture, archive, on-device certificate share, and Polygon work without exposing product via marketing domain.

## Provenance Tracking

* *Product decisions (no in-app email, defer until web host, stealth pre-App Store)*: Agent session synthesis 2026-05-24; owner confirmation in conversation.
* *Code*: `factlockcam_app/lib/features/archive/presentation/providers/send_proof_provider.dart`, `archive_item_actions.dart`, `certificate_export_service.dart`, `proof_courier_service.dart`, `courier_repository.dart`, `courier-unlock` edge function, `supabase/migrations/20260524120000_courier_download_limits.sql`, `.cursor/rules/archive-courier-origination.mdc`, `.cursor/rules/courier-origination.mdc`.
* *Prior audit*: `FactLockCam_SendProof_Blueprints.md` (repo root, May 2026).

## Related Notes

* [[FactLockCam_Product_Baseline_2026-05]]
* [[App_Store_Prep_Capture_Seal_2026-05]]
* [[Identity_Lifecycle_And_Data_Lineage]]
* [[FactLockCam_Blueprints_14May2026]]
* [[ProofLock_Refactor_Scope]]
* [[overview]]
