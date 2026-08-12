import { test, expect } from '@playwright/test';
import { password, username, displayName } from './utils/demo-user';

/**
 * Regression guard for a logout triggered by navigating to a protected route.
 *
 * ProtectedRoute calls `user.info().get()` to validate access. When the widget's
 * underlying store was already `completed` from a prior fetch, reading it crashed
 * on Svelte's synchronous subscribe emission — `get()` rejected, the route guard's
 * catch called `setAuth(false)`, and the user was logged out (tokens cleared from
 * localStorage). It was intermittent because it only fired once a store had
 * completed at least once. This exercises repeated Home <-> Todos navigation and
 * asserts the session survives (the authenticated account menu stays present and
 * the OAuth tokens remain in localStorage).
 */

const NAVIGATION_ROUNDS = 4;

test('React - navigating to Todos repeatedly does not log the user out', async ({ page }) => {
  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign In', exact: true }).click();

  await page.getByLabel('Username').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');

  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

  // A logout clears the widget's OAuth tokens from localStorage. Capture the key
  // so we can assert the session persists across navigations.
  const tokenKeyCount = async () =>
    page.evaluate(() =>
      Object.keys(window.localStorage).filter((key) => key.startsWith('pic-')).length,
    );

  expect(await tokenKeyCount(), 'expected OAuth tokens in localStorage after login').toBeGreaterThan(
    0,
  );

  for (let round = 0; round < NAVIGATION_ROUNDS; round++) {
    // Go to the protected Todos route — this runs ProtectedRoute's access check.
    // Exact match: the home page also has a "Manage your todos here" link.
    await page.getByRole('link', { name: 'Todos', exact: true }).click();
    await expect(page.getByRole('heading', { name: 'Your Todos' })).toBeVisible();

    // Back to Home.
    await page.getByRole('link', { name: 'Home', exact: true }).click();
    await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

    // The access check must not have logged us out.
    expect(
      await tokenKeyCount(),
      `session was cleared after navigation round #${round + 1}`,
    ).toBeGreaterThan(0);
  }
});
