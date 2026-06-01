# FactLockCam Site

Compliance and courier web surface for FactLockCam, built with **Astro**, **Tailwind CSS**, and **React islands**, deployed to **Cloudflare Pages**.

## Routes

| Path | Rendering | Purpose |
|------|-----------|---------|
| `/` | SSG | Marketing landing + App Store badge |
| `/support` | SSG | Guideline 5.1.1 support contact + FAQ |
| `/privacy` | SSG | Privacy Policy |
| `/terms` | SSG | Terms of Service (EULA) |
| `/guide` | SSG | Consumer user guide (legal detail in Terms) |
| `/courier?pkg={uuid}` | SSG shell + client hydrate | **Flutter Send Proof links** (current app format) |
| `/courier?pkg={uuid}` | SSG + client hydrate | Optional courier demo on marketing site; production links use `archive.factlockcam.com` |

## Hero background (marketing)

The homepage uses **HTML copy** from [`src/copy/marketing.ts`](src/copy/marketing.ts) and a **text-free** background at `public/images/hero-background.svg`.

To swap the graphic manually, see [`public/images/README.md`](public/images/README.md). Legacy assets with baked copy live in `public/images/_deprecated/` and are not linked from the site.

## Local development

```bash
cd projects/FactLockCam_Site
cp .env.example .env
# Fill PUBLIC_SUPABASE_URL and PUBLIC_SUPABASE_ANON_KEY
npm install
npm run dev
```

## Cloudflare Pages deploy

**Exact dashboard values and failure fixes:** [`docs/cloudflare_pages_factlockcam_site.md`](../../docs/cloudflare_pages_factlockcam_site.md)

### Option A — GitHub Actions (recommended)

Workflow: [`.github/workflows/factlockcam-site.yml`](../../.github/workflows/factlockcam-site.yml)

1. In GitHub → **Settings → Secrets and variables → Actions**, add:
   - `CLOUDFLARE_API_TOKEN` — token with **Cloudflare Pages Edit** permission
   - `CLOUDFLARE_ACCOUNT_ID` — from Cloudflare dashboard URL
2. Push to `main` (or run the workflow manually under **Actions**).
3. Verify `https://factlockcam.pages.dev/` shows `hero-background.svg` in page source.

### Option B — Wrangler CLI (local)

```bash
npx wrangler login
bash scripts/deploy_factlockcam_site_cf.sh
```

If you see `Authentication error [code: 10000]`, re-login or use Option A.

### Option C — Cloudflare dashboard (Git-connected)

1. Pages → project **factlockcam** → **Settings → Builds**
2. Root directory: `projects/FactLockCam_Site`
3. Build command: `npm run build` · Output: `dist`
4. **Retry deployment** on the latest `main` commit after push.

Environment variables (if courier pages need Supabase): `PUBLIC_SUPABASE_URL`, `PUBLIC_SUPABASE_ANON_KEY`

## Flutter integration

The iOS app generates courier URLs as:

```text
{WEB_ARCHIVE_BASE_URL}/courier?pkg={package_id}
```

After deploying this site, set:

```json
{
  "WEB_ARCHIVE_BASE_URL": "https://factlockcam.pages.dev",
  "SUPPORT_URL": "https://factlockcam.pages.dev/support"
}
```

Rebuild the iOS app with `--dart-define-from-file=dart_defines.json`.

## Archive unlock (follow-up)

`VaultCourier.tsx` (internal component name) wires `check_courier_attempts` and `courier-unlock` today. Browser-side AES-GCM decrypt + SHA-256 verify (parity with Flutter `CourierCrypto`) is the next implementation step.
