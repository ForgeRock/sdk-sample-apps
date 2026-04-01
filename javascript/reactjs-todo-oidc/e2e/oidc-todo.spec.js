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
import { asyncEvents } from './utils/async-events';
import { username, password } from './utils/demo-user';

const BASE_URL = 'https://localhost:8443';

test.describe.serial('React - OIDC Todo', () => {
  const createdTodoText = `Test create todo ${Date.now()}`;
  const editedTodoText = `${createdTodoText} edited`;

  async function loginAndGoToTodos(page) {
    const { clickLink } = asyncEvents(page);

    // Log in and go to the todos page
    await page.goto(BASE_URL);

    await clickLink('Sign In', 'https://openam-sdks.forgeblocks.com/');
    await page.getByLabel('User Name').fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);
    await page.getByRole('button', { name: 'Next' }).click();

    await page.getByRole('link', { name: 'Todos', exact: true }).click();
    await page.waitForURL(BASE_URL + '/todos');

    // Wait for todos to load
    await expect(page.getByText('Verifying access')).toHaveCount(0);
    await expect(page.getByRole('heading', { name: 'Your Todos' })).toBeVisible();
    await expect(page.getByText('Collecting your todos')).toHaveCount(0);
  }

  async function signOut(page) {
    await page.locator('#account_dropdown').click();
    await page.getByRole('link', { name: 'Sign Out' }).click();
    await page.waitForURL(`${BASE_URL}/logout`);
    await page.waitForURL(BASE_URL);

    // Ensure we're properly logged out by checking for Sign In button
    await expect(page.getByText('Welcome back')).not.toBeVisible();
    await expect(page.getByRole('link', { name: 'Sign In', exact: true })).toBeVisible();
  }

  async function openTodoActions(page, todoText) {
    const todoRow = page.locator('li', { has: page.getByText(todoText, { exact: true }) }).first();
    await expect(todoRow).toBeVisible();
    await todoRow.locator('button[id^="todo_action_"]').click();
  }

  test('Fetch todos API response is valid, pass', async ({ page }) => {
    await loginAndGoToTodos(page);
    await expect(page.getByRole('heading', { name: 'Your Todos' })).toBeVisible();
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

  test.skip('Edit todo then refresh and ensure changes persist, pass', async ({ page }) => {
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

  test.skip('Delete todo and ensure it is no longer listed, pass', async ({ page }) => {
    await loginAndGoToTodos(page);
    await expect(page.getByText(editedTodoText, { exact: true })).toBeVisible();

    await openTodoActions(page, editedTodoText);
    await page.getByRole('button', { name: 'Delete', exact: true }).click();
    await page.getByRole('button', { name: 'Delete Todo', exact: true }).click();

    await expect(page.getByText(editedTodoText, { exact: true })).toHaveCount(0);
  });
});
