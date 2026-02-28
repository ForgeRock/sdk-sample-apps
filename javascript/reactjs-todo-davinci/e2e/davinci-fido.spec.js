/*
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */

import { test, expect } from '@playwright/test';

const username = 'JSFidoUser@user.com';
const password = 'FakePassword#123';

test.use({ browserName: 'chromium' });

// these tests are skipped and should be run manually because there is a limit on the number of FIDO registrations for each user
// to be able to run these tests, uncomment server with 5829 port in the playwright.config.ts file
test.describe.skip('WebAuthn Virtual Authenticator Setup', () => {
  let cdpClient;
  let authenticatorId;

  test.beforeEach(async ({ page }) => {
    cdpClient = await page.context().newCDPSession(page);

    await cdpClient.send('WebAuthn.enable');

    const result = await cdpClient.send('WebAuthn.addVirtualAuthenticator', {
      options: {
        protocol: 'ctap2',
        transport: 'internal', // platform authenticator
        hasResidentKey: true, // allow discoverable credentials (passkeys)
        hasUserVerification: true, // device supports UV
        isUserVerified: true, // simulate successful UV (PIN/biometric)
        automaticPresenceSimulation: true, // auto "touch"/presence
      },
    });

    authenticatorId = result.authenticatorId;
  });

  test.afterEach(async () => {
    if (authenticatorId) {
      await cdpClient.send('WebAuthn.removeVirtualAuthenticator', { authenticatorId });
      await cdpClient.send('WebAuthn.disable');
    }
  });

  test('should successfully register a new WebAuthn credential and authenticate', async ({
    page,
  }) => {
    await page.goto('http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c');
    await expect(page).toHaveURL(
      'http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c',
    );

    // Sign in to enable FIDO MFA flow
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByRole('link', { name: 'USER_LOGIN' }).click();
    await page.getByRole('textbox', { name: 'Username' }).fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);
    await page.getByRole('button', { name: 'Sign On' }).click();

    // Register a new WebAuthn credential
    await page.getByRole('button', { name: 'DEVICE_REGISTRATION' }).click();
    await page.getByLabel('MFA Device Selection -').selectOption('FIDO2');
    await expect(page.getByLabel('MFA Device Selection -')).toHaveValue('FIDO2');
    await page.getByRole('button', { name: 'Next' }).click();
    await page.getByRole('button', { name: 'Continue' }).click();

    // Verify we're back at home page if registration is successful
    await expect(page.getByText('FIDO2 Test Form')).toBeVisible();

    // Authenticate with the newly registered credential
    await page.getByRole('link', { name: 'DEVICE_AUTHENTICATION' }).click();
    const deviceSelector = page.getByLabel('MFA Device Selection -');
    await expect(deviceSelector).toBeVisible();
    const options = deviceSelector.locator('option').filter({ hasText: 'Biometrics/Security Key' });
    const lastValue = await options.last().getAttribute('value');
    await deviceSelector.selectOption(lastValue);
    await page.getByRole('button', { name: 'Next' }).click();

    // Verify we're back at home page if authentication is successful
    await expect(page.getByText('FIDO2 Test Form')).toBeVisible();
  });

  test('should fail to register a new WebAuthn credential', async ({ page }) => {
    await page.goto('http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c');
    await expect(page).toHaveURL(
      'http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c',
    );

    // Disable automatic presence simulation to simulate registration failure
    await cdpClient.send('WebAuthn.setAutomaticPresenceSimulation', {
      authenticatorId,
      enabled: false,
    });

    // Sign in to enable FIDO MFA flow
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByRole('link', { name: 'USER_LOGIN' }).click();
    await page.getByRole('textbox', { name: 'Username' }).fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);
    await page.getByRole('button', { name: 'Sign On' }).click();

    // Try to register a new WebAuthn credential
    await page.getByRole('button', { name: 'DEVICE_REGISTRATION' }).click();
    await page.getByLabel('MFA Device Selection -').selectOption('FIDO2');
    await expect(page.getByLabel('MFA Device Selection -')).toHaveValue('FIDO2');
    await page.getByRole('button', { name: 'Next' }).click();

    // Assert that registration has failed
    await expect(page.getByRole('heading', { name: 'FIDO2 Registration' })).toBeVisible();
    await expect(
      page.getByRole('button', { name: 'Continue' }).click({ trial: true, timeout: 5000 }),
    ).rejects.toThrow();
  });

  test('should fail to authenticate with an existing WebAuthn credential', async ({ page }) => {
    await page.goto('http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c');
    await expect(page).toHaveURL(
      'http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c',
    );

    // Sign in to enable FIDO MFA flow
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByRole('link', { name: 'USER_LOGIN' }).click();
    await page.getByRole('textbox', { name: 'Username' }).fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);
    await page.getByRole('button', { name: 'Sign On' }).click();

    // Register a new WebAuthn credential
    await page.getByRole('button', { name: 'DEVICE_REGISTRATION' }).click();
    await page.getByLabel('MFA Device Selection -').selectOption('FIDO2');
    await expect(page.getByLabel('MFA Device Selection -')).toHaveValue('FIDO2');
    await page.getByRole('button', { name: 'Next' }).click();
    await page.getByRole('button', { name: 'Continue' }).click();

    // Verify we're back at home page if registration is successful
    await expect(page.getByText('FIDO2 Test Form')).toBeVisible();

    // Disable automatic presence simulation to simulate authentication failure
    await cdpClient.send('WebAuthn.setAutomaticPresenceSimulation', {
      authenticatorId,
      enabled: false,
    });

    // Try to authenticate with the newly registered credential
    await page.getByRole('link', { name: 'DEVICE_AUTHENTICATION' }).click();
    const deviceSelector = page.getByLabel('MFA Device Selection -');
    await expect(deviceSelector).toBeVisible();
    const options = deviceSelector.locator('option').filter({ hasText: 'Biometrics/Security Key' });
    const lastValue = await options.last().getAttribute('value');
    await deviceSelector.selectOption(lastValue);
    await page.getByRole('button', { name: 'Next' }).click();

    // Assert that authentication has failed
    await expect(page.getByRole('heading', { name: 'FIDO2 Authentication' })).toBeVisible();

    // Try to click on a non-existent device regsitration button to confirm that we're still on the authentication page and not navigated back to home page
    await expect(
      page
        .getByRole('button', { name: 'DEVICE_REGISTRATION' })
        .click({ trial: true, timeout: 5000 }),
    ).rejects.toThrow();
  });
});
