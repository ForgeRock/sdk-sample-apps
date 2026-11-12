/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';

/// Decodes the claims of a JWT, or returns `null` if [token] isn't one (an opaque access token,
/// for instance).
///
/// For display only: the signature is **not** verified, so never make a trust decision from the
/// result.
Map<String, Object?>? decodeJwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final claims = jsonDecode(payload);
    return claims is Map ? claims.cast<String, Object?>() : null;
  } on FormatException {
    return null;
  }
}
