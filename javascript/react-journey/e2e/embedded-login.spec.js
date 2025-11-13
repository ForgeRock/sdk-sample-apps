/*
 * ping-sample-web-react-journey
 *
 * embedded-login.spec.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { test, expect } from '@playwright/test';
import { password, username, displayName } from './utils/demo-user';

test('React Journey - Login with embedded login', async ({ page }) => {
  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  // failed login
  await page.getByLabel('User Name').fill('notauser');
  await page.getByLabel('Password').fill('notapassword');

  await page.getByLabel('Password').press('Enter');
  await expect(page.getByText('Login failure')).toBeVisible();

  // successful login
  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await page.getByLabel('User Name').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');

  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();
});
