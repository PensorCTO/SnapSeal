/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        titanium: {
          deep: '#121212',
          panel: '#1C1C1C',
          edge: '#2A2A2A',
          highlight: '#3A3A3A',
        },
        kinetic: {
          green: '#00D26A',
        },
        verified: {
          neon: '#39FF14',
        },
        alert: {
          amber: '#FFB300',
        },
      },
      fontFamily: {
        mono: ['"Space Mono"', 'ui-monospace', 'SFMono-Regular', 'monospace'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [require('@tailwindcss/typography')],
};
