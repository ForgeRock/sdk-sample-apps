import { test, expect } from '@playwright/test';
import { displayName, password, username } from './utils/demo-user';

test('Angular - Login with embedded login', async ({ page }) => {
  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  //failed login
  await page.getByLabel('User Name').fill('notauser');
  await page.getByLabel('Password').fill('notapassword');

  await page.getByLabel('Password').press('Enter');
  await expect(page.getByText('Login failure')).toBeVisible();

  //successful login
  await page.goto('https://localhost:8443/home');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await page.getByLabel('User Name').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');

  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();
});
