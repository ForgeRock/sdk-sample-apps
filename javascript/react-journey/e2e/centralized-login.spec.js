/*
 * ping-sample-web-react-journey
 *
 * centralized-login.spec.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { test, expect } from '@playwright/test';
import { password, username } from './utils/demo-user';

test('React Journey - Login with Centralized Login', async ({ page }) => {
  await page.goto('https://localhost:8443/?centralLogin=true');

  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await page.getByLabel('User Name').fill(username);
  await page.getByLabel('Password').first().fill(password);
  await page.getByRole('button', { name: 'Next' }).click();

  // TODO: It should be fixed evantually. This line has been added as after succesfully logging in, the server
  // stops responding and it is necessary to reload the page in order for it to work. FYI: Only happens when running
  // e2e tests.
  await page.waitForTimeout(3000);

  await page.reload();

  await expect(page.getByText('Welcome back')).toBeVisible();
});
