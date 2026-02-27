/*
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';

const BASE_URL = 'http://localhost:8443';

test.describe('React - DaVinci Protected Route', () => {
  test('Unauthenticated user navigating to /todos is redirected to /login, pass', async ({
    page,
  }) => {
    await page.goto(`${BASE_URL}/todos`);
    await page.waitForURL(`${BASE_URL}/login**`);
    await expect(page).toHaveURL(new RegExp(`${BASE_URL}/login`));
  });
});
