/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';
import 'dart:io';

/// An in-process OAuth 2.0 provider that completes a browser authorize with no UI interaction.
///
/// `/oauth2/authorize` answers with a `302` straight to [redirectUri] (code + echoed `state`), so
/// the system browser hands control back to the app immediately. It serves no discovery document:
/// `/.well-known/openid-configuration` returns `500` and is recorded, so a scenario can assert
/// discovery was never attempted. Binds to loopback on the device, like [MockDiscoveryServer].
class MockOidcProvider {
  MockOidcProvider._(this._server, this.redirectUri);

  final HttpServer _server;
  final List<ProviderRequest> _requests = <ProviderRequest>[];

  /// Where `/oauth2/authorize` redirects to. On Android its scheme must match the test host's
  /// `appRedirectUriScheme` placeholder.
  final String redirectUri;

  /// The authorization code `/oauth2/authorize` hands back.
  static const authorizationCode = 'mock-authorization-code';

  /// The `/oauth2/access_token` response body. Long `expires_in` keeps refresh out of the way.
  static const Map<String, Object?> token = <String, Object?>{
    'access_token': 'mock-access-token',
    'refresh_token': 'mock-refresh-token',
    'token_type': 'Bearer',
    'scope': 'openid profile email',
    'expires_in': 3599,
  };

  /// The `/oauth2/userinfo` response body.
  static const Map<String, Object?> userInfo = <String, Object?>{
    'sub': 'mock-subject',
    'email': 'mock.user@example.com',
  };

  /// Starts the provider on an OS-assigned loopback port.
  static Future<MockOidcProvider> start({required String redirectUri}) async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final provider = MockOidcProvider._(httpServer, redirectUri);
    httpServer.listen(provider._handle);
    return provider;
  }

  /// The base URL of this server, e.g. `http://127.0.0.1:54321`.
  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  /// The authorization endpoint to configure explicitly.
  String get authorizationEndpoint => '$baseUrl/oauth2/authorize';

  /// The token endpoint to configure explicitly.
  String get tokenEndpoint => '$baseUrl/oauth2/access_token';

  /// The userinfo endpoint to configure explicitly.
  String get userinfoEndpoint => '$baseUrl/oauth2/userinfo';

  /// The end-session endpoint to configure explicitly.
  String get endSessionEndpoint => '$baseUrl/oauth2/connect/endSession';

  /// The revocation endpoint to configure explicitly.
  String get revocationEndpoint => '$baseUrl/oauth2/token/revoke';

  /// Every request received, oldest first.
  List<ProviderRequest> get requests =>
      List<ProviderRequest>.unmodifiable(_requests);

  /// Requests whose path is [path].
  Iterable<ProviderRequest> requestsTo(String path) =>
      _requests.where((request) => request.path == path);

  /// A readable dump of [requests], for assertion failure messages.
  String get requestLog => _requests.isEmpty
      ? '  (none)'
      : _requests.map((request) => '  $request').join('\n');

  /// Shuts the server down. Safe to pass straight to `addTearDown`.
  Future<void> stop() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    _requests.add(
      ProviderRequest(
        method: request.method,
        path: request.uri.path,
        query: request.uri.queryParameters,
        body: body,
      ),
    );

    final response = request.response;
    switch (request.uri.path) {
      case '/oauth2/authorize':
        final redirect = Uri.parse(redirectUri).replace(
          queryParameters: <String, String>{
            'code': authorizationCode,
            'state': ?request.uri.queryParameters['state'],
          },
        );
        response.statusCode = HttpStatus.found;
        response.headers.set(HttpHeaders.locationHeader, redirect.toString());
      case '/oauth2/access_token':
        _json(response, token);
      case '/oauth2/userinfo':
        _json(response, userInfo);
      case '/oauth2/connect/endSession':
      case '/oauth2/token/revoke':
        response.statusCode = HttpStatus.ok;
      default:
        // Includes discovery: a 500 makes any attempt fail loudly.
        response.statusCode = HttpStatus.internalServerError;
    }
    await response.close();
  }

  static void _json(HttpResponse response, Map<String, Object?> body) {
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
  }
}

/// One request as observed by [MockOidcProvider].
class ProviderRequest {
  /// Creates a record of a received request.
  ProviderRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.body,
  });

  /// The HTTP method.
  final String method;

  /// The request path, without query.
  final String path;

  /// The decoded query parameters.
  final Map<String, String> query;

  /// The raw request body (empty for a GET).
  final String body;

  @override
  String toString() => '$method $path';
}
