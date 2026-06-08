import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import { existsSync } from 'fs';
import { fileURLToPath } from 'url';

function optionalConfigJson(configPath) {
  return {
    name: 'optional-config-json',
    resolveId(id) {
      if (id.endsWith('config.json') && !existsSync(configPath)) {
        return '\0virtual:empty-config';
      }
    },
    load(id) {
      if (id === '\0virtual:empty-config') {
        return 'export default {}';
      }
    },
  };
}

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
    plugins: [
      react(),
      optionalConfigJson(fileURLToPath(new URL('./config.json', import.meta.url))),
    ],
    css: {
      preprocessorOptions: {
        scss: {
          silenceDeprecations: [
            'legacy-js-api',
            'import',
            'if-function',
            'global-builtin',
            'color-functions',
          ],
        },
      },
    },
  };
});
