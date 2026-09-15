/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Runtime selection between the two modes these integration tests support.
///
/// **Hermetic (default).** No configuration, no network, no tenant. The suite starts a
/// [MockAmServer] in-process and points the SDK at loopback. This is what CI runs and what you get
/// from a bare `flutter test integration_test/`.
///
/// **Live.** Supplying `E2E_SERVER_URL` via `--dart-define` switches every dual-mode scenario over to
/// a real PingAM / PingOne Advanced Identity Cloud tenant:
///
/// ```sh
/// flutter test integration_test/ \
///   --dart-define=E2E_SERVER_URL=https://openam.example.com/openam \
///   --dart-define=E2E_USERNAME=testuser \
///   --dart-define=E2E_PASSWORD='…'
/// ```
///
/// Values arrive through `String.fromEnvironment`, which is compile-time — so credentials live in
/// your shell or your CI secret store and are never written to a file in this repository. That is
/// deliberate: this is a public samples repo, and the native SDKs make the same choice (Android
/// fills `assets/test_config.properties` from a CI secret; iOS commits a `Config.json` with
/// placeholders only).
///
/// Scenarios that can only be produced by a scripted server — the callback-mapping sweep, the
/// forced-failure case — skip themselves in live mode rather than pretend to pass.
abstract final class E2eConfig {
  /// Base URL of a real tenant. Non-empty means "run in live mode".
  static const serverUrl = String.fromEnvironment('E2E_SERVER_URL');

  /// Username for the live-mode login scenarios.
  static const username = String.fromEnvironment('E2E_USERNAME');

  /// Password for the live-mode login scenarios.
  static const password = String.fromEnvironment('E2E_PASSWORD');

  /// Realm to authenticate against. AM's default realm is `root`.
  static const realm = String.fromEnvironment(
    'E2E_REALM',
    defaultValue: 'root',
  );

  /// Name of the authentication tree/journey to start.
  static const journeyName = String.fromEnvironment(
    'E2E_JOURNEY',
    defaultValue: 'Login',
  );

  /// Name of the SSO session cookie. `iPlanetDirectoryPro` on self-hosted AM; AIC tenants use a
  /// per-tenant name, which is why this is configurable.
  static const cookieName = String.fromEnvironment(
    'E2E_COOKIE',
    defaultValue: 'iPlanetDirectoryPro',
  );

  /// OAuth 2.0 client id. Set this, [discoveryEndpoint], and [redirectUri] together to exercise the
  /// post-login token exchange against a live tenant.
  static const clientId = String.fromEnvironment('E2E_CLIENT_ID');

  /// Full OIDC discovery document URL — the SDK treats this as a complete URL and does not append
  /// `/.well-known/openid-configuration` for you.
  static const discoveryEndpoint = String.fromEnvironment(
    'E2E_DISCOVERY_ENDPOINT',
  );

  /// Redirect URI registered on the OAuth 2.0 client.
  static const redirectUri = String.fromEnvironment('E2E_REDIRECT_URI');

  /// Space-separated OAuth scopes.
  static const scopes = String.fromEnvironment(
    'E2E_SCOPES',
    defaultValue: 'openid profile email',
  );

  /// Whether the suite should talk to a real tenant instead of the in-process mock.
  static bool get isLive => serverUrl.isNotEmpty;

  /// Whether the suite runs against the in-process [MockAmServer].
  static bool get isHermetic => !isLive;

  /// Whether live-mode credentials were supplied.
  static bool get hasCredentials => username.isNotEmpty && password.isNotEmpty;

  /// Whether a full OAuth 2.0 client was supplied for live-mode token exchange.
  static bool get hasOidc =>
      clientId.isNotEmpty &&
      discoveryEndpoint.isNotEmpty &&
      redirectUri.isNotEmpty;

  /// [scopes] split into the list shape `JourneyConfigMessage` expects.
  static List<String> get scopeList =>
      scopes.split(' ').where((scope) => scope.isNotEmpty).toList();

  /// A reason to skip a scenario that requires live credentials, or `null` if it can run.
  ///
  /// `testWidgets`'s `skip:` parameter is `bool?`, not `dynamic` the way `package:test`'s `test()`
  /// is — it cannot carry an explanation. Check this at the top of the test body instead and call
  /// `markTestSkipped(reason)` when non-null, so the reason still shows up in the test report.
  static String? get liveCredentialsSkipReason {
    if (!isLive) return null;
    if (hasCredentials) return null;
    return 'Live mode is on (E2E_SERVER_URL is set) but E2E_USERNAME/E2E_PASSWORD are not. '
        'Supply both, or drop E2E_SERVER_URL to run hermetically.';
  }

  /// A reason to skip a scenario that only a scripted server can produce, or `null` if it can run.
  ///
  /// See [liveCredentialsSkipReason] for how to use this with `testWidgets`.
  static const hermeticOnlySkipReason =
      'Hermetic-only: this scenario needs a scripted server response that a real tenant will not '
      'produce on demand. Drop E2E_SERVER_URL to run it.';

  /// A one-line description of the active mode, for test names and failure output.
  static String get describe => isLive
      ? 'live mode against $serverUrl (realm $realm, journey $journeyName)'
      : 'hermetic mode against an in-process MockAmServer';
}
