import { defineConfig, devices } from '@playwright/test';
import * as dotenv from 'dotenv';
import testConfigPingam from './config.test.pingam.json';
import testConfigPingone from './config.test.pingone.json';

const url = process.env.PLAYWRIGHT_TEST_BASE_URL || 'https://localhost:8443';

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
        SERVER: 'PINGAM',
        REST_OAUTH_CLIENT: 'RestOAuthClient',
        REST_OAUTH_SECRET: process.env.REST_OAUTH_SECRET || '',
        SDK_CONFIG: JSON.stringify(testConfigPingam),
      },
      ignoreHTTPSErrors: true,
    },
    {
      command: 'npm run start',
      url: 'https://localhost:8444',
      timeout: 120 * 1000,
      reuseExistingServer: false,
      cwd: './',
      env: {
        API_URL: 'http://localhost:9443',
        DEBUGGER_OFF: 'true',
        DEVELOPMENT: 'false',
        PORT: '8444',
        SERVER: 'PINGONE',
        REST_OAUTH_CLIENT: '724ec718-c41c-4d51-98b0-84a583f450f9',
        SDK_CONFIG: JSON.stringify(testConfigPingone),
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
