import { test, expect } from '@playwright/test';
import { password, username, displayName } from './utils/demo-user';

test('React - Login with embedded login', async ({ page }) => {
  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  // failed login
  await page.getByLabel('Username').fill('notauser');
  await page.getByLabel('Password').fill('notapassword');

  await page.getByLabel('Password').press('Enter');
  await expect(page.getByText('Sign in failed')).toBeVisible();

  // successful login
  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await page.getByLabel('Username').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');

  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();
});
