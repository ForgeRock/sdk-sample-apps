/*
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 *
 */
import { test, expect } from '@playwright/test';

const BASE_URL = 'http://localhost:8443';
// TODO: replace with the acrValue for a DaVinci flow that emits an IMAGE field, once supplied
const imageFlowAcrValue = 'TBD';

// Skipped until a DaVinci flow policy ID that emits an IMAGE field is supplied (see SDKS-5102 open risk).
// Basic src/alt/hyperlink-wrapper rendering is already covered by the SDK repo's
// e2e/davinci-suites/src/form-image.test.ts against its own reference fixture.
// Once a real fixture is wired up, also assert the image's `src` (or another
// fixture-specific signal) to confirm this flow's IMAGE field carries an unsafe
// `output.href` — otherwise this no-anchor assertion passes just as well when
// `output.href` is absent entirely, and doesn't prove the unsafe-scheme rejection.
test.describe.skip('React - DaVinci Image Collector', () => {
  test('Does not wrap the image in a hyperlink when output.href uses an unsafe scheme', async ({
    page,
  }) => {
    await page.goto(`${BASE_URL}?acrValue=${imageFlowAcrValue}`);
    await page.getByRole('link', { name: 'Sign In', exact: true }).click();

    const image = page.getByTestId('form-image');
    await expect(image).toBeVisible();
    await expect(page.locator('a', { has: image })).toHaveCount(0);
  });
});
