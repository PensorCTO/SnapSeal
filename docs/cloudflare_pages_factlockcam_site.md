# Cloudflare Pages — FactLockCam marketing site

Project path: `projects/FactLockCam_Site`  
Live URLs: `https://factlockcam.pages.dev`, `https://factlockcam.com`

## “No deployment available”

That message means **Cloudflare has never finished a successful upload** for this project—not that your code is missing.

Common causes:

1. **Git is not connected** to the Pages project (project exists but never built).
2. **Every build failed** (wrong root directory, old Worker/KV setup, or missing `npm ci`).
3. **GitHub Actions deploy failed** — missing `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID` secrets (build can pass, upload still fails).
4. **Wrangler deploy never succeeded** — `Authentication error [code: 10000]` on your machine.

**Fix:** complete **one** of the three paths below. After the first **Success** deployment, the overview will show a URL and “No deployment available” goes away.

---

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

## Deploy paths (pick one)

### Path 1 — Connect Git in Cloudflare (recommended)

1. [Cloudflare Dashboard](https://dash.cloudflare.com) → **Workers & Pages** → open project **`factlockcam`** (create it as **Pages** if missing).
2. **Settings** → **Builds & deployments** → **Connect to Git** (or **Connect repository**).
3. Choose **`PensorCTO/SnapSeal`**, branch **`main`**.
4. Set build settings from the table above → **Save**.
5. **Deployments** → **Create deployment** / **Retry deployment** on latest commit (`397518d` or newer).
6. Wait until status is **Success** (not Failed). Then open `https://factlockcam.pages.dev`.

If **Deployments** stays empty after Save, click **Manage deployment** → **Deploy site** once manually.

### Path 2 — Direct upload from your Mac (no Git on Cloudflare)

```bash
cd /Users/paulensor/Projects/ProofLockCleanup/projects/FactLockCam_Site
npm ci && npm run build
npx wrangler login
npx wrangler pages deploy dist --project-name=factlockcam --branch=main --commit-dirty=true
```

When Wrangler prints a deployment URL, that becomes your first deployment. Refresh the Cloudflare **Deployments** tab.

### Path 3 — GitHub Actions

Repo → **Settings** → **Secrets and variables** → **Actions** → add:

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`

Then **Actions** → **Deploy FactLockCam marketing site** → **Run workflow**.

## QA check after deploy

View source on homepage must include:

- `hero-background.svg`
- `Sovereign Zero-Knowledge` (or current headline from `src/copy/marketing.ts`)

Must **not** include:

- `factlockcam-hero-sales`
- `personal history`
- `completely safe from modification`
