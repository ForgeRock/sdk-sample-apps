/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/**
 * Extracts the `user_code` query parameter from an RFC 8628
 * `verification_uri_complete` string.
 *
 * @param uri - Verification URI, with or without the `user_code` parameter.
 * @returns The decoded user code, or `undefined` if `uri` carries none.
 */
export function extractUserCode(uri: string): string | undefined {
  const match = /(?:\?|&)user_code=([^&]+)/i.exec(uri);
  return match ? decodeURIComponent(match[1]) : undefined;
}
