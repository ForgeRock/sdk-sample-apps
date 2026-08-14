import { test, expect } from '@playwright/test';
import { password, username } from './utils/demo-user';

/**
 * Verifies that logger.level from LOG_LEVEL is forwarded to the SDK.
 *
 * LOG_LEVEL is set to 'debug' in the playwright webServer env. The sample app
 * passes `logger: { level: process.env.LOG_LEVEL || 'error' }` to configure(). When the level reaches
 * the SDK, it emits console.debug calls for its internal operations.
 *
 * After login, the sample app calls user.tokens().get({ backgroundRenew: true })
 * which fires an authorize request. We wait for that so the SDK has had a chance
 * to emit its debug output before asserting.
 */

test('React - logger.level is forwarded to the SDK', async ({ page }) => {
  const consoleLines = [];
  page.on('console', (msg) => consoleLines.push({ type: msg.type(), text: msg.text() }));

  await page.goto('https://localhost:8443/');
  await page.evaluate(() => {
    window.localStorage.clear();
    window.sessionStorage.clear();
  });
  await page.goto('https://localhost:8443/');

  const authorizeRequest = page.waitForRequest((request) => request.url().includes('/authorize?'));
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();
  await page.getByLabel('Username').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');
  await authorizeRequest;

  expect(consoleLines.some((line) => line.type === 'debug')).toBe(true);
});
