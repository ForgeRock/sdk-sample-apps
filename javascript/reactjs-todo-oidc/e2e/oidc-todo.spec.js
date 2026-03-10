/*
 * ping-sample-web-react-todo-oidc
 *
 * oidc-todo.spec.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';
import { username, password } from './utils/demo-user';

const BASE_URL = 'https://localhost:8443';

test.describe.serial('React - OIDC Todo', () => {
  test.setTimeout(120000);

  const createdTodoText = `Test create todo ${Date.now()}`;
  const editedTodoText = `${createdTodoText} edited`;

  async function loginAndGoToTodos(page, checkTodosApi = false) {
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await page.waitForURL(/openam-sdks\.forgeblocks\.com|\/mock\/authorize/, {
      timeout: 60000,
    });

    const usernameField = page.getByLabel('Username');
    const userNameField = page.getByLabel('User Name');
    if (
      await usernameField
        .first()
        .isVisible({ timeout: 3000 })
        .catch(() => false)
    ) {
      await usernameField.first().fill(username);
    } else {
      await userNameField.first().fill(username);
    }
    await page.getByLabel('Password').first().fill(password);
    await page
      .getByRole('button', { name: /Sign On|Next|Login/i })
      .first()
      .click();

    await page.waitForURL(`${BASE_URL}/**`, { timeout: 30000 });
    const todosResponsePromise = checkTodosApi
      ? page.waitForResponse(
          (response) => response.url().includes('/todos') && response.request().method() === 'GET',
          { timeout: 30000 },
        )
      : Promise.resolve(null);
    await page.getByRole('link', { name: 'Todos', exact: true }).click();
    await page.waitForURL(`${BASE_URL}/todos`);
    await expect(page.getByRole('heading', { name: 'Your Todos' })).toBeVisible();
    await expect(page.getByText('Collecting your todos')).toHaveCount(0);

    if (checkTodosApi) {
      const todosResponse = await todosResponsePromise;
      await expect(todosResponse.ok()).toBeTruthy();
      const payload = await todosResponse.json();
      await expect(Array.isArray(payload)).toBeTruthy();
    }
  }

  async function signOut(page) {
    await page.locator('#account_dropdown').click();
    await page.getByRole('link', { name: 'Sign Out' }).click();
    await page.waitForURL(`${BASE_URL}/logout`);
    await page.waitForURL(BASE_URL, { timeout: 30000 });

    // Ensure we're properly logged out by checking for Sign In button
    await expect(page.getByRole('link', { name: 'Sign In', exact: true })).toBeVisible({
      timeout: 10000,
    });
  }

  async function openTodoActions(page, todoText) {
    const todoRow = page.locator('li', { has: page.getByText(todoText, { exact: true }) }).first();
    await expect(todoRow).toBeVisible();
    await todoRow.locator('button[id^="todo_action_"]').click();
  }

  test('Fetch todos API response is valid, pass', async ({ page }) => {
    await loginAndGoToTodos(page, true);
    await expect(page.getByText('Unable to load todos:')).toHaveCount(0);
  });

  test('Create todo then sign out/in and fetch it again, pass', async ({ page }) => {
    await loginAndGoToTodos(page);
    await page.getByPlaceholder('What needs doing?').fill(createdTodoText);
    await page.getByRole('button', { name: 'Create' }).click();
    await expect(page.getByText(createdTodoText, { exact: true })).toBeVisible();

    await signOut(page);
    await loginAndGoToTodos(page);
    await expect(page.getByText(createdTodoText, { exact: true })).toBeVisible();
  });

  test('Edit todo then refresh and ensure changes persist, pass', async ({ page }) => {
    await loginAndGoToTodos(page);
    await expect(page.getByText(createdTodoText, { exact: true })).toBeVisible();

    await openTodoActions(page, createdTodoText);
    await page.getByRole('button', { name: 'Edit', exact: true }).click();
    await page.getByLabel('Update todo text').fill(editedTodoText);
    await page.getByRole('button', { name: 'Update Todo', exact: true }).click();
    await expect(page.getByText(editedTodoText, { exact: true })).toBeVisible();

    await page.reload();
    await page.waitForURL(`${BASE_URL}/todos`);
    await expect(page.getByText('Collecting your todos')).toHaveCount(0);
    await expect(page.getByText(editedTodoText, { exact: true })).toBeVisible();
  });

  test('Delete todo and ensure it is no longer listed, pass', async ({ page }) => {
    await loginAndGoToTodos(page);
    await expect(page.getByText(editedTodoText, { exact: true })).toBeVisible();

    await openTodoActions(page, editedTodoText);
    await page.getByRole('button', { name: 'Delete', exact: true }).click();
    await page.getByRole('button', { name: 'Delete Todo', exact: true }).click();

    await expect(page.getByText(editedTodoText, { exact: true })).toHaveCount(0);
  });
});
