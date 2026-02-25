/*
 * ping-sample-web-react-journey
 *
 * social-login.spec.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { test, expect } from '@playwright/test';

test('React Journey - Login with social login', async ({ page }) => {
  await page.goto('https://localhost:8443/?journey=TEST_LoginWithSocial');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await expect(page.getByLabel('User Name')).toBeEmpty();
  await expect(page.getByLabel('User Name')).toBeVisible();
  await expect(page.getByLabel('Password')).toBeEmpty();
  await expect(page.getByLabel('Password')).toBeVisible();

  await expect(page.getByRole('button', { name: 'Sign in with Apple' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Sign in with Facebook' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Sign in with Google' })).toBeVisible();
});
