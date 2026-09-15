/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';
import 'dart:io';

/// An in-process stand-in for an OIDC provider's discovery document.
///
/// Unlike `ping_journey`'s `MockAmServer`, this server exists to prove a *negative*: that
/// `OidcClient.configure`/`createWebClient`/`hasUser` never fetch this document at all. Native
/// discovery (`config.init()`) only runs lazily inside calls that need resolved endpoints —
/// `token`, `refresh`, `userInfo` — and every one of those first resolves a signed-in user, which
/// fails before touching the network when no session exists (see `OidcHostApiImpl.resolveUser`
/// on both platforms). Since no scenario here can complete a browser login, no scenario here can
/// ever legitimately cause a request to land on this server; [requests] being empty at the end of
/// a scenario is the assertion, not an afterthought.
///
/// Runs inside the test process **on the device**, bound to loopback on an OS-assigned port —
/// `127.0.0.1` is therefore correct on both the Android emulator and the iOS simulator, with no
/// `10.0.2.2` special case. Two narrowly-scoped platform permissions make plain HTTP to loopback
/// possible: `android/app/src/debug/res/xml/network_security_config.xml` and
/// `NSAllowsLocalNetworking` in `ios/Runner/Info.plist`.
class MockDiscoveryServer {
  MockDiscoveryServer._(this._server);

  final HttpServer _server;
  final List<String> _requests = <String>[];

  /// Starts a server on an OS-assigned loopback port, serving a syntactically-valid discovery
  /// document at `/.well-known/openid-configuration`.
  static Future<MockDiscoveryServer> start() async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = MockDiscoveryServer._(httpServer);
    httpServer.listen(server._handle);
    return server;
  }

  /// The base URL of this server, e.g. `http://127.0.0.1:54321`.
  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  /// The full URL to hand to `OidcConfig.discoveryEndpoint`. The native SDK treats this as a
  /// complete URL and does not append `/.well-known/openid-configuration` itself.
  String get discoveryEndpoint => '$baseUrl/.well-known/openid-configuration';

  /// Every request path this server has received, oldest first. Expected to stay empty for every
  /// scenario in this suite — see the class docs.
  List<String> get requests => List<String>.unmodifiable(_requests);

  /// Shuts the server down. Safe to pass straight to `addTearDown`.
  Future<void> stop() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    _requests.add('${request.method} ${request.uri.path}');

    final response = request.response;
    if (request.uri.path == '/.well-known/openid-configuration') {
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.json;
      response.write(
        jsonEncode(<String, Object?>{
          'issuer': baseUrl,
          'authorization_endpoint': '$baseUrl/oauth2/authorize',
          'token_endpoint': '$baseUrl/oauth2/access_token',
          'userinfo_endpoint': '$baseUrl/oauth2/userinfo',
          'end_session_endpoint': '$baseUrl/oauth2/connect/endSession',
          'revocation_endpoint': '$baseUrl/oauth2/token/revoke',
        }),
      );
    } else {
      response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  }
}
