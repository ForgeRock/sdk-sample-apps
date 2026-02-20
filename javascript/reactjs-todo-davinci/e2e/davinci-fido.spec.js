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
      }
    });

    authenticatorId = result.authenticatorId;
  });

  test.afterEach(async () => {
    if (authenticatorId) {
      await cdpClient.send('WebAuthn.removeVirtualAuthenticator', { authenticatorId });
      await cdpClient.send('WebAuthn.disable');
    }
  });

  test('should successfully register a new WebAuthn credential and authenticate', async ({ page }) => {
    await page.goto(
      'http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c',
    );
    await expect(page).toHaveURL(
      'http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c',
    );

    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByRole('link', { name: 'USER_LOGIN' }).click();
    await page.getByRole('textbox', { name: 'Username' }).fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);
    await page.getByRole('button', { name: 'Sign On' }).click();

    const { credentials: initialCredentials } = await cdpClient.send('WebAuthn.getCredentials', {
      authenticatorId,
    });
    expect(initialCredentials).toHaveLength(0);

    await page.getByRole('button', { name: 'DEVICE_REGISTRATION' }).click();

    await expect(page.getByLabel('MFA Device Selection -')).toBeVisible();
    await page.getByLabel('MFA Device Selection -').selectOption('FIDO2');
    await expect(page.getByLabel('MFA Device Selection -')).toHaveValue('FIDO2');
    await page.getByRole('button', { name: 'Next' }).click();

    // Wait until the WebAuthn registration ceremony has actually produced a credential
    await expect.poll(async () => {
      const { credentials } = await cdpClient.send('WebAuthn.getCredentials', { authenticatorId });
      return credentials.length;
    }).toBe(1);

    const { credentials: recordedCredentials } = await cdpClient.send('WebAuthn.getCredentials', {
      authenticatorId,
    });
    expect(recordedCredentials).toHaveLength(1);

    await page.getByRole('button', { name: 'Continue' }).click();

    // Verify we're back at home page if registration is successful
    await expect(page.getByText('FIDO2 Test Form')).toBeVisible();

    // Authenticate with the registered WebAuthn credential
    const initialSignCount = recordedCredentials[0].signCount;

    await page.getByRole('link', { name: 'DEVICE_AUTHENTICATION' }).click();
    await expect(page.getByLabel('MFA Device Selection -')).toContainText('Biometrics/Security Key');
    await expect(page.getByLabel('MFA Device Selection -')).toBeVisible();
    await page.getByLabel('MFA Device Selection -').selectOption('815e5114-94e2-403f-a1bc-84cc88c1111a');
    await page.getByRole('button', { name: 'Next' }).click();

    // Wait until a successful assertion increments the credential signature counter
    await expect.poll(async () => {
      const { credentials } = await cdpClient.send('WebAuthn.getCredentials', { authenticatorId });
      return credentials[0]?.signCount;
    }).toBeGreaterThan(initialSignCount);

    // Verify we're back at home page if successful
    await expect(page.getByText('FIDO2 Test Form')).toBeVisible();
  });

  test('should fail to register a new WebAuthn credential', async ({ page }) => {
    await page.goto(
      'http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c',
    );
    await expect(page).toHaveURL(
      'http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c',
    );

    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByRole('link', { name: 'USER_LOGIN' }).click();
    await page.getByRole('textbox', { name: 'Username' }).fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);
    await page.getByRole('button', { name: 'Sign On' }).click();

    const { credentials: initialCredentials } = await cdpClient.send('WebAuthn.getCredentials', {
      authenticatorId,
    });
    expect(initialCredentials).toHaveLength(0);

    await page.getByRole('button', { name: 'DEVICE_REGISTRATION' }).click();

    await expect(page.getByLabel('MFA Device Selection -')).toBeVisible();
    await page.getByLabel('MFA Device Selection -').selectOption('FIDO2');
    await expect(page.getByLabel('MFA Device Selection -')).toHaveValue('FIDO2');
    await page.getByRole('button', { name: 'Next' }).click();

    // Assert no credential was registered
    const { credentials: recordedCredentials } = await cdpClient.send('WebAuthn.getCredentials', {
      authenticatorId,
    });
    expect(recordedCredentials).toHaveLength(0);
  });

  test('should fail to authenticate after registration with a new WebAuthn credential', async ({ page }) => {
    await page.goto(
      'http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c',
    );
    await expect(page).toHaveURL(
      'http://localhost:5829/?acrValue=98f2c058aae71ec09eb268db6810ff3c',
    );

    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await page.getByRole('link', { name: 'USER_LOGIN' }).click();
    await page.getByRole('textbox', { name: 'Username' }).fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);
    await page.getByRole('button', { name: 'Sign On' }).click();

    const { credentials: initialCredentials } = await cdpClient.send('WebAuthn.getCredentials', {
      authenticatorId,
    });
    expect(initialCredentials).toHaveLength(0);

    await page.getByRole('button', { name: 'DEVICE_REGISTRATION' }).click();

    await expect(page.getByLabel('MFA Device Selection -')).toBeVisible();
    await page.getByLabel('MFA Device Selection -').selectOption('FIDO2');
    await expect(page.getByLabel('MFA Device Selection -')).toHaveValue('FIDO2');
    await page.getByRole('button', { name: 'Next' }).click();

    // Wait until the WebAuthn registration ceremony has actually produced a credential
    await expect.poll(async () => {
      const { credentials } = await cdpClient.send('WebAuthn.getCredentials', { authenticatorId });
      return credentials.length;
    }).toBe(1);

    const { credentials: recordedCredentials } = await cdpClient.send('WebAuthn.getCredentials', {
      authenticatorId,
    });
    expect(recordedCredentials).toHaveLength(1);

    await page.getByRole('button', { name: 'Continue' }).click();

    // Verify we're back at home page if registration is successful
    await expect(page.getByText('FIDO2 Test Form')).toBeVisible();

    // Authenticate with the registered WebAuthn credential
    const initialSignCount = recordedCredentials[0].signCount;

    await page.getByRole('link', { name: 'DEVICE_AUTHENTICATION' }).click();
    await expect(page.getByLabel('MFA Device Selection -')).toContainText('Biometrics/Security Key');
    await expect(page.getByLabel('MFA Device Selection -')).toBeVisible();
    await page.getByLabel('MFA Device Selection -').selectOption('815e5114-94e2-403f-a1bc-84cc88c1111a');
    await page.getByRole('button', { name: 'Next' }).click();

    const credentialsAfterAuth = await cdpClient.send('WebAuthn.getCredentials', {
      authenticatorId,
    });
    expect(credentialsAfterAuth.credentials).toHaveLength(1);
    expect(credentialsAfterAuth.credentials[0].signCount).toBe(initialSignCount);
  }); 
});