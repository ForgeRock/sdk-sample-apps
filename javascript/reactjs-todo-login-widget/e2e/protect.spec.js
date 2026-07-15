import { test, expect, describe } from '@playwright/test';
import { displayName, password, username } from './utils/demo-user';

describe('React - Login with Protect', () => {
  test('should succeed when initialized by callback', async ({ page }) => {
    const logs = [];
    page.on('console', async (msg) => {
      logs.push(msg.text());
      return Promise.resolve(true);
    });

    await page.goto('https://localhost:8443?journey=TEST_Protect');
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await page.getByLabel('Username').fill(username);
    await page.getByLabel('Password').fill(password);
    await page.getByLabel('Password').press('Enter');

    await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

    expect(logs.includes('PingOne Protect initialized at bootstrap')).toBeTruthy();

    page.removeListener('console', (msg) => console.log(msg.text()));
  });
});
