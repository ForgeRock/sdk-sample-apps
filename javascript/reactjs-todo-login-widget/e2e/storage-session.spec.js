import { test, expect } from '@playwright/test';
import { password, username, displayName } from './utils/demo-user';

/**
 * Verifies the widget's top-level `storage` config places OAuth tokens in
 * sessionStorage. The sample app hardcodes `storage: { type: 'sessionStorage',
 * name: WEB_OAUTH_CLIENT }` in configure(), so tokens must land in
 * sessionStorage and never in localStorage.
 *
 * The SDK default prefix ('pic-') is used, keeping the expected key consistent
 * with the other specs' token-key assumptions.
 */

const TOKEN_KEY_PREFIX = 'pic-';

test('React - storage type sessionStorage stores tokens in sessionStorage only', async ({
  page,
}) => {
  await page.goto('https://localhost:8443/');
  await page.evaluate(() => {
    window.localStorage.clear();
    window.sessionStorage.clear();
  });

  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await page.getByLabel('Username').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');

  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

  const tokenKeys = await page.evaluate((prefix) => {
    const inStore = (storage) => Object.keys(storage).filter((key) => key.startsWith(prefix));
    return {
      session: inStore(window.sessionStorage),
      local: inStore(window.localStorage),
    };
  }, TOKEN_KEY_PREFIX);

  expect(tokenKeys.session.length, 'expected OAuth token in sessionStorage').toBeGreaterThan(0);
  expect(tokenKeys.local, 'no OAuth token should be written to localStorage').toHaveLength(0);
});
