/*
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';
import { username, password } from './utils/demo-user';

const BASE_URL = 'http://localhost:8443';
const htmlFormAcrValue = 'ea02bcbfb2112e051c94ee9b08083d2d';

test.describe('React - DaVinci Protect', () => {
  test('Initialize at bootstrap and evaluate risk', async ({ page }) => {
    const logs = [];
    page.on('console', async (msg) => {
      logs.push(msg.text());
      return Promise.resolve(true);
    });

    await page.goto(`${BASE_URL}?initProtect=bootstrap&acrValue=${htmlFormAcrValue}`);

    await page.getByRole('link', { name: 'Sign In', exact: true }).click();
    await expect(page.getByText('JS Protect - Custom HTML Form')).toBeVisible();

    let riskData;
    page.on('request', (request) => {
      const method = request.method();
      const requestUrl = request.url();
      const payload = request.postDataJSON();

      // Only process POST requests with JSON payloads
      if (method === 'POST' && payload && requestUrl.includes('customHTMLTemplate')) {
        const data = payload.parameters?.data?.formData?.riskSDK;
        if (data) {
          riskData = data;
        }
      }
    });

    const protectPromise = page.waitForRequest(
      (req) =>
        req.method() === 'POST' &&
        req.url().includes('customHTMLTemplate') &&
        req.postDataJSON()?.parameters?.data?.formData?.riskSDK,
    );
    await page.getByLabel('Username').fill(username);
    await page.getByLabel('Password').fill(password);
    await page.getByRole('button', { name: 'Sign On' }).click();
    await protectPromise;

    expect(riskData).toBeDefined();
    expect(riskData).toMatch(/^R\/o\//);

    expect(logs.includes('Protect initialized at bootstrap for data collection')).toBeTruthy();
    expect(
      logs.includes('PingOne Protect initialized by collector for data collection'),
    ).toBeFalsy();

    page.removeListener('console', (msg) => console.log(msg.text()));
  });

  test('Initialize by collector and evaluate risk', async ({ page }) => {
    const logs = [];
    page.on('console', async (msg) => {
      logs.push(msg.text());
      return Promise.resolve(true);
    });

    await page.goto(`${BASE_URL}/login?initProtect=flow&acrValue=${htmlFormAcrValue}`);
    await expect(page.getByText('JS Protect - Custom HTML Form')).toBeVisible();

    let riskData;
    page.on('request', (request) => {
      const method = request.method();
      const requestUrl = request.url();
      const payload = request.postDataJSON();

      // Only process POST requests with JSON payloads
      if (method === 'POST' && payload && requestUrl.includes('customHTMLTemplate')) {
        const data = payload.parameters?.data?.formData?.riskSDK;
        if (data) {
          riskData = data;
        }
      }
    });

    const protectPromise = page.waitForRequest(
      (req) =>
        req.method() === 'POST' &&
        req.url().includes('customHTMLTemplate') &&
        req.postDataJSON()?.parameters?.data?.formData?.riskSDK,
    );
    await page.getByLabel('Username').fill(username);
    await page.getByLabel('Password').fill(password);
    await page.getByRole('button', { name: 'Sign On' }).click();
    await protectPromise;

    expect(riskData).toBeDefined();
    expect(riskData).toMatch(/^R\/o\//);

    expect(logs.includes('Protect initialized at bootstrap for data collection')).toBeFalsy();
    expect(
      logs.includes('PingOne Protect initialized by collector for data collection'),
    ).toBeTruthy();

    page.removeListener('console', (msg) => console.log(msg.text()));
  });
});
