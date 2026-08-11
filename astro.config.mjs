import { defineConfig } from 'astro/config';
import vercel from '@astrojs/vercel';

export default defineConfig({
  site: 'https://dinorunepochs.com',
  adapter: vercel(),
  server: {
    port: 4321,
    host: true
  }
});

