import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: '/',
  plugins: [react()],
  server: {
    port: 5173,
    open: false,
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    chunkSizeWarningLimit: 1200,
    rolldownOptions: {
      output: {
        codeSplitting: {
          groups: [
            {
              name: 'vendor-react',
              test: /node_modules[\\/](react|react-dom|react-router|react-router-dom|scheduler)[\\/]/,
            },
            {
              name: 'vendor-markdown',
              test: /node_modules[\\/](highlight\.js|marked|marked-highlight|dompurify|fuse\.js|lucide-react)[\\/]/,
            },
            {
              name: 'content-data',
              test: /src[\\/]content[\\/]generated\.json$/,
            },
          ],
        },
      },
    },
  },
});
