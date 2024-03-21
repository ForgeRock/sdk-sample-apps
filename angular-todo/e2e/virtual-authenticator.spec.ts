import { test, expect } from '@playwright/test';

test('webAuth login angular', async ({ browser, page }) => {
  let authenticator;
  if (browser.browserType().name() === 'chromium') {
    const cdpSession = await page.context().newCDPSession(page);

    await cdpSession.send('WebAuthn.enable');
    authenticator = await cdpSession.send('WebAuthn.addVirtualAuthenticator', {
      options: {
        protocol: 'ctap2',
        transport: 'internal',
        hasUserVerification: true,
        isUserVerified: true,
        hasResidentKey: true,
      },
    });

    await page.goto('https://localhost:8443/home?journey=TEST_WebAuthn-Registration');
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await page.getByPlaceholder('User Name').fill('demouser');
    await page.getByLabel('Password').fill('j56eKtae*1');
    await page.getByPlaceholder('Password').press('Enter');

    await expect(page.getByText('Success! Redirecting ...')).toBeVisible();
    await expect(page.getByText('Welcome back, Demo User!')).toBeVisible();

    await cdpSession.send('WebAuthn.removeVirtualAuthenticator', {
      authenticatorId: authenticator.authenticatorId,
    });
  }
});
