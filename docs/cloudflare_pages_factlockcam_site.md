# Cloudflare Pages — FactLockCam marketing site

Project path: `projects/FactLockCam_Site`  
Live URLs: `https://factlockcam.pages.dev`, `https://factlockcam.com`

## Dashboard settings (exact values)

| Field | Value |
|-------|--------|
| **Production branch** | `main` |
| **Framework preset** | `Astro` or `None` |
| **Root directory** | `projects/FactLockCam_Site` |
| **Build command** | `npm ci && npm run build` |
| **Build output directory** | `dist` |
| **Node.js version** | `20` (recommended) |

Environment variables (optional — courier page on this site only; production courier is on `archive.factlockcam.com`):

| Variable | Notes |
|----------|--------|
| `PUBLIC_SUPABASE_URL` | Only if testing `/courier` on marketing site |
| `PUBLIC_SUPABASE_ANON_KEY` | Anon key only |

## Why builds were failing

The site previously used `@astrojs/cloudflare`, which produced:

- `dist/_worker.js/` (Workers runtime)
- `dist/_routes.json` with Functions routing
- **SESSION** KV binding requirement

Standard **Cloudflare Pages static** deploys (Git UI with output `dist`) do **not** provision that KV binding → build/deploy errors or broken runtime.

The site is now **pure static** (`output: 'static'`, no Cloudflare adapter). `dist/` contains only HTML, CSS, JS, and images.

## Verify locally before deploy

```bash
cd projects/FactLockCam_Site
npm ci && npm run build
ls dist/index.html dist/images/hero-background.svg
test ! -d dist/_worker.js && echo "OK: no worker bundle"
```

## Deploy paths

1. **Cloudflare Git integration** — push to `main`, correct table above, Retry deployment.
2. **GitHub Actions** — add repo secrets `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID`, run workflow `Deploy FactLockCam marketing site`.
3. **Wrangler CLI** — `npx wrangler login` then `bash scripts/deploy_factlockcam_site_cf.sh` from repo root.

## QA check after deploy

View source on homepage must include:

- `hero-background.svg`
- `Sovereign Zero-Knowledge` (or current headline from `src/copy/marketing.ts`)

Must **not** include:

- `factlockcam-hero-sales`
- `personal history`
- `completely safe from modification`
