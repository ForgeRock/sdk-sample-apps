/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Runtime selection between the two modes these integration tests support.
///
/// **Hermetic (default).** No configuration, no network, no tenant. The suite starts a
/// [MockDiscoveryServer] in-process and points [OidcConfig.discoveryEndpoint] at it. This is what
/// CI runs and what you get from a bare `flutter test integration_test/`.
///
/// **Live.** Supplying `E2E_CLIENT_ID` via `--dart-define` switches every scenario over to a real
/// OAuth 2.0 client on a real tenant:
///
/// ```sh
/// flutter test integration_test/ \
///   --dart-define=E2E_CLIENT_ID=my-client \
///   --dart-define=E2E_DISCOVERY_ENDPOINT=https://openam.example.com/oauth2/.well-known/openid-configuration \
///   --dart-define=E2E_REDIRECT_URI=com.example.app://oauthredirect
/// ```
///
/// Neither mode ever completes a login: [authorize] opens a system browser, which no scenario
/// here can drive, so nothing in this suite can exercise it. What both modes *can* exercise —
/// `configure`/`createWebClient`/`hasUser` succeeding, and `token`/`refresh`/`userInfo`/`revoke`/
/// `signOff` each failing with a "no session" [PingException] before any sign-in — needs no
/// completed login either way. Live mode exists so `configure`/`createWebClient` can be exercised
/// against a real discovery document at least once, ahead of the manual browser-login check that
/// `flutter/flutter-oidc`'s README calls for.
///
/// Values arrive through `String.fromEnvironment`, which is compile-time — so credentials live in
/// your shell or your CI secret store and are never written to a file in this repository. That is
/// deliberate: this is a public samples repo.
abstract final class E2eConfig {
  /// OAuth 2.0 client id for a real tenant. Non-empty means "run in live mode".
  static const clientId = String.fromEnvironment('E2E_CLIENT_ID');

  /// Full OIDC discovery document URL for the live-mode client. The SDK treats this as a complete
  /// URL and does not append `/.well-known/openid-configuration` for you.
  static const discoveryEndpoint = String.fromEnvironment(
    'E2E_DISCOVERY_ENDPOINT',
  );

  /// Redirect URI registered on the live-mode OAuth 2.0 client.
  static const redirectUri = String.fromEnvironment('E2E_REDIRECT_URI');

  /// Space-separated OAuth scopes.
  static const scopes = String.fromEnvironment(
    'E2E_SCOPES',
    defaultValue: 'openid profile email',
  );

  /// Whether the suite should configure against a real tenant instead of the in-process mock.
  static bool get isLive => clientId.isNotEmpty;

  /// Whether the suite runs against the in-process [MockDiscoveryServer].
  static bool get isHermetic => !isLive;

  /// Whether a complete live-mode client was supplied.
  static bool get hasCompleteConfig =>
      discoveryEndpoint.isNotEmpty && redirectUri.isNotEmpty;

  /// [scopes] split into the list shape [OidcConfig] expects.
  static List<String> get scopeList =>
      scopes.split(' ').where((scope) => scope.isNotEmpty).toList();

  /// A reason to skip a scenario that requires a complete live-mode config, or `null` if it can
  /// run.
  ///
  /// `testWidgets`'s `skip:` parameter is `bool?`, not `dynamic` the way `package:test`'s `test()`
  /// is — it cannot carry an explanation. Check this at the top of the test body instead and call
  /// `markTestSkipped(reason)` when non-null, so the reason still shows up in the test report.
  static String? get liveConfigSkipReason {
    if (!isLive) return null;
    if (hasCompleteConfig) return null;
    return 'Live mode is on (E2E_CLIENT_ID is set) but E2E_DISCOVERY_ENDPOINT/E2E_REDIRECT_URI '
        'are not. Supply both, or drop E2E_CLIENT_ID to run hermetically.';
  }

  /// A one-line description of the active mode, for test names and failure output.
  static String get describe => isLive
      ? 'live mode with client $clientId'
      : 'hermetic mode against an in-process MockDiscoveryServer';
}
