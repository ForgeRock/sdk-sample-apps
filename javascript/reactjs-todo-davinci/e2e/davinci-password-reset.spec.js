/*
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';
import { username } from './utils/demo-user';

const BASE_URL = 'http://localhost:8443';

test.describe('React - DaVinci Password Reset', () => {
  test('Check password reset flow, pass', async ({ page }) => {
    // Check for password reset form
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByRole('link', { name: 'Having trouble signing on?' }).click();
    await expect(page.getByRole('heading', { name: 'Forgot password form' })).toBeVisible();
    await page.getByLabel('Username').fill(username);
    await page.getByRole('button', { name: 'Submit' }).click();

    // Check for password reset verification form
    await expect(
      page.getByRole('heading', { name: 'Forgot password recovery code form' }),
    ).toBeVisible();
    await expect(page.getByLabel('Recovery Code')).toBeVisible();
    await expect(page.getByLabel('New Password')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Submit' })).toBeVisible();
  });
});
