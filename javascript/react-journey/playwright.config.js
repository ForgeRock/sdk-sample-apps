/*
 * ping-sample-web-react-journey
 *
 * playwright.config.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { defineConfig, devices } from '@playwright/test';
import * as dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config({ path: '.env' });

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
      command: 'npm run start',
      url,
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
      env: {
        VITE_API_URL: 'http://localhost:9443',
        VITE_DEBUGGER_OFF: 'true',
        VITE_DEVELOPMENT: 'false',
        VITE_JOURNEY_LOGIN: 'Login',
        VITE_JOURNEY_REGISTER: 'Registration',
        VITE_PORT: '8443',
        VITE_WELLKNOWN_URL:
          'https://openam-sdks.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration',
        VITE_SCOPE: 'profile openid email',
        VITE_WEB_OAUTH_CLIENT: 'WebOAuthClient',
        VITE_REALM_PATH: 'alpha',
        VITE_CENTRALIZED_LOGIN: 'false',
        VITE_PINGONE_ENV_ID: '02fb4743-189a-4bc7-9d6c-a919edfe6447',
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
