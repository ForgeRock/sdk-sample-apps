/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_oidc/ping_oidc.dart';

import 'mock_discovery_server.dart';
import 'test_config.dart';

/// A configured [OidcClient] plus whatever backs it, so a scenario reads the same whether it is
/// configured against the in-process [MockDiscoveryServer] or a real tenant.
///
/// Construct with [start] and let it pick the mode from [E2eConfig]; the redirect URI is never
/// registered anywhere on purpose, since no scenario in this suite drives [OidcClient.authorize]
/// — that call opens a system browser, which nothing here can complete. Call [dispose] (or
/// `addTearDown(harness.dispose)`) to release the native client and shut the mock down.
class OidcHarness {
  OidcHarness._({required this.client, required this.server});

  /// The client under test.
  final OidcClient client;

  /// The mock server backing [client], or `null` in live mode.
  final MockDiscoveryServer? server;

  /// The redirect URI used by the hermetic client. Registered nowhere — see the class docs.
  static const hermeticRedirectUri = 'pingoidcexample://oauth2redirect';

  /// Client id used by the hermetic client. The mock never checks it.
  static const hermeticClientId = 'mock-client-id';

  /// Builds a harness for the active mode.
  static Future<OidcHarness> start() async {
    if (E2eConfig.isLive) {
      return OidcHarness._(
        client: await OidcClient.configure(_liveConfig()),
        server: null,
      );
    }

    final server = await MockDiscoveryServer.start();
    return OidcHarness._(
      client: await OidcClient.configure(_hermeticConfig(server)),
      server: server,
    );
  }

  /// Whether this harness is backed by the in-process mock.
  bool get isHermetic => server != null;

  /// The mock server, asserting that we are in hermetic mode. Use inside `if (harness.isHermetic)`
  /// blocks.
  MockDiscoveryServer get mock {
    final server = this.server;
    if (server == null) {
      fail(
        'OidcHarness.mock was read in live mode. Guard mock-only assertions with '
        '`if (harness.isHermetic)`.',
      );
    }
    return server;
  }

  /// Releases the native client and stops the mock server, in that order.
  Future<void> dispose() async {
    await client.dispose();
    await server?.stop();
  }

  static OidcConfig _hermeticConfig(MockDiscoveryServer server) => OidcConfig(
    clientId: hermeticClientId,
    discoveryEndpoint: server.discoveryEndpoint,
    redirectUri: hermeticRedirectUri,
    scopes: const ['openid', 'profile', 'email'],
  );

  static OidcConfig _liveConfig() => OidcConfig(
    clientId: E2eConfig.clientId,
    discoveryEndpoint: E2eConfig.discoveryEndpoint,
    redirectUri: E2eConfig.redirectUri,
    scopes: E2eConfig.scopeList,
  );
}
