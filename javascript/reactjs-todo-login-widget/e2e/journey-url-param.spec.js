/*
 * forgerock-sample-web-react
 *
 * journey-url-param.spec.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { test, expect } from '@playwright/test';

test('React - Login widget opens correct journey from URL param', async ({ page }) => {
  await page.goto('https://localhost:8443/?journey=Registration');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  // Registration journey has these fields; Login journey does not
  await expect(page.getByLabel('First name')).toBeVisible();
  await expect(page.getByLabel('Last name')).toBeVisible();
  await expect(page.getByLabel('Email address')).toBeVisible();
});
