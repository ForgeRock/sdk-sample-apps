import { test, expect } from '@playwright/test';
import { password, username, displayName } from './utils/demo-user';

/**
 * Exercises the todo page's core feature end to end: create, complete, edit,
 * and delete a todo. Every mutation goes through client/utilities/request.js,
 * which reads the access token via `user.tokens().get()` and sends it as a
 * bearer token to the protected todo-api on 9443. So this is also the only spec
 * that proves the widget's token retrieval reaches a real protected resource.
 *
 * A per-run unique title keeps the test independent of any todos left over from
 * previous runs and safe under parallel execution.
 */

async function signIn(page) {
  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();
  await page.getByLabel('Username').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');
  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();
}

test('React - create, complete, edit and delete a todo', async ({ page }) => {
  await signIn(page);

  const title = `e2e todo ${Date.now()}`;
  const editedTitle = `${title} (edited)`;

  // Go to the protected Todos route.
  await page.getByRole('link', { name: 'Todos', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'Your Todos' })).toBeVisible();

  // Create — POST /todos with the bearer token.
  await page.getByLabel('What needs doing?').fill(title);
  await page.getByRole('button', { name: 'Create' }).click();

  const todoItem = page.locator('li.cstm_todo-item').filter({ hasText: title });
  await expect(todoItem).toBeVisible();

  // Complete — toggling the checkbox POSTs { completed: true }.
  const checkbox = todoItem.locator('input[type="checkbox"]');
  await todoItem.locator('label.cstm_todo-label').click();
  await expect(checkbox).toBeChecked();

  // Edit — open the todo's action menu, rename it in the modal.
  await todoItem.locator('button.cstm_dropdown-actions').click();
  await todoItem.getByRole('button', { name: 'Edit' }).click();

  const editInput = page.getByLabel('Update todo text');
  await expect(editInput).toBeVisible();
  await editInput.fill(editedTitle);
  await page.getByRole('button', { name: 'Update Todo' }).click();

  const editedItem = page.locator('li.cstm_todo-item').filter({ hasText: editedTitle });
  await expect(editedItem).toBeVisible();

  // Delete — open the action menu, confirm in the delete modal.
  await editedItem.locator('button.cstm_dropdown-actions').click();
  await editedItem.getByRole('button', { name: 'Delete' }).click();
  await page.getByRole('button', { name: 'Delete Todo' }).click();

  await expect(page.locator('li.cstm_todo-item').filter({ hasText: editedTitle })).toHaveCount(0);
});
