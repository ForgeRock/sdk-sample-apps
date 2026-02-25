/*
 * ping-sample-web-react-journey
 *
 * protect.spec.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { test, expect, describe } from '@playwright/test';
import { displayName, password, username } from './utils/demo-user';

describe('React Journey - Login with Protect', () => {
  test('should succeed when initialized by callback', async ({ page }) => {
    const logs = [];
    page.on('console', async (msg) => {
      logs.push(msg.text());
      return Promise.resolve(true);
    });

    await page.goto('https://localhost:8443?journey=TEST_Protect&initProtect=journey');
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await page.getByLabel('User Name').fill(username);
    await page.getByLabel('Password').fill(password);
    await page.getByLabel('Password').press('Enter');

    await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

    await expect(logs.includes('Protect initialized by callback for data collection')).toBeTruthy();
    await expect(logs.includes('Data set on Protect evaluation callback')).toBeTruthy();

    page.removeListener('console', (msg) => console.log(msg.text()));
  });

  test('should succeed when initialized at bootstrap', async ({ page }) => {
    const logs = [];
    page.on('console', async (msg) => {
      logs.push(msg.text());
      return Promise.resolve(true);
    });

    await page.goto('https://localhost:8443?journey=TEST_Protect&initProtect=bootstrap');
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await page.getByLabel('User Name').fill(username);
    await page.getByLabel('Password').fill(password);
    await page.getByLabel('Password').press('Enter');

    await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

    await expect(
      logs.includes('Protect initialized at bootstrap for data collection'),
    ).toBeTruthy();
    await expect(logs.includes('Data set on Protect evaluation callback')).toBeTruthy();

    page.removeListener('console', (msg) => console.log(msg.text()));
  });
});
