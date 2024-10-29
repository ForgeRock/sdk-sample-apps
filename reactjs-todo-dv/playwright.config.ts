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
      command: 'npm run start',
      url,
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
      // cwd: '../',
      env: {
        API_URL: 'http://localhost:9443',
        DEBUGGER_OFF: 'true',
        DEVELOPMENT: 'false',
        PORT: '8443'

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
  /*{
      name: 'firefox',
      grepInvert: /WebAuthN/i,
      use: { ...devices['Desktop Firefox'] },
    },*/
  ],
});
