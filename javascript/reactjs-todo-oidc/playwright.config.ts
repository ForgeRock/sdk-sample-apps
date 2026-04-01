import { defineConfig, devices } from '@playwright/test';

const url = process.env.PLAYWRIGHT_TEST_BASE_URL || 'https://localhost:8443';
import * as dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config({ path: '.env' });

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
      reuseExistingServer: false,
      cwd: './',
      env: {
        API_URL: 'http://localhost:9443',
        DEBUGGER_OFF: 'true',
        DEVELOPMENT: 'false',
        PORT: '8443',
        SERVER_URL: 'https://openam-sdks.forgeblocks.com/am',
        WELLKNOWN_URL:
          'https://openam-sdks.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration',
        REALM_PATH: 'alpha',
        SCOPE: 'openid profile me.read email',
        TIMEOUT: '3000',
        WEB_OAUTH_CLIENT: 'CentralLoginOAuthClient-',
        REST_OAUTH_CLIENT: 'RestOAuthClient',
        REST_OAUTH_SECRET: process.env.REST_OAUTH_SECRET || '',
        INIT_PROTECT: 'bootstrap',
        PINGONE_ENV_ID: '02fb4743-189a-4bc7-9d6c-a919edfe6447',
      },
      ignoreHTTPSErrors: true,
    },
    {
      command: 'npm run start',
      url: 'http://localhost:9443/healthcheck',
      timeout: 120 * 1000,
      reuseExistingServer: false,
      cwd: '../todo-api/',
      env: {
        PORT: '9443',
        SERVER_TYPE: 'AIC',
        SERVER_URL: 'https://openam-sdks.forgeblocks.com/am',
        REALM_PATH: 'alpha',
        REST_OAUTH_CLIENT: 'RestOAuthClient',
        REST_OAUTH_SECRET: process.env.REST_OAUTH_SECRET || '',
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
