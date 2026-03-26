import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const PORT = parseInt(env.VITE_PORT) || 8443;

  return {
    root: __dirname + '/client',
    publicDir: __dirname + '/public',
    envDir: __dirname,
    build: {
      outDir: __dirname + '/dist',
      emptyOutDir: true,
      reportCompressedSize: true,
      target: 'esnext',
      minify: false,
    },
    preview: {
      port: PORT,
    },
    server: {
      port: PORT,
      open: true,
      strictPort: true,
    },
    plugins: [react()],
  };
});
