import { test, expect } from '@playwright/test';

test('Angular - Login with WebAuthn', async ({ browser, page }) => {
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

    await page.getByLabel('User Name').fill('user01');
    await page.getByLabel('Password').fill('Password1!');
    await page.getByPlaceholder('Password').press('Enter');

    await expect(page.getByText('Welcome back, user01 user01!')).toBeVisible();

    await cdpSession.send('WebAuthn.removeVirtualAuthenticator', {
      authenticatorId: authenticator.authenticatorId,
    });
  }
});
