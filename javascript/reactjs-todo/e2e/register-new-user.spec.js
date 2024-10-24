import { test, expect } from '@playwright/test';
import { v4 as uuid } from 'uuid';

const userName = uuid();

test('React - Register user', async ({ page }) => {
  await page.goto('https://localhost:8443/');
  await page.getByRole('link', { name: 'Sign Up' }).click();
  await page.getByLabel('Username').fill(userName);
  await page.getByLabel('First Name').fill('newUser');
  await page.getByLabel('Last Name').fill('newUser');
  await page.getByLabel('Email Address').fill('newUser@user.com');
  await page.getByLabel('Password').fill('Password1!');
  await page.getByLabel('Password').press('Tab');
  await page
    .getByLabel('Select a security question')
    .first()
    .selectOption({ label: `What's your favorite color?` });
  await page.getByLabel('Security Answer').first().fill('Red');
  await page
    .getByLabel('Select a security question')
    .last()
    .selectOption({ label: `Who was your first employer?` });
  await page.getByLabel('Security Answer').last().fill('employee');

  await page.getByLabel('Please accept our below Terms').check();
  await page.getByRole('button', { name: 'Register' }).click();

  await expect(page.getByText('Welcome back, newUser newUser')).toBeVisible();
});
