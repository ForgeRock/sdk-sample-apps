import { test, expect } from '@playwright/test';

test('React - Login with Centralized Login', async ({ page }) => {
  await page.goto('https://localhost:8443/?centralLogin=true');

  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await page.getByLabel('User Name').fill('user01');
  await page.getByLabel('Password').first().fill('Password1!');
  await page.getByRole('button', { name: 'Next' }).click();

  // TODO: It should be fixed evantually. This line has been added as after succesfully logging in, the server
  // stops responding and it is necessary to reload the page in order for it to work. FYI: Only happens when running
  // e2e tests.
  await page.waitForTimeout(3000);

  await page.reload();

  await expect(page.getByText('Welcome back, user01 user01!')).toBeVisible();
});
