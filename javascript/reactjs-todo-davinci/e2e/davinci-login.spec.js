/*
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';
import { username, password } from './utils/demo-user';

const BASE_URL = 'http://localhost:8443';

test.describe('React - DaVinci Login', () => {
  test('Login with valid credentials, pass', async ({ page }) => {
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByLabel('Username').fill(username);
    await page.getByLabel('Password').fill(password);
    await page.getByRole('button', { name: 'Sign On' }).click();
    await expect(page.getByText('Welcome back, JS DaVinci Sample Apps E2E!')).toBeVisible();
    await expect(page.getByText('Protect with Ping')).toBeVisible();
  });
  test('Login with invalid credentials, fail', async ({ page }) => {
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByLabel('Username').fill('invalidUsername');
    await page.getByLabel('Password').fill('invalidPassword');
    await page.getByRole('button', { name: 'Sign On' }).click();
    await expect(
      page.getByText(/Invalid username and\/or password|Validation Error/),
    ).toBeVisible();
  });
});
