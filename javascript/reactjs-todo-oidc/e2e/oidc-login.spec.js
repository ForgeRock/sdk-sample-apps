/*
 * ping-sample-web-react-todo-oidc
 *
 * oidc-login.spec.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';
import { password, username } from './utils/demo-user';

const BASE_URL = 'https://localhost:8443';

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function getConfiguredOidcHost() {
  const configuredWellKnownUrl = test.info().config.metadata?.oidcWellKnownUrl;
  if (typeof configuredWellKnownUrl !== 'string') {
    return null;
  }

  return new URL(configuredWellKnownUrl).hostname;
}

async function submitLoginForm(page, testUsername = username, testPassword = password) {
  const usernameField = page.getByLabel('Username');
  const userNameField = page.getByLabel('User Name');

  if (
    await usernameField
      .first()
      .isVisible({ timeout: 3000 })
      .catch(() => false)
  ) {
    await usernameField.first().fill(testUsername);
  } else {
    await userNameField.first().fill(testUsername);
  }

  await page.getByLabel('Password').first().fill(testPassword);
  await page
    .getByRole('button', { name: /Next|Sign On|Login/i })
    .first()
    .click();
}

async function openCentralizedLogin(page) {
  await page.context().clearCookies();
  await page.goto(BASE_URL);
  await page.evaluate(() => window.localStorage.clear());
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();
  await page.waitForURL(/openam-sdks\.forgeblocks\.com|\/mock\/authorize/, { timeout: 60000 });
}

test('React OIDC - home page loads with sign-in CTA', async ({ page }) => {
  await page.goto('/');

  await expect(page.getByRole('link', { name: 'Sign In', exact: true })).toBeVisible();
});

test('React OIDC - sign in starts centralized login flow', async ({ page }) => {
  await page.goto('/');

  const configuredOidcHost = getConfiguredOidcHost();
  const redirectPattern = configuredOidcHost
    ? new RegExp(`${escapeRegExp(configuredOidcHost)}|\\/mock\\/authorize`)
    : /openam-sdks\.forgeblocks\.com|\/mock\/authorize/;

  await page.getByRole('link', { name: 'Sign In', exact: true }).click();
  await page.waitForURL(redirectPattern);

  const authorizeUrl = new URL(page.url());
  if (authorizeUrl.pathname.includes('/mock/authorize')) {
    expect(authorizeUrl.searchParams.get('client_id')).toBeTruthy();
    expect(authorizeUrl.searchParams.get('redirect_uri')).toContain('/callback.html');
    expect(authorizeUrl.searchParams.get('state')).toBeTruthy();
  } else {
    expect(authorizeUrl.hostname).toBe(configuredOidcHost || 'openam-sdks.forgeblocks.com');
  }
});

test('React OIDC - real sign in flow with valid credentials', async ({ page }) => {
  test.setTimeout(120000);

  await openCentralizedLogin(page);
  await submitLoginForm(page);
  await page.waitForURL(`${BASE_URL}/**`, { timeout: 60000 });
  await expect(page.locator('#account_dropdown')).toBeVisible();
  await expect(page.getByRole('link', { name: 'Sign In', exact: true })).toHaveCount(0);

  await page.getByRole('link', { name: 'Todos', exact: true }).click();
  await page.waitForURL(`${BASE_URL}/todos`);
  await expect(page.getByRole('heading', { name: 'Your Todos' })).toBeVisible();
});

test('React OIDC - login then logout, pass', async ({ page }) => {
  test.setTimeout(120000);

  await openCentralizedLogin(page);
  await submitLoginForm(page);
  await page.waitForURL(`${BASE_URL}/**`, { timeout: 60000 });
  await expect(page.locator('#account_dropdown')).toBeVisible();

  await page.locator('#account_dropdown').click();
  await page.getByRole('link', { name: 'Sign Out' }).click();
  await page.waitForURL(`${BASE_URL}/logout`);
  await page.waitForURL(`${BASE_URL}/`, { timeout: 60000 });
  await expect(page.getByRole('link', { name: 'Sign In', exact: true })).toBeVisible();
  await expect(page.locator('#account_dropdown')).toHaveCount(0);
});

test('React OIDC - real sign in flow with invalid credentials', async ({ page }) => {
  test.setTimeout(120000);

  await openCentralizedLogin(page);
  await submitLoginForm(page, 'invalidUsername', 'invalidPassword');

  await expect(
    page.getByText(
      /Invalid username and\/or password|Validation Error|Login failure|Authentication failed/i,
    ),
  ).toBeVisible({ timeout: 60000 });
  await expect(page.locator('#account_dropdown')).toHaveCount(0);
});

test('React OIDC - login error query shows failure message', async ({ page }) => {
  await page.goto('/login?error=access_denied');

  await expect(page.getByText('Sign in failed. Please try again.')).toBeVisible();
});

test('React OIDC - login error page can navigate back home', async ({ page }) => {
  await page.goto('/login?error=access_denied');
  await page.getByRole('link', { name: 'Home' }).click();

  await expect(page).toHaveURL('/');
  await expect(page.getByRole('link', { name: 'Sign In', exact: true })).toBeVisible();
});
