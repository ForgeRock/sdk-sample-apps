/*
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';

// Uses the 356a254c tenant (port 8444) which has passwordPolicy configured on the
// registration password field, producing a ValidatedPasswordCollector.
const BASE_URL = 'http://localhost:8444';
const ACR_VALUE = '769eecb92f8e66f88005a85e8b939a01';

async function navigateToRegistrationForm(page) {
  await page.goto(`${BASE_URL}/login?acrValue=${ACR_VALUE}`);
  await expect(page.getByRole('heading', { name: 'Select Test Form' })).toBeVisible();
  await page.getByRole('link', { name: 'USER_REGISTRATION' }).click();
  await expect(page.getByRole('heading', { name: 'Example - Registration 1' })).toBeVisible({
    timeout: 10000,
  });
}

// These tests require the 356a254c PingOne tenant on port 8444.
// They are skipped in CI where only the 02fb4743 tenant (port 8443) is available.
// Run locally with both webServers active: npm run e2e -- --grep ValidatedPasswordCollector
test.describe('React - DaVinci ValidatedPasswordCollector', () => {
  test.skip(!!process.env.CI, 'Requires 356a254c tenant on port 8444 (not available in CI)');

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
