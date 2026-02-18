/*
 * ping-sample-web-react-journey
 *
 * virtual-authenticator.spec.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { test, expect } from '@playwright/test';
import { displayName, password, username } from './utils/demo-user';

test.use({ browserName: 'chromium' });

// Skipping this until we handle cleaning up users or devices so we don't run into
// max allowed credentials when authenticating
test.skip('React Journey - Register and Authenticate with WebAuthN', async ({ page, context }) => {
  const cdpSession = await context.newCDPSession(page);
  await cdpSession.send('WebAuthn.enable');

  const response = await cdpSession.send('WebAuthn.addVirtualAuthenticator', {
    options: {
      protocol: 'ctap2',
      transport: 'internal',
      hasUserVerification: true,
      isUserVerified: true,
      hasResidentKey: true,
      automaticPresenceSimulation: true,
    },
  });
  const authenticatorId = response.authenticatorId;

  await page.goto('https://localhost:8443/?journey=TEST_WebAuthn-Registration');

  const { credentials: initialCredentials } = await cdpSession.send('WebAuthn.getCredentials', {
    authenticatorId,
  });
  await expect(initialCredentials).toHaveLength(0);

  await page.getByRole('link', { name: 'Sign In', exact: true }).click();
  await page.getByLabel('User Name').fill(username);
  await page.getByLabel('Password').fill(password);
  await page.getByLabel('Password').press('Enter');

  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

  const { credentials: recordedCredentials } = await cdpSession.send('WebAuthn.getCredentials', {
    authenticatorId,
  });
  await expect(recordedCredentials).toHaveLength(1);

  await page.locator('#account_dropdown').click();
  await page.getByRole('link', { name: 'Sign Out' }).click();
  await expect(page.getByText('Welcome back')).not.toBeVisible();
  await expect(page.getByRole('link', { name: 'Sign In', exact: true })).toBeVisible();

  // Authenticate with the registered WebAuthn credential
  const initialSignCount = recordedCredentials[0].signCount;

  await page.goto('https://localhost:8443/?journey=TEST_WebAuthnAuthentication');

  await page.getByRole('link', { name: 'Sign In', exact: true }).click();
  await page.getByLabel('User Name').fill(username);
  await page.getByRole('button', { name: 'Sign In' }).click();

  await expect(page.getByText(`Welcome back, ${displayName}!`)).toBeVisible();

  const credentialsAfterAuth = await cdpSession.send('WebAuthn.getCredentials', {
    authenticatorId,
  });
  await expect(credentialsAfterAuth.credentials).toHaveLength(1);

  // Signature counter should have incremented after successful authentication/assertion
  await expect(credentialsAfterAuth.credentials[0].signCount).toBeGreaterThan(initialSignCount);

  await cdpSession.send('WebAuthn.removeVirtualAuthenticator', { authenticatorId });
  await cdpSession.send('WebAuthn.disable');
});
