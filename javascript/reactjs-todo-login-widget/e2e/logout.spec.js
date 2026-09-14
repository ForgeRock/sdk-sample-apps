import { test, expect } from '@playwright/test';
import { password, username, displayName } from './utils/demo-user';

/**
 * Verifies the full sign-out path. Choosing "Sign Out" from the account menu
 * drives the widget's `user.logout()`, which:
 *   1. terminates the AM session   — POST /sessions/?_action=logout
 *   2. ends the OIDC session        — GET  /connect/endSession (id_token_hint)
 *   3. revokes the access token     — POST /token/revoke
 *
 * The OIDC steps only fire when an id_token exists, which requires the `openid`
 * scope (set in the shared webServer env). We assert all three requests go out —
 * asserting on the requests rather than a logged-out UI, because this sample app
 * signs out with a full-page reload and its boot-time silent renewal then
 * re-authenticates from the surviving AM SSO cookie.
 */

test('React - signing out terminates the AM session and revokes OIDC tokens', async ({ page }) => {
  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await page.getByLabel('Username').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');

  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

  // Set up waiters before clicking so none of the logout requests are missed.
  const sessionTerminate = page.waitForRequest(
    (request) =>
      request.method() === 'POST' && request.url().includes('/sessions/?_action=logout'),
  );
  const endSession = page.waitForRequest((request) =>
    request.url().includes('/connect/endSession'),
  );
  const revoke = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes('/token/revoke'),
  );

  await page.locator('#account_dropdown').click();
  await page.getByRole('link', { name: 'Sign Out' }).click();

  await sessionTerminate;

  // The OIDC end_session request carries the id_token_hint.
  const endSessionUrl = new URL((await endSession).url());
  expect(endSessionUrl.searchParams.get('id_token_hint')).toBeTruthy();

  await revoke;
});
