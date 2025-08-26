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

test.describe('Logout tests', () => {
  test('PingOne login then logout', async ({ page }) => {
    const { navigate, clickButton } = asyncEvents(page);
    await navigate('http://localhost:8443/');
    expect(page.url()).toBe('http://localhost:8443/');

    let endSessionStatus, revokeStatus;
    page.on('response', (response) => {
      const responseUrl = response.url();
      const status = response.ok();

      if (responseUrl.includes('/as/idpSignoff?id_token_hint')) {
        endSessionStatus = status;
      }
      if (responseUrl.includes('/revoke')) {
        revokeStatus = status;
      }
    });

    await clickButton('Login', 'https://apps.pingone.ca/');

    await page.getByLabel('Username').fill(pingOneUsername);
    await page.getByRole('textbox', { name: 'Password' }).fill(pingOnePassword);
    await page.getByRole('button', { name: 'Sign On' }).click();

    await page.waitForURL('http://localhost:8443/**');
    expect(page.url()).toContain('code');
    expect(page.url()).toContain('state');
    await expect(page.getByRole('button', { name: 'Login' })).toBeHidden();

    await page.getByRole('button', { name: 'Sign Out' }).click();
    await expect(page.getByRole('button', { name: 'Login' })).toBeVisible();

    expect(endSessionStatus).toBeTruthy();
    expect(revokeStatus).toBeTruthy();
  });

  test('PingAM login then logout', async ({ page }) => {
    const { navigate, clickButton } = asyncEvents(page);
    await navigate('http://localhost:8444/');
    expect(page.url()).toBe('http://localhost:8444/');

    let endSessionStatus, revokeStatus;
    page.on('response', (response) => {
      const responseUrl = response.url();
      const status = response.ok();

      if (responseUrl.includes('/endSession?id_token_hint')) {
        endSessionStatus = status;
      }
      if (responseUrl.includes('/revoke')) {
        revokeStatus = status;
      }
    });

    await clickButton('Login', 'https://openam-sdks.forgeblocks.com/');

    await page.getByLabel('User Name').fill(pingAmUsername);
    await page.getByRole('textbox', { name: 'Password' }).fill(pingAmPassword);
    await page.getByRole('button', { name: 'Next' }).click();

    await page.waitForURL('http://localhost:8444/**');
    expect(page.url()).toContain('code');
    expect(page.url()).toContain('state');
    await expect(page.getByRole('button', { name: 'Login' })).toBeHidden();

    await page.getByRole('button', { name: 'Sign Out' }).click();
    await expect(page.getByRole('button', { name: 'Login' })).toBeVisible();

    expect(endSessionStatus).toBeTruthy();
    expect(revokeStatus).toBeTruthy();
  });

  test('logout without tokens should error', async ({ page }) => {
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
    await expect(page.getByRole('button', { name: 'Login' })).toBeHidden();

    await page.evaluate(() => window.localStorage.clear());

    await page.getByRole('button', { name: 'Sign Out' }).click();
    await expect(page.locator('#Error span')).toContainText('Token_Error');
  });
});
