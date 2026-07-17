/*
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';

const BASE_URL = 'http://localhost:8443';
const ACR_VALUE = '533a7ff229ca6395afd9dd6deb699944';

async function navigateToRegistrationForm(page) {
  await page.goto(`${BASE_URL}/login?acrValue=${ACR_VALUE}`);
  await expect(page.getByRole('heading', { name: 'Select Test Form' })).toBeVisible();
  await page.getByRole('link', { name: 'USER_REGISTRATION' }).click();
  await expect(page.getByRole('heading', { name: 'Example - Registration' })).toBeVisible({
    timeout: 10000,
  });
}

test.describe('React - DaVinci ValidatedPasswordCollector', () => {
  test('shows password requirements list', async ({ page }) => {
    await navigateToRegistrationForm(page);
    await expect(page.locator('ul.password-requirements')).toBeVisible();
    await expect(page.locator('ul.password-requirements li').first()).toBeVisible();
  });

  test('shows inline validation errors for a password that violates policy, then clears them', async ({
    page,
  }) => {
    await navigateToRegistrationForm(page);
    const passwordInput = page.getByLabel('Password');
    await passwordInput.fill('a');
    await expect(page.locator('[class$="-error"] li').first()).toBeVisible();

    await passwordInput.fill('Demo_12345!');
    await expect(page.locator('[class$="-error"] li')).toHaveCount(0);
  });
});
