/*
 * ping-sample-web-react-journey
 *
 * todo.spec.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { test, expect } from '@playwright/test';
import { username, password } from './utils/demo-user';

const BASE_URL = 'https://localhost:8443/';

test.describe('React Journey - Todo', () => {
  const todoText = 'Test create todo' + Date.now();

  async function goToTodosPage(page) {
    // Log in and go to the todos page
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByLabel('User Name').fill(username);
    await page.getByLabel('Password').fill(password);
    await page.getByLabel('Password').press('Enter');
    await page.getByRole('link', { name: 'Todos', exact: true }).click();
    await page.waitForURL(BASE_URL + 'todos');

    // Wait for todos to load
    await expect(page.getByText('Verifying access')).toHaveCount(0);
    await expect(page.getByRole('heading', { name: 'Your Todos' })).toBeVisible();
    await expect(page.getByText('Collecting your todos')).toHaveCount(0);
  }

  test.beforeEach(async ({ page }) => {
    await goToTodosPage(page);
  });

  // Log in, create a todo, log out, then log back in and retrieve the todo
  // Note: To run this test, ensure REST_OAUTH_SECRET is set in your .env
  test('Get todos, pass', async ({ page }) => {
    // Create a todo
    await page.getByPlaceholder('What needs doing?').fill(todoText);
    await page.getByRole('button', { name: 'Create' }).click();
    await expect(page.getByText(todoText)).toBeVisible();

    // Log out
    await page.locator('#account_dropdown').click();
    await page.getByRole('link', { name: 'Sign Out' }).click();
    await page.waitForURL(BASE_URL + 'logout');
    await page.waitForURL(BASE_URL);
    await expect(page.getByText('Welcome back')).not.toBeVisible();
    await expect(page.getByText('Protect with Ping')).toBeVisible();

    // Log back in and find the created todo
    await goToTodosPage(page);
    await expect(page.getByText(todoText)).toBeVisible();
  });
});
