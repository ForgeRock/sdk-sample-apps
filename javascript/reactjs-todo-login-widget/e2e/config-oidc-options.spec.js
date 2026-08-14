import { test, expect } from '@playwright/test';
import { password, username } from './utils/demo-user';

/**
 * Verifies the OIDC-client passthrough options reach the authorize request.
 *
 * `loginHint`, `acrValues`, and `query` are forwarded by the widget onto the
 * OIDC authorize call. After login the sample app calls
 * user.tokens().get({ backgroundRenew: true }) which fires the authorize request
 * carrying these params — we intercept that to assert the config was forwarded.
 *
 * Expected values match what is hardcoded in index.js:
 *   loginHint: 'demo@example.com', acrValues: 'urn:acr:example',
 *   query: { ui_locales: 'en-US' }
 */

const EXPECTED_LOGIN_HINT = 'demo@example.com';
const EXPECTED_ACR_VALUES = 'urn:acr:example';
const EXPECTED_UI_LOCALES = 'en-US';

test('React - loginHint, acrValues and query are forwarded to the authorize request', async ({
  page,
}) => {
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

  expect(params.get('login_hint')).toBe(EXPECTED_LOGIN_HINT);
  expect(params.get('acr_values')).toBe(EXPECTED_ACR_VALUES);
  expect(params.get('ui_locales')).toBe(EXPECTED_UI_LOCALES);
});
