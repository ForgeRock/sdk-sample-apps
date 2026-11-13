/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// The session of a completed DaVinci flow: the OAuth **authorization code** from
/// `SuccessNode.session`, returned by `DaVinciClient.getSession()`.
///
/// **This is not a token-bearing session.** Unlike `ping_journey`'s `Session`, which carries
/// access and refresh tokens, a DaVinci session holds only the code PingOne issued at the end of
/// the flow. The native SDK has already redeemed it, or will on the first
/// `DaVinciClient.getToken()` (Android exchanges it as soon as the flow succeeds, iOS on first
/// use), so the code is spent: don't send it anywhere to exchange it yourself. For tokens, call
/// `DaVinciClient.getToken()`; for claims, `DaVinciClient.getUserInfo()`.
class DaVinciSession {
  /// Creates a session from its authorization code.
  const DaVinciSession({required this.authorizationCode});

  /// The OAuth authorization code issued at the end of the flow.
  final String authorizationCode;

  /// Parses a JSON-shaped map. Throws [FormatException] unless `authorizationCode` is a
  /// non-empty string.
  factory DaVinciSession.fromJson(Map<String, Object?> json) {
    final authorizationCode = json['authorizationCode'];
    if (authorizationCode is! String || authorizationCode.isEmpty) {
      throw const FormatException(
        'DaVinciSession.authorizationCode must be a non-empty string',
      );
    }
    return DaVinciSession(authorizationCode: authorizationCode);
  }

  /// Serializes this session back to a JSON-shaped map.
  Map<String, Object?> toJson() => {'authorizationCode': authorizationCode};
}
