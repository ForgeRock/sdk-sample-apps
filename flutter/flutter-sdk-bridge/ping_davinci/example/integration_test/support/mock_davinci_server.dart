/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';
import 'dart:io';

/// An in-process stand-in for PingOne's OIDC endpoints and the DaVinci flow protocol.
///
/// The server runs **inside the integration-test process, on the device**, bound to loopback on an
/// OS-assigned port, so `127.0.0.1` is correct on Android emulators and iOS simulators alike — no
/// `10.0.2.2`. The test host permits cleartext to loopback only (see `example/README.md`).
///
/// The DaVinci protocol, as the native SDKs speak it:
/// - `start()` fetches discovery, then GETs the authorization endpoint with
///   `response_mode=pi.flow`; the JSON response is the first node.
/// - `next()` POSTs JSON to the current node's `_links.next.href`; the response is the next node.
/// - A response carrying `authorizeResponse.code` becomes a `SuccessNode`, after which the OIDC
///   module exchanges the code at the token endpoint (Android at once, iOS on the first `token()`).
///   Like PingOne, the server sets the [sessionCookie] on that response. Android's `DaVinci.user()`
///   is null without it, and both SDKs delete it on `signOff()`.
///
/// [start] takes the [flow] script: the authorize response, then one response per `next()`. Captured
/// nodes link `next` to a `/davinci/` path on this server, and any POST to such a path takes the
/// next scripted response — except the challenge-status endpoint a challenge-mode
/// `PollingCollector` polls (`…/davinci/user/credentials/challenge/{challenge}/status`), which
/// takes the next [challengeStatus] response instead, repeating the last once it runs out. A script entry is a JSON body answered `200`, or a [MockResponse] for
/// any other status. Every request is recorded in [requests]; one with no handler is answered
/// 404 and recorded in [unmatchedPaths], which [expectNoUnmatchedRequests] turns into a readable
/// failure.
class MockDaVinciServer {
  MockDaVinciServer._(this._server, this._flow, this._challengeStatus);

  final HttpServer _server;
  final List<Object> Function(String baseUrl) _flow;
  late final List<Object> _script = _flow(baseUrl);
  int _scriptIndex = 0;
  final List<Object> _challengeStatus;
  int _challengeStatusIndex = 0;

  final List<RecordedRequest> _requests = <RecordedRequest>[];
  final List<String> _unmatchedPaths = <String>[];

  /// Starts a server. [flow] builds the scripted node bodies from this server's [baseUrl], so
  /// captured fixtures can link to it.
  static Future<MockDaVinciServer> start({
    required List<Object> Function(String baseUrl) flow,
    List<Object> challengeStatus = const <Object>[],
  }) async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = MockDaVinciServer._(httpServer, flow, challengeStatus);
    httpServer.listen(server._handle);
    return server;
  }

  /// The session cookie set on the `SuccessNode` response, as PingOne's `ST`. The SDKs persist
  /// cookies named `ST`/`ST-NO-SS` to secure storage.
  static const sessionCookie = 'ST=mock-session-cookie';

  /// e.g. `http://127.0.0.1:54321`.
  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  /// The full URL to hand to `DaVinciConfigMessage.discoveryEndpoint`.
  String get discoveryEndpoint =>
      '$baseUrl/as/.well-known/openid-configuration';

  /// The requests to [path], oldest first.
  List<RecordedRequest> requestsTo(String path) =>
      _requests.where((r) => r.path == path).toList(growable: false);

  /// Every request received, oldest first.
  List<RecordedRequest> get requests =>
      List<RecordedRequest>.unmodifiable(_requests);

  /// The flow requests only: the authorize GET, then one POST per `next()`.
  List<RecordedRequest> get flowRequests => _requests
      .where(
        (r) =>
            r.path == '/as/authorize' ||
            (r.path.contains('/davinci/') && !_isChallengeStatus(r.path)),
      )
      .toList(growable: false);

  /// The challenge-status polls, oldest first.
  List<RecordedRequest> get challengeStatusRequests => _requests
      .where((r) => _isChallengeStatus(r.path))
      .toList(growable: false);

  static bool _isChallengeStatus(String path) =>
      path.contains('/davinci/user/credentials/challenge/') &&
      path.endsWith('/status');

  /// Paths that arrived with no handler, in arrival order.
  List<String> get unmatchedPaths => List<String>.unmodifiable(_unmatchedPaths);

  /// Throws a [StateError] with the full request log if any request went unhandled.
  void expectNoUnmatchedRequests() {
    if (_unmatchedPaths.isEmpty) return;
    throw StateError(
      'MockDaVinciServer had no handler for:\n  ${_unmatchedPaths.join('\n  ')}\n'
      'Full request log:\n$requestLog',
    );
  }

  /// A human-readable dump of every recorded request, for failure messages.
  String get requestLog => _requests.map((r) => '  ${r.summary}').join('\n');

  /// Shuts the server down. Safe to pass straight to `addTearDown`.
  Future<void> stop() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final recorded = RecordedRequest(
      method: request.method,
      path: request.uri.path,
      query: Map<String, String>.of(request.uri.queryParameters),
      headers: _collectHeaders(request.headers),
      body: await utf8.decoder.bind(request).join(),
    );
    _requests.add(recorded);

    var response = _responseFor(recorded);
    var status = HttpStatus.ok;
    if (response is MockResponse) {
      status = response.status;
      response = response.body;
    }
    if (response == null) {
      _unmatchedPaths.add('${recorded.method} ${recorded.path}');
      await _write(request, HttpStatus.notFound, <String, Object?>{
        'error': 'no handler registered',
        'receivedSoFar': _requests.map((r) => r.summary).toList(),
      });
      return;
    }
    if (response is Map && response.containsKey('authorizeResponse')) {
      request.response.headers.add(
        HttpHeaders.setCookieHeader,
        '$sessionCookie; Path=/; HttpOnly',
      );
    }
    await _write(request, status, response);
  }

  Object? _responseFor(RecordedRequest request) {
    if (request.method == 'POST' && _isChallengeStatus(request.path)) {
      if (_challengeStatus.isEmpty) return null;
      final index = _challengeStatusIndex < _challengeStatus.length
          ? _challengeStatusIndex++
          : _challengeStatus.length - 1;
      return _challengeStatus[index];
    }
    if ((request.method == 'GET' && request.path == '/as/authorize') ||
        (request.method == 'POST' && request.path.contains('/davinci/'))) {
      if (_scriptIndex >= _script.length) {
        return <String, Object?>{
          'error': 'flow script exhausted after ${_script.length} responses',
        };
      }
      return _script[_scriptIndex++];
    }
    return switch (request.path) {
      // iOS's `OpenIdConfiguration` fails to decode unless these five are present.
      '/as/.well-known/openid-configuration' => <String, Object?>{
        'issuer': '$baseUrl/as',
        'authorization_endpoint': '$baseUrl/as/authorize',
        'token_endpoint': '$baseUrl/as/token',
        'userinfo_endpoint': '$baseUrl/as/userinfo',
        'end_session_endpoint': '$baseUrl/as/signoff',
        'revocation_endpoint': '$baseUrl/as/revoke',
      },
      '/as/token' => <String, Object?>{
        'access_token': 'mock-access-token',
        'refresh_token': 'mock-refresh-token',
        'token_type': 'Bearer',
        'scope': 'openid',
        'expires_in': 3599,
      },
      '/as/userinfo' => <String, Object?>{'sub': 'mock-subject'},
      '/as/revoke' || '/as/signoff' => <String, Object?>{},
      _ => null,
    };
  }

  static Future<void> _write(
    HttpRequest request,
    int status,
    Object body,
  ) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  }

  static Map<String, String> _collectHeaders(HttpHeaders headers) {
    final collected = <String, String>{};
    headers.forEach(
      (name, values) => collected[name.toLowerCase()] = values.join(', '),
    );
    return collected;
  }
}

/// A scripted [MockDaVinciServer] response with a status other than `200`, e.g. a DaVinci `400`.
class MockResponse {
  /// Creates a response answered with [status].
  const MockResponse(this.status, this.body);

  /// The HTTP status.
  final int status;

  /// The JSON body.
  final Object body;
}

/// One request as observed by [MockDaVinciServer].
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

  /// The `parameters.data` object of a submitted DaVinci node — `actionKey` and `formData`.
  Map<String, Object?>? get submittedData {
    final parameters = json?['parameters'];
    final data = parameters is Map ? parameters['data'] : null;
    return data is Map ? data.cast<String, Object?>() : null;
  }

  /// A one-line description used in failure messages.
  String get summary {
    final preview = body.length > 300 ? '${body.substring(0, 300)}…' : body;
    return '$method $path${preview.isEmpty ? '' : ' body=$preview'}';
  }
}
