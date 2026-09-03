import { test, expect, describe } from '@playwright/test';
import { password, username } from './utils/demo-user';

const authenticateRequestUrl = 'https://openam-sdks.forgeblocks.com/am/json/alpha/authenticate';

describe('React - Login with Protect', () => {
  test('should succeed when initialized at bootstrap', async ({ page }) => {
    const logs = [];
    page.on('console', async (msg) => {
      logs.push(msg.text());
      return Promise.resolve(true);
    });

    let riskData;
    page.on('request', (request) => {
      const method = request.method();
      const requestUrl = request.url();
      const payload = request.postDataJSON();

      // Only process POST requests with JSON payloads
      if (method === 'POST' && payload && requestUrl.includes(authenticateRequestUrl)) {
        const callback = payload.callbacks?.find(
          (callback) => callback.type === 'PingOneProtectEvaluationCallback',
        );

        if (callback) {
          const data = callback.input?.find((input) => input.name === 'IDToken1signals')?.value;
          riskData = data;
        }
      }
    });

    await page.goto('https://localhost:8443?journey=TEST_Protect');
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    const protectPromise = page.waitForRequest((req) => {
      return (
        req.method() === 'POST' &&
        req.url() === authenticateRequestUrl &&
        req
          .postDataJSON()
          ?.callbacks?.some((callback) => callback.type === 'PingOneProtectEvaluationCallback')
      );
    });
    await page.getByRole('textbox', { name: 'Username' }).fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);
    await page.getByRole('button', { name: 'Next' }).click();
    await protectPromise;

    expect(riskData).toBeDefined();
    expect(riskData).toMatch(/^R\/o\//);

    expect(logs.includes('PingOne Protect initialized at bootstrap')).toBeTruthy();

    page.removeListener('console', (msg) => console.log(msg.text()));
  });
});
