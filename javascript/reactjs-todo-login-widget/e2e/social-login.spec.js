import { test, expect } from '@playwright/test';

test('React - Login with social login', async ({ page }) => {
  await page.goto('https://localhost:8443/?journey=TEST_LoginWithSocial');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await expect(page.getByLabel('Username')).toBeEmpty();
  await expect(page.getByLabel('Username')).toBeVisible();
  await expect(page.getByLabel('Password')).toBeEmpty();
  await expect(page.getByLabel('Password')).toBeVisible();

  await expect(page.getByRole('button', { name: 'Continue with Apple' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Continue with Facebook' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Continue with Google' })).toBeVisible();
});
