/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { test, expect } from '@playwright/test';
import { asyncEvents } from './utils/async-events';
import {
  pingAmUsername,
  pingAmPassword,
  pingOneUsername,
  pingOnePassword,
} from './utils/demo-users';

test.describe('Login Tests', () => {
  test('PingAM redirect login with valid credentials', async ({ page }) => {
    const { navigate, clickButton } = asyncEvents(page);
    await navigate('http://localhost:8444/');
    expect(page.url()).toBe('http://localhost:8444/');

    await clickButton('Login', 'https://openam-sdks.forgeblocks.com/');

    await page.getByLabel('User Name').fill(pingAmUsername);
    await page.getByRole('textbox', { name: 'Password' }).fill(pingAmPassword);
    await page.getByRole('button', { name: 'Next' }).click();

    await page.waitForURL('http://localhost:8444/**');
    expect(page.url()).toContain('code');
    expect(page.url()).toContain('state');
    await expect(page.locator('#User pre')).toContainText('Sdk User');
    await expect(page.locator('#User pre')).toContainText('sdkuser@example.com');
  });

  test('PingOne redirect login with valid credentials', async ({ page }) => {
    const { navigate, clickButton } = asyncEvents(page);
    await navigate('http://localhost:8443/');
    expect(page.url()).toBe('http://localhost:8443/');

    await clickButton('Login', 'https://apps.pingone.ca/');

    await page.getByLabel('Username').fill(pingOneUsername);
    await page.getByRole('textbox', { name: 'Password' }).fill(pingOnePassword);
    await page.getByRole('button', { name: 'Sign On' }).click();

    await page.waitForURL('http://localhost:8443/**');
    expect(page.url()).toContain('code');
    expect(page.url()).toContain('state');
    await expect(page.locator('#User pre')).toContainText('demouser');
    await expect(page.locator('#User pre')).toContainText('demouser@user.com');
  });

  test('login with invalid state fails with error', async ({ page }) => {
    const { navigate } = asyncEvents(page);
    await navigate('http://localhost:8443/?code=12345&state=abcxyz');
    expect(page.url()).toBe('http://localhost:8443/?code=12345&state=abcxyz');

    await expect(page.locator('#Error span')).toContainText('State mismatch');
  });
});
