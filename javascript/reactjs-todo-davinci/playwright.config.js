import { defineConfig, devices } from '@playwright/test';
const url = process.env.PLAYWRIGHT_TEST_BASE_URL || 'http://localhost:8443';
const CLIENT_ID = '3ddfa67a-066a-42ac-afd3-f6822b0789a2';
const ENVIRONMENT_ID = '356a254c-cba3-4ade-be1a-860136e8df01';

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
      command: 'npm run start',
      url,
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
      cwd: './',
      env: {
        API_URL: 'http://localhost:9443',
        DEBUGGER_OFF: 'true',
        DEVELOPMENT: 'false',
        PORT: '8443',
        PINGONE_ENV_ID: ENVIRONMENT_ID,
        SDK_CLIENT_ID: CLIENT_ID,
        SDK_DISCOVERY_ENDPOINT: `https://auth.pingone.ca/${ENVIRONMENT_ID}/as/.well-known/openid-configuration`,
        SDK_SCOPE: 'openid profile email phone revoke',
      },
      ignoreHTTPSErrors: true,
    },
    {
      command: 'npm run start',
      url: 'http://localhost:9443/healthcheck',
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
      cwd: '../todo-api/',
      env: {
        PORT: '9443',
        SERVER_TYPE: 'PINGONE',
        SERVER_URL: `https://auth.pingone.ca/${ENVIRONMENT_ID}`,
        REST_OAUTH_CLIENT: CLIENT_ID,
      },
      ignoreHTTPSErrors: true,
    },
    // Uncomment the server below to be able run e2e FIDO tests
    // {
    //   command: 'npm run start',
    //   url: 'http://localhost:5829',
    //   timeout: 120 * 1000,
    //   reuseExistingServer: !process.env.CI,
    //   cwd: './',
    //   env: {
    //     API_URL: 'http://localhost:9443',
    //     DEBUGGER_OFF: 'true',
    //     DEVELOPMENT: 'false',
    //     PORT: '5829',
    //     SDK_CLIENT_ID: CLIENT_ID,
    //     SDK_DISCOVERY_ENDPOINT: `https://auth.pingone.ca/${ENVIRONMENT_ID}/as/.well-known/openid-configuration`,
    //     SDK_SCOPE: 'openid profile email phone revoke',
    //   },
    //   ignoreHTTPSErrors: true,
    // },
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
