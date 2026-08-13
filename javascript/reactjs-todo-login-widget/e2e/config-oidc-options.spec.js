import { test, expect } from '@playwright/test';
import { password, username } from './utils/demo-user';

/**
 * Verifies the OIDC-client passthrough options are absent from the authorize
 * request when they are omitted from the app's config.
 *
 * index.js ships `loginHint`, `acrValues`, and `query` commented out as
 * optional examples. With them omitted, the widget must not add the
 * corresponding params to the authorize request. After login the sample app
 * calls user.tokens().get() which fires the authorize request — we intercept
 * that to assert the params are absent.
 */

test('React - loginHint, acrValues and query are omitted when not configured', async ({ page }) => {
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

  const params = new URL((await authorizeRequest).url()).searchParams;

  expect(params.get('login_hint')).toBeNull();
  expect(params.get('acr_values')).toBeNull();
  expect(params.get('ui_locales')).toBeNull();
});
