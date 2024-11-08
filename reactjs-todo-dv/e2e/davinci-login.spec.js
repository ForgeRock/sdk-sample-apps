import { test, expect } from '@playwright/test';

test('React - Login using DaVinci', async ({ page }) => {
  await page.goto('http://localhost:8443');
  await expect(page.getByText('About this project')).toBeVisible();
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();
  await page.getByLabel('Username').fill('demouser@mailinator.com');
  await page.getByLabel('Password').first().fill('2FederateM0re!');
  await page.getByRole('button', { name: 'Sign On' }).click();
  await expect(page.getByText('Welcome back')).toBeVisible();
});
