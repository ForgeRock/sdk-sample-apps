import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: 'e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    trace: 'on',
    ignoreHTTPSErrors: true,
    headless: !!process.env.CI,
  },
  webServer: [
    // PingOne client
    {
      command: 'npm run dev',
      url: 'http://localhost:8443',
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
      cwd: './',
      env: {
        VITE_PORT: '8443',
        VITE_WEB_OAUTH_CLIENT: '654b14e2-7cc5-4977-8104-c4113e43c537',
        VITE_SCOPE: 'openid profile email revoke',
        VITE_TIMEOUT: 3000,
        VITE_WELLKNOWN_URL:
          'https://auth.pingone.ca/02fb4743-189a-4bc7-9d6c-a919edfe6447/as/.well-known/openid-configuration',
      },
      ignoreHTTPSErrors: true,
    },

    // PingAM client
    {
      command: 'npm run dev',
      url: 'http://localhost:8444',
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
      cwd: './',
      env: {
        VITE_PORT: '8444',
        VITE_WEB_OAUTH_CLIENT: 'WebOAuthClient',
        VITE_SCOPE: 'openid profile email',
        VITE_TIMEOUT: 3000,
        VITE_WELLKNOWN_URL:
          'https://openam-sdks.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration',
      },
      ignoreHTTPSErrors: true,
    },
  ],
  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
  ],
});
