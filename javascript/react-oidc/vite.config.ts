// import * as path from 'path';
import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const PORT = parseInt(env.VITE_PORT) || 8443;

  return {
    root: __dirname,
    build: {
      outDir: './dist',
      reportCompressedSize: true,
      target: 'esnext',
      minify: false,
      // rollupOptions: {
      //   input: {
      //     main: path.resolve(__dirname, 'index.html'),
      //   },
      //   output: {
      //     entryFileNames: 'main.js',
      //   },
      // },
    },
    preview: {
      port: PORT,
    },
    server: {
      port: PORT,
      headers: {
        'Service-Worker-Allowed': '/',
        'Service-Worker': 'script',
      },
      strictPort: true,
    },
    plugins: [react()],
  };
});
