import { test, expect } from '@playwright/test';

const BASE_URL = 'http://localhost:8443';

test.describe('Angular - DaVinci Password Reset', () => {
  test('Check password reset flow, pass', async ({ page }) => {
    // Check for password reset form
    await page.goto(BASE_URL);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByText('Having trouble signing on?').click();
    await expect(page.getByRole('heading', { name: 'Forgot password form' })).toBeVisible();
    await page.getByLabel('Username').fill('JsDvSampleAppsE2E@user.com');
    await page.getByRole('button', { name: 'Submit' }).click();

    // Check for password reset verification form
    await expect(
      page.getByRole('heading', { name: 'Forgot password recovery code form' }),
    ).toBeVisible();
    await expect(page.getByLabel('Recovery Code')).toBeVisible();
    await expect(page.getByLabel('New Password')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Submit' })).toBeVisible();
  });
});
