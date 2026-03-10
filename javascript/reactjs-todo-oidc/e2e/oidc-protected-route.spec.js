/*
 * ping-sample-web-react-todo-oidc
 *
 * oidc-protected-route.spec.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';

test.describe('React - OIDC Protected Route', () => {
  test('Unauthenticated user navigating to /todos is redirected to /login, pass', async ({
    page,
  }) => {
    await page.goto('/todos');
    await page.waitForURL(/\/(login|mock\/authorize)|openam-sdks\.forgeblocks\.com/);
    await expect(page).toHaveURL(/\/(login|mock\/authorize)|openam-sdks\.forgeblocks\.com/);
  });
});
