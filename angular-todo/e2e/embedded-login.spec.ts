import { test, expect } from '@playwright/test';

test('embedded login angular', async ({ page }) => {
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

  await page.getByLabel('User Name').fill('user01');
  await page.getByLabel('Password').fill('Password1!');
  await page.getByLabel('Password').press('Enter');

  await expect(page.getByText('Success! Redirecting ...')).toBeVisible();
  await expect(page.getByText('Welcome back, user01 user01!')).toBeVisible();
});
