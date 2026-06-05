---
tags: [analysis, factlockcam, web, deployment, courier, cloudflare, qa, 2026-05]
summary: "Fourteenth QA (2026-05-29): decoupled web surfaces — factlockcam.com sales pitch (Astro) and archive.factlockcam.com courier-only Flutter gate; native capture exclusive."
---

# Web Deployment Architecture (May 2026)

## Core Synthesis

**Fourteenth device QA pass (2026-05-29)** — user-confirmed after splitting public web from the mobile app and hardening lens-to-cloud boundaries.

FactLockCam public web is **two hosts**, not a browser clone of the iOS app:

| Host | Stack | Purpose |
|------|-------|---------|
| **`https://factlockcam.com`** | Astro (`projects/FactLockCam_Site`) | Master sales pitch, `/support`, `/privacy`, `/terms`, `/guide` |
| **`https://archive.factlockcam.com`** | Flutter Web (`scripts/build_web_archive.sh`) | **Courier unlock only** — `/courier?pkg={uuid}` + minimal gate at `/` |

**Native iOS/Android** retains exclusive rights to **capture, seal, archive origination, and Send Proof**. Browser capture is disabled; web router gates block logon/hub/archive routes on the archive subdomain.

### Marketing site (`factlockcam.com`)

- **`src/pages/index.astro`** — defensive mechanism copy from `src/copy/marketing.ts`; CSS hero backdrop by default (legacy `factlockcam-hero-sales.png` has baked copy—use text-free `factlockcam-hero-sales-v2.png` when ready).
- **`astro.config.mjs`** — `site: https://factlockcam.com`
- **Deploy:** `./scripts/deploy_factlockcam_site_cf.sh` → Cloudflare Pages project `factlockcam` (override via `CF_PAGES_PROJECT`).

### Archive courier SPA (`archive.factlockcam.com`)

- **Build:** `flutter build web --release --pwa-strategy=none --dart-define-from-file=dart_defines.json`
- **Deploy:** `./scripts/deploy_web_archive_cf.sh` → Cloudflare Pages project **`factlockcam-archive`**
- **SPA rewrites:** `factlockcam_app/web/_redirects` → copied into `build/web/` (`/* /index.html 200`)
- **Verify:** `./scripts/verify_web_archive_deploy.sh https://archive.factlockcam.com`

### Flutter web routing (courier-only)

`AppRouterRefreshNotifier` on **`kIsWeb`**:

- **`/`** → `WebArchiveGateView` — “courier unlock only”; link to `WEB_BASE_URL` / `factlockcam.com`
- **`/courier?pkg=…`** → `CourierUnlockView` — **Secure Communications Console** (phased gate → hash cascade → decrypt → media + Proof Panel → viral CTA); see [[Secure_Communications_Console_2026-06]]
- **Any other path** → redirect to `/` gate

Mobile routing unchanged (logon → hub → capture/archive).

### Browser capture prohibition

- Conditional exports: `capture_panel.dart` (IO → `CameraView`; web → `WebCaptureDisabledPanel`)
- Hub Picture/Video tiles hidden when `kIsWeb`
- `NativeEnclaveChannel` registered only when `!kIsWeb`; web stub throws if invoked
- Rule: `.cursor/rules/web-subdomain-deployment.mdc`

### Compile-time defines

| Define | Production target |
|--------|-------------------|
| `WEB_ARCHIVE_BASE_URL` | `https://archive.factlockcam.com` (Send Proof links) |
| `WEB_BASE_URL` | `https://factlockcam.com` (marketing + gate “Learn more” link) |
| `SUPPORT_URL` | `https://factlockcam.com/support` |

Sync via `./scripts/sync_flutter_dart_defines.sh`.

### Cloudflare ops notes

- First deploy may require Wrangler interactive prompts (project create, production branch) — see `.cursor/rules/cli-execution-gating.mdc`
- **Custom domains** must be bound in Pages dashboard: `archive.factlockcam.com` → `factlockcam-archive`; `factlockcam.com` → marketing project
- Empty Pages deployments return **522**; unbound custom domain DNS returns **530**
- Working alias after deploy: `https://main.factlockcam-archive.pages.dev`

### Secure Communications Console (twenty-sixth / twenty-seventh pass, 2026-06-05)

- Phase machine: `CourierUnlockPhase` + `CourierUnlockNotifier` staged unlock (RPC → 1.5s cascade → `CourierCrypto`).
- Proof Panel: `get_public_proof_attestation` RPC (`20260605140000`).
- Interim QA origin: `https://main.factlockcam-archive.pages.dev` when custom domain DNS is not bound.
- **Twenty-seventh QA passed** — Send Proof E2E stable; **101/101** tests.

### Tests

`flutter test` **101/101** (includes Secure Communications Console + UGC reporting suites).

## Provenance Tracking

* *Product decision*: Archive subdomain is courier-only; marketing on apex; no browser edition of mobile app — owner confirmation + fourteenth QA 2026-05-29.
* *Code*: `app_router.dart`, `web_archive_gate_view.dart`, `web_capture_disabled_panel.dart`, `capture_panel*.dart`, `haptic_hub_panel.dart`, `deploy_web_archive_cf.sh`, `deploy_factlockcam_site_cf.sh`, `FactLockCam_Site/src/pages/index.astro`.

## Related Notes

* [[Secure_Communications_Console_2026-06]]
* [[Send_Proof_Courier_2026-05]]
* [[App_Store_Remediation_2026-05]]
* [[FactLockCam_Product_Baseline_2026-05]]
* [[Sovereign_Key_Lifecycle_2026-05]]
* [[overview]]
