# FactLockCam Site

Compliance and courier web surface for FactLockCam, built with **Astro**, **Tailwind CSS**, and **React islands**, deployed to **Cloudflare Pages**.

## Routes

| Path | Rendering | Purpose |
|------|-----------|---------|
| `/` | SSG | Marketing landing + App Store badge |
| `/support` | SSG | Guideline 5.1.1 support contact + FAQ |
| `/privacy` | SSG | Privacy Policy |
| `/terms` | SSG | Terms of Service (EULA) |
| `/guide` | SSG | User guide + FRE 902 explainer |
| `/courier?pkg={uuid}` | SSG shell + client hydrate | **Flutter Send Proof links** (current app format) |
| `/vault/{uuid}` | SSR shell + client hydrate | Blueprint dynamic courier route |

## Local development

```bash
cd projects/FactLockCam_Site
cp .env.example .env
# Fill PUBLIC_SUPABASE_URL and PUBLIC_SUPABASE_ANON_KEY
npm install
npm run dev
```

## Cloudflare Pages deploy

1. Push this directory to a GitHub repository (or monorepo subpath).
2. Cloudflare Pages → Connect to Git → Build command: `npm run build`
3. Build output: `dist`
4. Root directory: `projects/FactLockCam_Site` (if using monorepo)
5. Environment variables: `PUBLIC_SUPABASE_URL`, `PUBLIC_SUPABASE_ANON_KEY`
6. Bind the issued `*.pages.dev` URL to `WEB_ARCHIVE_BASE_URL` and `SUPPORT_URL` in Flutter `dart_defines.json`.

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

## Vault unlock (follow-up)

`VaultCourier.tsx` wires `check_courier_attempts` and `courier-unlock` today. Browser-side AES-GCM decrypt + SHA-256 verify (parity with Flutter `CourierCrypto`) is the next implementation step.
