/*
 * ping-sample-web-react-journey
 *
 * protect.spec.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { test, expect } from '@playwright/test';
import { password, username } from './utils/demo-user';

const authenticateRequestUrl = 'https://openam-sdks.forgeblocks.com/am/json/alpha/authenticate';

test.describe('React Journey - Login with Protect', () => {
  test('should succeed when initialized by callback', async ({ page }) => {
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

    await page.goto('http://localhost:8443/?journey=TEST_Protect&initProtect=journey');
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await expect(page.getByRole('heading', { name: 'Sign In' })).toBeVisible();

    const protectPromise = page.waitForRequest((req) => {
      return (
        req.method() === 'POST' &&
        req.url() === authenticateRequestUrl &&
        req
          .postDataJSON()
          ?.callbacks?.some((callback) => callback.type === 'PingOneProtectEvaluationCallback')
      );
    });
    await page.getByRole('textbox', { name: 'User Name' }).fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);
    await page.getByRole('button', { name: 'Sign In' }).click();
    await protectPromise;

    expect(riskData).toBeDefined();
    expect(riskData).toMatch(/^R\/o\//);

    expect(logs.includes('Protect initialized by callback for data collection')).toBeTruthy();
    expect(logs.includes('Data set on Protect evaluation callback')).toBeTruthy();

    page.removeListener('console', (msg) => console.log(msg.text()));
  });

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

    await page.goto('http://localhost:8443/?journey=TEST_Protect&initProtect=bootstrap');
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    await expect(page.getByRole('heading', { name: 'Sign In' })).toBeVisible();

    const protectPromise = page.waitForRequest((req) => {
      return (
        req.method() === 'POST' &&
        req.url() === authenticateRequestUrl &&
        req
          .postDataJSON()
          ?.callbacks?.some((callback) => callback.type === 'PingOneProtectEvaluationCallback')
      );
    });
    await page.getByRole('textbox', { name: 'User Name' }).fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);
    await page.getByRole('button', { name: 'Sign In' }).click();
    await protectPromise;

    expect(riskData).toBeDefined();
    expect(riskData).toMatch(/^R\/o\//);

    expect(logs.includes('Protect initialized at bootstrap for data collection')).toBeTruthy();
    expect(logs.includes('Data set on Protect evaluation callback')).toBeTruthy();

    page.removeListener('console', (msg) => console.log(msg.text()));
  });
});
