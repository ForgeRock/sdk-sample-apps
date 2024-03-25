import { test, expect } from '@playwright/test';
import { v4 as uuid } from 'uuid';

const toDo = uuid() + ' ' + 'TEST';

test('Angular - Login with embedded login and manage todos', async ({ page }) => {
  //create new todo
  await page.goto('https://localhost:8443/home');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();
  await page.getByLabel('User Name').fill('user01');
  await page.getByLabel('Password').fill('Password1!');
  await page.getByLabel('Password').press('Enter');
  await page.getByRole('link', { name: 'Manage your todos here' }).click();
  await page.getByLabel('What needs doing?').click();
  await page.getByLabel('What needs doing?').fill(toDo);
  await page.getByRole('button', { name: 'Create' }).click();
  await expect(page.getByText(toDo)).toBeVisible();

  //Edit todo
  await page.getByLabel('More actions').first().click();
  await page.getByRole('button', { name: 'Edit' }).click();
  await page.getByLabel('Update todo text').fill(`${toDo} - Edited`);
  await page.getByRole('button', { name: 'Update Todo' }).click();

  const newTodo = await page.getByLabel('todo title text').first().textContent();

  await expect(newTodo.trim()).toBe(`${toDo} - Edited`);

  //Delete todo
  await page.getByLabel('More actions').first().click();
  await page.getByLabel('delete button').click();
  await page.getByRole('button', { name: 'Delete Todo' }).click();
  await expect(page.getByText(newTodo)).not.toBeVisible();
});
