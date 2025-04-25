import { test, expect } from '@playwright/test';

const BASE_URL = 'http://localhost:8443';

test.describe('Angular - Davinci Todo', () => {
  test.describe.configure({ mode: 'default' }); // Don't run these tests in parallel

  async function goToTodosPage(page) {
    // Log in and go to the todos page
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByLabel('Username').fill('JsDvSampleAppsE2E@user.com');
    await page.getByLabel('Password').fill('FakePassword#123');
    await page.getByRole('button', { name: 'Sign On' }).click();
    await page.getByRole('link', { name: 'Todos', exact: true }).click();
    await page.waitForURL(BASE_URL + '/todos');

    // Wait for todos to load
    await expect(page.getByText('Verifying access')).toHaveCount(0);
    await expect(page.getByRole('heading', { name: 'Your Todos' })).toBeVisible();
    await expect(page.getByText('Collecting your todos')).toHaveCount(0);
  }

  async function cleanupTodos(page) {
    const dropdowns = await page.locator('ul li > div > button');
    const numDropdowns = await dropdowns?.count();
    if (numDropdowns) {
      for (let i = 0; i < numDropdowns; i++) {
        await dropdowns.first().click(); // Select the first todo item's dropdown
        await page.getByRole('button', { name: 'Delete' }).click();
        await page.getByRole('button', { name: 'Delete Todo' }).click();
      }
    }
    await expect(page.getByText('No todos yet. Create one above!')).toBeVisible();
  }

  test.beforeEach(async ({ page }) => {
    await goToTodosPage(page);
  });

  test.afterEach(async ({ page }) => {
    await cleanupTodos(page);
  });

  // Log in, create a todo, log out, then log back in and retrieve the todo
  test('Get todos, pass', async ({ page }) => {
    // Create a todo
    const todoText = 'Test get todo';
    await page.getByPlaceholder('What needs doing?').fill(todoText);
    await page.getByRole('button', { name: 'Create' }).click();
    await expect(page.getByText(todoText)).toBeVisible();

    // Log out
    await page.locator('#account_dropdown').click();
    await page.getByRole('link', { name: 'Sign Out' }).click();
    await page.waitForURL(BASE_URL + '/logout');
    await page.waitForURL(BASE_URL + '/home');
    await expect(page.getByText('Welcome back')).not.toBeVisible();
    await expect(page.getByText('Protect with Ping')).toBeVisible();

    // Log back in and find the created todo
    await goToTodosPage(page);
    await expect(page.getByText(todoText)).toBeVisible();
  });

  test('Create and delete todo, pass', async ({ page }) => {
    const todoText = 'Test create todo';

    // Create the todo
    await page.getByPlaceholder('What needs doing?').fill(todoText);
    await page.getByRole('button', { name: 'Create' }).click();
    await expect(page.getByText(todoText)).toBeVisible();

    // Delete the todo
    await page.locator('ul li > div > button').first().click(); // Select the first todo item's dropdown
    await page.getByRole('button', { name: 'Delete' }).click();
    await page.getByRole('button', { name: 'Delete Todo' }).click();
    await expect(page.getByText(todoText)).not.toBeVisible();
  });

  test('Edit todo, pass', async ({ page }) => {
    const initialTodoText = 'Initial todo';
    const updatedTodoText = 'Updated todo';

    // Create the todo
    await page.getByPlaceholder('What needs doing?').fill(initialTodoText);
    await page.getByRole('button', { name: 'Create' }).click();

    // Edit the todo
    await page.locator('ul li > div > button').first().click(); // Select the first todo item's dropdown
    await page.getByRole('button', { name: 'Edit' }).click();
    await page.getByLabel('Update todo text').fill(updatedTodoText);
    await page.getByRole('button', { name: 'Update Todo' }).click();
    await expect(page.getByText(updatedTodoText)).toBeVisible();
    await expect(page.getByText(initialTodoText)).not.toBeVisible();
  });
});
