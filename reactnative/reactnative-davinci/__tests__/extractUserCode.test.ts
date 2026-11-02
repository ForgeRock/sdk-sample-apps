/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { extractUserCode } from '../ui/utils/extractUserCode';

describe('extractUserCode', () => {
  test('extracts user_code as the only query parameter', () => {
    expect(
      extractUserCode('https://example.com/device?user_code=WDJB-MJHT'),
    ).toBe('WDJB-MJHT');
  });

  test('extracts user_code when it is not the first query parameter', () => {
    expect(
      extractUserCode(
        'https://example.com/device?client_id=abc&user_code=WDJB-MJHT',
      ),
    ).toBe('WDJB-MJHT');
  });

  test('decodes a URL-encoded value', () => {
    expect(
      extractUserCode('https://example.com/device?user_code=WD%2DMJHT'),
    ).toBe('WD-MJHT');
  });

  test('returns undefined when user_code is absent', () => {
    expect(
      extractUserCode('https://example.com/device?client_id=abc'),
    ).toBeUndefined();
  });

  test('returns undefined for a blank string', () => {
    expect(extractUserCode('')).toBeUndefined();
  });

  test('does not match the unrelated camelCase userCode parameter', () => {
    expect(
      extractUserCode(
        'https://auth.pingone.ca/env/applications/client/deviceFlow?userCode=WDJB-MJHT',
      ),
    ).toBeUndefined();
  });
});
