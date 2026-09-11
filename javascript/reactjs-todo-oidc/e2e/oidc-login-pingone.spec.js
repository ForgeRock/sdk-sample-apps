/*
 * ping-sample-web-react-todo-oidc
 *
 * oidc-login-pingone.spec.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';
import { p1DisplayName, p1Password, p1Username } from './utils/demo-user';

const BASE_URL = 'https://localhost:8444';
const CLIENT_ID = '00e62f85-3d49-4046-b860-15aefdebbb0d';

test.describe('React - PingOne OIDC', () => {
  test('Starts centralized login flow, pass', async ({ page }) => {
    let authorizeUrl;
    await page.goto(BASE_URL);

    page.on('request', (request) => {
      const method = request.method();
      const requestUrl = request.url();

      if (method === 'GET' && requestUrl.includes('as/authorize')) {
        authorizeUrl = new URL(requestUrl);
      }
    });

    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await expect(page.getByRole('textbox', { name: 'Username' })).toBeVisible();
    await expect(page.getByRole('textbox', { name: 'Password' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Sign On' })).toBeVisible();

    expect(authorizeUrl.searchParams.get('client_id')).toBe(CLIENT_ID);
    expect(authorizeUrl.searchParams.get('redirect_uri')).toContain(`${BASE_URL}/callback.html`);
    expect(authorizeUrl.searchParams.get('state')).toBeTruthy();
    expect(authorizeUrl.searchParams.get('code_challenge')).toBeTruthy();
  });

  test('Login with valid credentials, pass', async ({ page }) => {
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await page.getByRole('textbox', { name: 'Username' }).fill(p1Username);
    await page.getByRole('textbox', { name: 'Password' }).fill(p1Password);
    await page.getByRole('button', { name: 'Sign On' }).click();

    await expect(page.getByText(`Welcome back, ${p1DisplayName}!`)).toBeVisible();
    await expect(page.getByRole('link', { name: 'Sign In', exact: true })).not.toBeVisible();
    await expect(page.getByText('Protect with Ping')).toBeVisible();
  });

  test('Login with invalid credentials, fail', async ({ page }) => {
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await page.getByRole('textbox', { name: 'Username' }).fill('invalidUsername');
    await page.getByRole('textbox', { name: 'Password' }).fill('invalidPassword');
    await page.getByRole('button', { name: 'Sign On' }).click();

    await expect(
      page.getByText(
        /Invalid username and\/or password|Incorrect username or password. Please try again.|Validation Error|identifier must be a uuid/,
      ),
    ).toBeVisible({ timeout: 10000 });
  });

  test('Login then logout, pass', async ({ page }) => {
    // Login
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await page.getByRole('textbox', { name: 'Username' }).fill(p1Username);
    await page.getByRole('textbox', { name: 'Password' }).fill(p1Password);
    await page.getByRole('button', { name: 'Sign On' }).click();

    await expect(page.getByText(`Welcome back, ${p1DisplayName}!`)).toBeVisible();
    await expect(page.getByRole('link', { name: 'Sign In', exact: true })).not.toBeVisible();
    await expect(page.getByText('Protect with Ping')).toBeVisible();

    // Logout
    await page.locator('#account_dropdown').click();
    await page.getByRole('link', { name: 'Sign Out' }).click();

    await page.waitForURL(BASE_URL + '/logout');
    await page.waitForURL(BASE_URL);

    await expect(page.getByText('Welcome back')).not.toBeVisible();
    await expect(page.getByText('Protect with Ping')).toBeVisible();
    await expect(page.getByRole('link', { name: 'Sign In', exact: true })).toBeVisible();
  });
});
