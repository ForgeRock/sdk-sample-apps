import { defineConfig, devices } from '@playwright/test';

const url = process.env.PLAYWRIGHT_TEST_BASE_URL || 'http://localhost:8443';

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
      cwd: './',
      command: 'npm run start',
      url,
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
      env: {
        API_URL: 'http://localhost:9443',
        DEVELOPMENT: 'false',
        PORT: '8443',
        WEB_OAUTH_CLIENT: "724ec718-c41c-4d51-98b0-84a583f450f9",
        SCOPE: "openid profile email phone name revoke",
        WELLKNOWN_URL: "https://auth.pingone.ca/02fb4743-189a-4bc7-9d6c-a919edfe6447/as/.well-known/openid-configuration",
      },
      ignoreHTTPSErrors: true,
    },
    {
      cwd: '../todo-api/',
      command: 'npm run start',
      url: 'http://localhost:9443/healthcheck',
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
      env: {
        PORT: '9443',
        SERVER_TYPE: "PINGONE",
        SERVER_URL: "https://auth.pingone.ca/02fb4743-189a-4bc7-9d6c-a919edfe6447",
        REST_OAUTH_CLIENT: "724ec718-c41c-4d51-98b0-84a583f450f9",
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
