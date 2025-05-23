import { test, expect, describe } from '@playwright/test';

describe('React - Login with Protect', () => {
  test('should succeed when initialized by callback', async ({ page }) => {
    const logs = [];
    page.on('console', async (msg) => {
      logs.push(msg.text());
      return Promise.resolve(true);
    });

    await page.goto('https://localhost:8443?journey=TEST_Protect');
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await page.getByLabel('User Name').fill('user01');
    await page.getByLabel('Password').fill('Password1!');
    await page.getByLabel('Password').press('Enter');

    await expect(page.getByText('Welcome back, user01 user01!')).toBeVisible();

    await expect(logs.includes('PingOne Protect initialized by callback')).toBeTruthy();
    await expect(logs.includes('Data set on Protect evaluation callback')).toBeTruthy();

    page.removeListener('console', (msg) => console.log(msg.text()));
  });
});
