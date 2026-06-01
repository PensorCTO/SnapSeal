# Homepage hero background

## Active asset

| File | Purpose |
|------|---------|
| **`hero-background.svg`** | Default text-free atmospheric background (committed). |

The homepage reads its path from `src/copy/marketing.ts` → `heroBackgroundSrc`.

## Replace manually (Marketing / Design)

1. Export a **1920×1080** (or larger 16:9) image with **no headlines or marketing copy** baked in—atmosphere only (gradients, abstract tech, titanium palette).
2. Save as one of:
   - `hero-background.webp` (preferred for photos)
   - `hero-background.jpg`
   - `hero-background.svg` (vector / abstract)
3. Update `heroBackgroundSrc` in [`src/copy/marketing.ts`](../src/copy/marketing.ts) to match your filename.
4. Run `npm run build` and deploy.

## Do not use (legacy — contains baked obsolete copy)

- `factlockcam-hero-sales.png`
- `factlockcam-hero-sales-v2.png`
- `FactlockcamPanel1.jpg`

These files are kept out of the homepage markup but should not be re-linked without a Legal/Marketing review of embedded text.
