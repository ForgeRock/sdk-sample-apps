import { defineConfig, devices } from '@playwright/test';

const url = process.env.PLAYWRIGHT_TEST_BASE_URL || 'https://localhost:8443';

export default defineConfig({
  testDir: 'e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    trace: 'on',
    baseURL: `${url}`,
    ignoreHTTPSErrors: true,
    headless: !!process.env.CI,
  },
  webServer: [
    {
      command: 'npm run start:reactjs-todo',
      url,
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
      cwd: '../',
      env: {
        API_URL: 'http://localhost:9443',
        DEBUGGER_OFF: 'true',
        DEVELOPMENT: 'false',
        JOURNEY_LOGIN: 'Login',
        JOURNEY_REGISTER: 'Registration',
        PORT: '9443',
        SERVER_URL: 'https://openam-sdks.forgeblocks.com/am',
        WELLKNOWN_URL:
          'https://openam-sdks.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration',
        REALM_PATH: 'alpha',
        SCOPE: 'profile me.read email',
        TIMEOUT: '3000',
        WEB_OAUTH_CLIENT: 'CentralLoginOAuthClient-',
        REST_OAUTH_CLIENT: 'RestOAuthClient',
        REST_OAUTH_SECRET: process.env.REST_OAUTH_SECRET || '',
        CENTRALIZED_LOGIN: 'false',
        INIT_PROTECT: 'false',
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
      grepInvert: /WebAuthN/i,
      use: { ...devices['Desktop Firefox'] },
    },
  ],
});
