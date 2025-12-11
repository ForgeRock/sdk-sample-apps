/*
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';
import { v4 as uuid } from 'uuid';

const BASE_URL = 'http://localhost:8443';
const randomUUID = uuid();

test.describe('React - DaVinci Register New User', () => {
  test('Check register user flow, pass', async ({ page }) => {
    // Check for reister user form
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByRole('link', { name: 'No account? Register now!' }).click();
    await page.getByRole('heading', { name: 'Registration form' }).click();
    await page.getByLabel('First Name').fill('Test');
    await page.getByLabel('Last Name').fill(`Test-${randomUUID}`);
    await page.getByLabel('Email').fill(`test-${randomUUID}@user.com`);
    await page.getByLabel('Password').fill('Demo_12345!');
    await page.getByRole('button', { name: 'Save' }).click();

    // Check for verification form
    await expect(page.getByRole('heading', { name: 'Prompt for verification code' })).toBeVisible();
    await expect(page.getByLabel('Verification Code')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Verify' })).toBeVisible();
  });
});
