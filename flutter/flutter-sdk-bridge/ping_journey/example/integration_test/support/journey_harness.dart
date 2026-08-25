/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';

import 'mock_am_server.dart';
import 'test_config.dart';

/// A configured [JourneyClient] plus whatever backs it, so a scenario reads the same whether it is
/// talking to the in-process [MockAmServer] or a real tenant.
///
/// Construct with [start] and let it pick the mode from [E2eConfig]; the `authenticate` script is
/// simply ignored in live mode. Call [dispose] (or `addTearDown(harness.dispose)`) to release the
/// native `Journey` and shut the mock down.
///
/// The `expect*` helpers here exist because a node-type mismatch is the single most common way these
/// tests fail, and the useful evidence — what the SDK actually put on the wire — lives in the mock's
/// request log. Reaching for `expect(node, isA<SuccessNode>())` throws that evidence away;
/// [expectSuccess] and friends attach it to the failure message.
class JourneyHarness {
  JourneyHarness._({
    required this.client,
    required this.server,
    required this.journeyName,
    required this.username,
    required this.password,
  });

  /// The client under test.
  final JourneyClient client;

  /// The mock server backing [client], or `null` in live mode.
  final MockAmServer? server;

  /// The Journey to pass to `JourneyClient.start`.
  final String journeyName;

  /// The username the scenario should submit.
  final String username;

  /// The password the scenario should submit.
  final String password;

  /// The redirect URI used by the hermetic OAuth 2.0 client. Registered nowhere on purpose — the
  /// Journey OIDC flow is headless, so nothing ever needs to resolve this scheme.
  static const hermeticRedirectUri = 'pingjourneyexample://oauth2redirect';

  /// Credentials the mock accepts. It does not actually check them; these exist so assertions on the
  /// submitted payload have something concrete to match.
  static const hermeticUsername = 'mockuser';

  /// See [hermeticUsername].
  static const hermeticPassword = 'mock-password';

  /// Builds a harness for the active mode.
  ///
  /// [authenticate] scripts the mock's `/authenticate` responses in order and is ignored when
  /// running live. [oidc] adds an OAuth 2.0 client to the configuration, which is what makes
  /// `JourneyClient.user()` return a session — without it the native bridge returns `null` by
  /// design, because a Journey-only configuration has no tokens to hand back.
  static Future<JourneyHarness> start({
    List<MockResponse> authenticate = const <MockResponse>[],
    bool oidc = false,
  }) async {
    if (E2eConfig.isLive) {
      return JourneyHarness._(
        client: await JourneyClient.configure(_liveConfig(oidc: oidc)),
        server: null,
        journeyName: E2eConfig.journeyName,
        username: E2eConfig.username,
        password: E2eConfig.password,
      );
    }

    final server = await MockAmServer.start(
      authenticate: authenticate,
      oidc: oidc ? MockOidc(redirectUri: hermeticRedirectUri) : null,
    );
    return JourneyHarness._(
      client: await JourneyClient.configure(
        _hermeticConfig(server, oidc: oidc),
      ),
      server: server,
      journeyName: 'Login',
      username: hermeticUsername,
      password: hermeticPassword,
    );
  }

  /// Whether this harness is backed by the in-process mock.
  bool get isHermetic => server != null;

  /// The mock server, asserting that we are in hermetic mode. Use inside `if (harness.isHermetic)`
  /// blocks, or in tests marked `skip: E2eConfig.hermeticOnlySkipReason` when live.
  MockAmServer get mock {
    final server = this.server;
    if (server == null) {
      fail(
        'JourneyHarness.mock was read in live mode. Guard the wire assertions with '
        '`if (harness.isHermetic)`, or skip the test with E2eConfig.hermeticOnlySkipReason.',
      );
    }
    return server;
  }

  /// Copies [username]/[password] into whichever credential callbacks [node] carries.
  ///
  /// Covers the plain and validated variants, which is enough for both the mock's login page and the
  /// stock AM `Login` tree. Returns the number of callbacks it filled so a caller can assert the node
  /// was what it expected.
  int fillCredentials(ContinueNode node) {
    var filled = 0;
    for (final callback in node.callbacks) {
      if (callback is NameCallback) {
        callback.name = username;
        filled++;
      } else if (callback is PasswordCallback) {
        callback.password = password;
        filled++;
      } else if (callback is ValidatedUsernameCallback) {
        callback.username = username;
        filled++;
      } else if (callback is ValidatedPasswordCallback) {
        callback.password = password;
        filled++;
      }
    }
    return filled;
  }

  /// Asserts [node] is a [ContinueNode] and returns it, attaching the request log on failure.
  ContinueNode expectContinue(JourneyNode node) =>
      _expect<ContinueNode>(node, 'ContinueNode');

  /// Asserts [node] is a [SuccessNode] and returns it, attaching the request log on failure.
  SuccessNode expectSuccess(JourneyNode node) =>
      _expect<SuccessNode>(node, 'SuccessNode');

  /// Asserts [node] is an [ErrorNode] and returns it, attaching the request log on failure.
  ErrorNode expectError(JourneyNode node) => _expect<ErrorNode>(node, 'ErrorNode');

  /// Asserts [node] is a [FailureNode] and returns it, attaching the request log on failure.
  FailureNode expectFailure(JourneyNode node) =>
      _expect<FailureNode>(node, 'FailureNode');

  T _expect<T extends JourneyNode>(JourneyNode node, String expected) {
    if (node is T) return node;
    fail(
      'Expected $expected but got ${_describe(node)}.\n'
      'Mode: ${E2eConfig.describe}.'
      '${server == null ? '' : '\nRequests seen by the mock server:\n${server!.requestLog}'}',
    );
  }

  static String _describe(JourneyNode node) => switch (node) {
    ContinueNode(:final callbacks) =>
      'ContinueNode with ${callbacks.length} callback(s) '
          '(${callbacks.map((c) => c.type).join(', ')})',
    SuccessNode() => 'SuccessNode',
    ErrorNode(:final message, :final status) =>
      'ErrorNode(status: $status, message: "$message")',
    FailureNode(:final cause) => 'FailureNode(cause: "$cause")',
  };

  /// Releases the native `Journey` and stops the mock server, in that order.
  Future<void> dispose() async {
    await client.dispose();
    await server?.stop();
  }

  static JourneyConfigMessage _hermeticConfig(
    MockAmServer server, {
    required bool oidc,
  }) => JourneyConfigMessage(
    serverUrl: server.baseUrl,
    realm: 'root',
    cookie: 'iPlanetDirectoryPro',
    timeoutMillis: 30000,
    clientId: oidc ? 'mock-client-id' : null,
    discoveryEndpoint: oidc ? server.discoveryEndpoint : null,
    redirectUri: oidc ? hermeticRedirectUri : null,
    scopes: oidc ? const <String>['openid', 'profile', 'email'] : null,
  );

  static JourneyConfigMessage _liveConfig({required bool oidc}) =>
      JourneyConfigMessage(
        serverUrl: E2eConfig.serverUrl,
        realm: E2eConfig.realm,
        cookie: E2eConfig.cookieName,
        timeoutMillis: 30000,
        clientId: oidc ? _requireOidc(E2eConfig.clientId) : null,
        discoveryEndpoint: oidc
            ? _requireOidc(E2eConfig.discoveryEndpoint)
            : null,
        redirectUri: oidc ? _requireOidc(E2eConfig.redirectUri) : null,
        scopes: oidc ? E2eConfig.scopeList : null,
      );

  static String _requireOidc(String value) {
    if (value.isNotEmpty) return value;
    fail(
      'This scenario needs an OAuth 2.0 client in live mode. Supply E2E_CLIENT_ID, '
      'E2E_DISCOVERY_ENDPOINT, and E2E_REDIRECT_URI, or drop E2E_SERVER_URL to run hermetically.',
    );
  }
}
