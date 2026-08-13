import { test, expect } from '@playwright/test';
import { password, username, displayName } from './utils/demo-user';

/**
 * Verifies the widget's `middleware` array is forwarded to both the Journey and
 * OIDC clients, and that each middleware function only intercepts its own client.
 *
 * Each middleware function attaches an X-Session-ID correlation header to every
 * outgoing request (allowed by the AM CORS policy). The journey authenticate
 * request is a direct fetch in the main page context so Playwright can inspect
 * its headers directly.
 *
 * A full login is required to drive requests through both clients:
 *   - Journey client: JOURNEY_START at form load, JOURNEY_NEXT on submit
 *   - OIDC client: AUTHORIZE and TOKEN_EXCHANGE after the journey succeeds
 */

test('React - per-client middleware intercepts Journey and OIDC actions separately', async ({
  page,
}) => {
  const consoleLines = [];
  page.on('console', (msg) => consoleLines.push({ type: msg.type(), text: msg.text() }));

  // Set up the journey request waiter before navigating — fires on JOURNEY_START
  // when the Sign In form loads.
  const journeyRequest = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes('/authenticate'),
  );

  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  // JOURNEY_START: the authenticate fetch must carry the X-Session-ID header.
  const journeyReq = await journeyRequest;
  expect(
    journeyReq.headers()['x-session-id'],
    'journey middleware must attach X-Session-ID',
  ).toBeTruthy();

  await page.getByLabel('Username').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');

  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

  const logText = () => consoleLines.map((line) => line.text);

  // Journey middleware saw the Journey Client's requests.
  await expect
    .poll(() => logText().some((text) => text.includes('[journey-middleware] JOURNEY_START')))
    .toBe(true);
  expect(logText().some((text) => text.includes('[journey-middleware] JOURNEY_NEXT'))).toBe(true);

  // OIDC middleware saw the OIDC client's requests (token exchange after login).
  await expect
    .poll(() => logText().some((text) => text.includes('[oidc-middleware] TOKEN_EXCHANGE')))
    .toBe(true);
  expect(logText().some((text) => text.includes('[oidc-middleware] AUTHORIZE'))).toBe(true);

  // Each middleware only logs its own client's actions — no cross-labeling.
  expect(logText().some((text) => text.includes('[journey-middleware] TOKEN_EXCHANGE'))).toBe(
    false,
  );
  expect(logText().some((text) => text.includes('[oidc-middleware] JOURNEY_START'))).toBe(false);
});
