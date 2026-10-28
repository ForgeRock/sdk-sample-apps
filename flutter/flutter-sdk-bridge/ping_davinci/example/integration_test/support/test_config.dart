/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Runtime selection between the two modes these integration tests support.
///
/// **Hermetic (default).** No configuration, no network, no tenant. Scenarios start a
/// `MockDaVinciServer` in-process and point the SDK at loopback. This is what CI runs and what you
/// get from a bare `flutter test integration_test/`.
///
/// **Live.** DaVinci has no `serverUrl`, so live mode switches on when both `E2E_DISCOVERY_ENDPOINT`
/// and `E2E_CLIENT_ID` are supplied. The non-secret tenant values live in the gitignored
/// `flutter/.env`:
///
/// ```sh
/// flutter test integration_test/ --dart-define-from-file=../../../.env
/// ```
///
/// The sign-on scenario additionally needs `E2E_USERNAME`/`E2E_PASSWORD`, from your shell, never a
/// file:
///
/// ```sh
/// flutter test integration_test/ --dart-define-from-file=../../../.env \
///   --dart-define=E2E_USERNAME="$E2E_USERNAME" --dart-define=E2E_PASSWORD="$E2E_PASSWORD"
/// ```
///
/// Values arrive through `String.fromEnvironment`, which is compile-time, so nothing is written
/// into this public repository.
abstract final class E2eConfig {
  /// Full OIDC discovery document URL.
  static const discoveryEndpoint = String.fromEnvironment(
    'E2E_DISCOVERY_ENDPOINT',
  );

  /// OAuth 2.0 client id.
  static const clientId = String.fromEnvironment('E2E_CLIENT_ID');

  /// Redirect URI registered on the OAuth 2.0 client.
  static const redirectUri = String.fromEnvironment('E2E_REDIRECT_URI');

  /// OAuth scopes, comma- or space-separated (`.env` uses commas).
  static const scopes = String.fromEnvironment(
    'E2E_SCOPES',
    defaultValue: 'openid',
  );

  /// The `acr_values` that select the form-fields flow, whose first node is a menu.
  static const acrFormFields = String.fromEnvironment('E2E_ACR_FORM_FIELDS');

  /// The `acr_values` that select the single-sign-on flow, whose first node is a sign-on form.
  static const acrSso = String.fromEnvironment('E2E_ACR_SSO');

  /// The `acr_values` that select the polling flow, whose first node is a menu.
  static const acrPolling = String.fromEnvironment('E2E_ACR_POLLING');

  /// The `acr_values` that select the metadata / image / QR code flow, whose first node is a menu.
  static const acrMetadataImage = String.fromEnvironment(
    'E2E_ACR_METADATA_IMAGE',
  );

  /// The `acr_values` that select the MFA device flow, whose first node is a menu.
  static const acrMfaDevice = String.fromEnvironment('E2E_ACR_MFA_DEVICE');

  /// A user of the live tenant, for the scenarios that sign in.
  static const username = String.fromEnvironment('E2E_USERNAME');

  /// [username]'s password.
  static const password = String.fromEnvironment('E2E_PASSWORD');

  /// Whether the suite should talk to a real tenant instead of the in-process mock.
  static bool get isLive => discoveryEndpoint.isNotEmpty && clientId.isNotEmpty;

  /// Whether the suite runs against the in-process `MockDaVinciServer`.
  static bool get isHermetic => !isLive;

  /// [scopes] split into the list shape `DaVinciConfigMessage` expects.
  static List<String> get scopeList => scopes
      .split(RegExp(r'[ ,]+'))
      .where((scope) => scope.isNotEmpty)
      .toList();

  /// A reason to skip a scenario that live mode can't run, or `null` if it can run.
  ///
  /// `testWidgets`'s `skip:` is a `bool?` and can't carry an explanation, so check this at the top
  /// of the test body and call `markTestSkipped(reason)` when it is non-null.
  static String? get liveConfigSkipReason {
    if (isHermetic) return null;
    if (redirectUri.isEmpty || acrFormFields.isEmpty) {
      return 'Live mode is on but E2E_REDIRECT_URI or E2E_ACR_FORM_FIELDS is missing. Pass '
          '--dart-define-from-file=<flutter/.env>, or drop the defines to run hermetically.';
    }
    return null;
  }

  /// Like [liveConfigSkipReason], for a scenario that runs the SSO flow without signing in.
  static String? get liveSsoSkipReason {
    if (isHermetic) return null;
    if (redirectUri.isEmpty || acrSso.isEmpty) {
      return 'Live mode is on but E2E_REDIRECT_URI or E2E_ACR_SSO is missing. Pass '
          '--dart-define-from-file=<flutter/.env>, or drop the defines to run hermetically.';
    }
    return null;
  }

  /// Like [liveConfigSkipReason], for a scenario that runs the flow [acr] selects; [name] is
  /// its `.env` key, for the message.
  static String? liveFlowSkipReason(String acr, String name) {
    if (isHermetic) return null;
    if (redirectUri.isEmpty || acr.isEmpty) {
      return 'Live mode is on but E2E_REDIRECT_URI or $name is missing. Pass '
          '--dart-define-from-file=<flutter/.env>, or drop the defines to run hermetically.';
    }
    return null;
  }

  /// Like [liveConfigSkipReason], for a scenario that signs in to the SSO flow in live mode.
  static String? get liveSignOnSkipReason {
    final ssoReason = liveSsoSkipReason;
    if (ssoReason != null) return ssoReason;
    if (isLive && (username.isEmpty || password.isEmpty)) {
      return 'Signing in live needs E2E_USERNAME and E2E_PASSWORD from your shell.';
    }
    return null;
  }

  /// A one-line description of the active mode, for failure output.
  static String get describe => isLive
      ? 'live mode against $discoveryEndpoint'
      : 'hermetic mode against an in-process MockDaVinciServer';
}
