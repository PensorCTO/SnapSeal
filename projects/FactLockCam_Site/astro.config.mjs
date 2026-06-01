import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import react from '@astrojs/react';

// Pure static output for Cloudflare Pages (no Workers / SESSION KV binding).
// Send Proof courier unlock lives on archive.factlockcam.com (Flutter web).
export default defineConfig({
  site: 'https://factlockcam.com',
  output: 'static',
  integrations: [
    tailwind({
      applyBaseStyles: false,
    }),
    react(),
  ],
});
