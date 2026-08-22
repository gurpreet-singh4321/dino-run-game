import { defineConfig } from 'astro/config';
import vercel from '@astrojs/vercel/static';

export default defineConfig({
  site: 'https://dinorunepochs.com',
  output: 'static',
  adapter: vercel({
    speedInsights: {
      enabled: true,
    },
    webAnalytics: {
      enabled: true,
    },
  }),
  server: {
    port: 4321,
    host: true,
  },
});


