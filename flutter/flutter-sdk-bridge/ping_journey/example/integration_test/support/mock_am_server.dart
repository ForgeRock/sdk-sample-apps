/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';
import 'dart:io';

/// An in-process stand-in for PingAM's authentication and OAuth 2.0 endpoints.
///
/// The server runs **inside the integration-test process, on the device**, bound to loopback on an
/// OS-assigned port. That placement matters: because both the client (the native Ping SDK) and the
/// server live in the same process, `127.0.0.1` resolves correctly on Android emulators and iOS
/// simulators alike — there is no `10.0.2.2` special-casing to get wrong. It does mean each platform
/// has to permit cleartext traffic to loopback; see
/// `android/app/src/debug/res/xml/network_security_config.xml` and the `NSAllowsLocalNetworking` key
/// in `ios/Runner/Info.plist`.
///
/// Usage is scripted rather than stateful: you hand [start] the sequence of responses the
/// `/authenticate` endpoint should return, one per request, and the server replays them in order.
/// That maps directly onto how a Journey progresses — first response is what `start()` sees, second
/// is what the first `next()` sees, and so on.
///
/// ```dart
/// final server = await MockAmServer.start(
///   authenticate: [
///     MockResponse.json(JourneyFixtures.usernamePasswordNode()),
///     MockResponse.json(JourneyFixtures.success()),
///   ],
/// );
/// addTearDown(server.stop);
/// ```
///
/// Every request is recorded in [requests] so tests can assert on the wire format the bridge
/// produces — the submitted `input` values, the `authIndexType`/`authIndexValue` parameters, the
/// `Accept-API-Version` header, the session cookie header on `next()`. When a request arrives for a
/// path with no handler, the server answers 404 with the full list of requests it has seen so far and
/// records the path in [unmatchedPaths]; [expectNoUnmatchedRequests] turns that into a readable test
/// failure. The first run against a new scenario almost always needs one wire-format adjustment, and
/// this is what makes that adjustment a single read rather than a bisect.
class MockAmServer {
  MockAmServer._(this._server, this._realm, this._authenticate, this._oidc);

  final HttpServer _server;
  final String _realm;
  final List<MockResponse> _authenticate;
  final MockOidc? _oidc;

  final List<RecordedRequest> _requests = <RecordedRequest>[];
  final List<String> _unmatchedPaths = <String>[];
  int _authenticateIndex = 0;

  /// Starts a server on an OS-assigned loopback port.
  ///
  /// [authenticate] is the ordered script of `/authenticate` responses (see the class docs).
  /// [realm] must match the `realm` on the `JourneyConfigMessage` under test — it is only used to
  /// build [authenticateUrl] for assertions; the handler itself matches any realm so that a realm
  /// mismatch shows up as a readable assertion rather than a 404.
  /// [oidc] enables the OAuth 2.0 endpoints; leave it `null` for a Journey-only (session-login)
  /// configuration, in which case any OIDC request is treated as unmatched and fails loudly.
  static Future<MockAmServer> start({
    List<MockResponse> authenticate = const <MockResponse>[],
    String realm = 'root',
    MockOidc? oidc,
  }) async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = MockAmServer._(
      httpServer,
      realm,
      List<MockResponse>.of(authenticate),
      oidc,
    );
    httpServer.listen(server._handle);
    return server;
  }

  /// The base URL to hand to `JourneyConfigMessage.serverUrl`, e.g. `http://127.0.0.1:54321`.
  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  /// The full URL to hand to `JourneyConfigMessage.discoveryEndpoint`.
  ///
  /// The native SDK treats `discoveryEndpoint` as a complete URL and does not append
  /// `/.well-known/openid-configuration` itself, so this includes the well-known suffix.
  String get discoveryEndpoint => '$baseUrl/.well-known/openid-configuration';

  /// The `/authenticate` URL for the realm this server was started with, for path assertions.
  String get authenticateUrl => '$baseUrl/json/realms/$_realm/authenticate';

  /// Every request received, oldest first.
  List<RecordedRequest> get requests =>
      List<RecordedRequest>.unmodifiable(_requests);

  /// Only the requests that hit the `/authenticate` endpoint, oldest first — index 0 is `start()`,
  /// index 1 the first `next()`, and so on.
  List<RecordedRequest> get authenticateRequests => _requests
      .where((request) => request.path.endsWith('/authenticate'))
      .toList(growable: false);

  /// Paths that arrived with no handler registered, in arrival order.
  List<String> get unmatchedPaths => List<String>.unmodifiable(_unmatchedPaths);

  /// Number of scripted `/authenticate` responses not yet consumed.
  int get remainingAuthenticateResponses =>
      _authenticate.length - _authenticateIndex;

  /// Throws a [StateError] describing every request received if any of them went unhandled.
  ///
  /// Call this at the end of a scenario. An unmatched path almost always means the SDK's wire
  /// format differs from what this harness assumes, and the message carries the evidence needed to
  /// fix the fixture in one pass.
  void expectNoUnmatchedRequests() {
    if (_unmatchedPaths.isEmpty) return;
    throw StateError(
      'MockAmServer received ${_unmatchedPaths.length} request(s) it had no handler for:\n'
      '  ${_unmatchedPaths.join('\n  ')}\n'
      'Full request log:\n$requestLog',
    );
  }

  /// A human-readable dump of every recorded request, for failure messages.
  String get requestLog =>
      _requests.map((request) => '  ${request.summary}').join('\n');

  /// Shuts the server down. Safe to pass straight to `addTearDown`.
  Future<void> stop() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final recorded = RecordedRequest(
      method: request.method,
      path: request.uri.path,
      query: Map<String, String>.of(request.uri.queryParameters),
      headers: _collectHeaders(request.headers),
      body: body,
    );
    _requests.add(recorded);

    final response = _responseFor(recorded);
    if (response == null) {
      _unmatchedPaths.add('${recorded.method} ${recorded.path}');
      await _write(
        request,
        MockResponse.json(<String, Object?>{
          'error': 'no handler registered',
          'method': recorded.method,
          'path': recorded.path,
          'receivedSoFar': _requests.map((r) => r.summary).toList(),
        }, status: HttpStatus.notFound),
      );
      return;
    }
    await _write(request, response);
  }

  MockResponse? _responseFor(RecordedRequest request) {
    final path = request.path;

    if (path.endsWith('/authenticate')) {
      if (_authenticateIndex >= _authenticate.length) {
        return MockResponse.json(<String, Object?>{
          'error': 'authenticate script exhausted',
          'scripted': _authenticate.length,
          'received': _authenticateIndex + 1,
          'receivedSoFar': _requests.map((r) => r.summary).toList(),
        }, status: HttpStatus.internalServerError);
      }
      return _authenticate[_authenticateIndex++];
    }

    // AM session logout. Answered unconditionally: `signOff()` is a fire-and-forget teardown in
    // most scenarios and a 404 here would mask the assertion the test actually cares about.
    if (path.endsWith('/sessions')) {
      return MockResponse.json(<String, Object?>{
        'result': 'Successfully logged out',
      });
    }

    final oidc = _oidc;
    if (oidc == null) return null;

    switch (path) {
      case '/.well-known/openid-configuration':
        // Exactly the five endpoints iOS's `OpenIdConfiguration` declares non-optional — a missing
        // one fails `Codable` decoding outright, while Android defaults every field to `""` and would
        // not notice. Deliberately advertises nothing it does not route: the device-code and PAR
        // endpoints are omitted so that enabling either feature fails loudly here rather than
        // silently sending the SDK to a path this mock answers with a 404.
        return MockResponse.json(<String, Object?>{
          'issuer': baseUrl,
          'authorization_endpoint': '$baseUrl/oauth2/authorize',
          'token_endpoint': '$baseUrl/oauth2/access_token',
          'userinfo_endpoint': '$baseUrl/oauth2/userinfo',
          'end_session_endpoint': '$baseUrl/oauth2/connect/endSession',
          'revocation_endpoint': '$baseUrl/oauth2/token/revoke',
        });

      case '/oauth2/authorize':
        // The Journey OIDC agent performs a *headless* authorize: it sends the SSO session cookie
        // as a request header and expects a 302 whose Location carries the authorization code. It
        // never opens a browser, which is exactly why these tests can run without UI.
        final state = request.query['state'];
        final redirect = StringBuffer(
          '${oidc.redirectUri}?code=${oidc.authCode}',
        );
        if (state != null && state.isNotEmpty) redirect.write('&state=$state');
        return MockResponse.raw(
          '',
          status: HttpStatus.found,
          headers: <String, String>{'Location': redirect.toString()},
        );

      case '/oauth2/access_token':
        return MockResponse.json(oidc.token);

      case '/oauth2/userinfo':
        return MockResponse.json(oidc.userInfo);

      case '/oauth2/connect/endSession':
      case '/oauth2/token/revoke':
        return MockResponse.raw('', status: HttpStatus.ok);
    }
    return null;
  }

  Future<void> _write(HttpRequest request, MockResponse response) async {
    final httpResponse = request.response
      ..statusCode = response.status
      ..headers.contentType = ContentType.parse(response.contentType);
    response.headers.forEach(httpResponse.headers.set);
    httpResponse.write(response.body);
    await httpResponse.close();
  }

  static Map<String, String> _collectHeaders(HttpHeaders headers) {
    final collected = <String, String>{};
    headers.forEach(
      (name, values) => collected[name.toLowerCase()] = values.join(', '),
    );
    return collected;
  }
}

/// A canned HTTP response for [MockAmServer].
class MockResponse {
  const MockResponse.raw(
    this.body, {
    this.status = HttpStatus.ok,
    this.contentType = 'text/plain; charset=utf-8',
    this.headers = const <String, String>{},
  });

  /// A JSON response. [body] is anything `jsonEncode` accepts — typically a `Map<String, Object?>`
  /// from [JourneyFixtures].
  MockResponse.json(Object body, {this.status = HttpStatus.ok})
    : body = jsonEncode(body),
      contentType = 'application/json; charset=utf-8',
      headers = const <String, String>{};

  /// The serialized response body.
  final String body;

  /// The HTTP status code to return.
  final int status;

  /// The `Content-Type` header value.
  final String contentType;

  /// Extra response headers (e.g. `Location` on a redirect).
  final Map<String, String> headers;
}

/// Configuration for [MockAmServer]'s OAuth 2.0 endpoints.
///
/// [redirectUri] must match the `redirectUri` on the `JourneyConfigMessage` under test — the native
/// SDK only reads the `code` parameter off the `Location` header, but keeping them aligned means the
/// mock exercises the same shape the real server produces.
class MockOidc {
  MockOidc({
    required this.redirectUri,
    this.authCode = 'mock-authorization-code',
    Map<String, Object?>? token,
    Map<String, Object?>? userInfo,
  }) : token = token ?? defaultToken,
       userInfo = userInfo ?? defaultUserInfo;

  /// The redirect URI echoed back on the authorize redirect.
  final String redirectUri;

  /// The authorization code handed back on the authorize redirect.
  final String authCode;

  /// The `/access_token` response body.
  final Map<String, Object?> token;

  /// The `/userinfo` response body.
  final Map<String, Object?> userInfo;

  /// A minimal RFC 6749 token response. `expires_in` is deliberately long so a slow test run can't
  /// trip the SDK's refresh path mid-assertion.
  static const Map<String, Object?> defaultToken = <String, Object?>{
    'access_token': 'mock-access-token',
    'refresh_token': 'mock-refresh-token',
    'token_type': 'Bearer',
    'scope': 'openid profile email',
    'expires_in': 3599,
  };

  /// A minimal userinfo response.
  static const Map<String, Object?> defaultUserInfo = <String, Object?>{
    'sub': 'mock-subject',
    'name': 'Mock User',
    'given_name': 'Mock',
    'family_name': 'User',
    'email': 'mock.user@example.com',
  };
}

/// One request as observed by [MockAmServer].
class RecordedRequest {
  /// Creates a record of a received request.
  RecordedRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.headers,
    required this.body,
  });

  /// HTTP method, e.g. `POST`.
  final String method;

  /// Request path, without the query string.
  final String path;

  /// Decoded query parameters.
  final Map<String, String> query;

  /// Request headers, lower-cased names, multi-values joined with `, `.
  final Map<String, String> headers;

  /// The raw request body.
  final String body;

  /// The body decoded as a JSON object, or `null` if it isn't one.
  Map<String, Object?>? get json {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    }
  }

  /// The `callbacks` array from a submitted `/authenticate` body.
  List<Map<String, Object?>> get callbacks {
    final callbacks = json?['callbacks'];
    if (callbacks is! List) return const <Map<String, Object?>>[];
    return callbacks
        .whereType<Map>()
        .map((callback) => callback.cast<String, Object?>())
        .toList(growable: false);
  }

  /// The submitted `input` values for the callback at [index], keyed by input name
  /// (`IDToken1`, `IDToken2`, …).
  Map<String, Object?> inputValues(int index) {
    if (index >= callbacks.length) return const <String, Object?>{};
    final input = callbacks[index]['input'];
    if (input is! List) return const <String, Object?>{};
    return <String, Object?>{
      for (final entry in input.whereType<Map>())
        '${entry['name']}': entry['value'],
    };
  }

  /// A one-line description used in failure messages.
  String get summary {
    final queryString = query.isEmpty
        ? ''
        : '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final bodyPreview = body.isEmpty
        ? ''
        : ' body=${body.length > 400 ? '${body.substring(0, 400)}…' : body}';
    return '$method $path$queryString$bodyPreview';
  }
}
