import { test, expect } from '@playwright/test';

test('Angular - Login with centralized login', async ({ page }) => {
  await page.goto('https://localhost:8443/home?centralLogin=true');

  await page.getByRole('link', { name: 'Sign In', exact: true }).click();
  await expect(page.getByText('Redirecting ...')).toBeVisible();

  await page.getByLabel('User Name').fill('user01');
  await page.getByLabel('Password').first().fill('Password1!');
  await page.getByRole('button', { name: 'Next' }).click();

  await page.waitForTimeout(3000);

  await page.reload();

  await expect(page.getByText('Welcome back, user01 user01!')).toBeVisible();
});
