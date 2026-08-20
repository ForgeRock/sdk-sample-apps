/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_oidc/ping_oidc.dart';
import 'package:ping_oidc/src/messages.g.dart';

/// Fake [PingOidcHostApi]: overrides every method instead of hitting a platform channel, so
/// [OidcClient] can be exercised without a native bridge.
class _FakeHostApi extends PingOidcHostApi {
  String? configureOidcHandleId;
  OidcConfigMessage? lastConfig;

  String? createWebClientHandleId;
  String? lastCreateWebClientClientId;
  BrowserOptionsMessage? lastCreateWebClientOptions;

  AuthorizeResultMessage? authorizeResult;
  String? lastAuthorizeWebClientId;

  bool hasUserResult = false;
  String? lastHasUserWebClientId;

  final List<String> disposeHandleIds = [];

  Object? configureErrorToThrow;
  Object? createWebClientErrorToThrow;
  Object? authorizeErrorToThrow;
  Object? disposeErrorToThrow;

  /// Handle ids for which [dispose] should throw [disposeErrorToThrow] instead of succeeding.
  /// Empty means every [dispose] call throws when [disposeErrorToThrow] is set.
  final Set<String> disposeErrorHandleIds = {};

  TokenMessage? tokenResult;
  String? lastTokenWebClientId;
  Object? tokenErrorToThrow;

  TokenMessage? refreshResult;
  String? lastRefreshWebClientId;
  Object? refreshErrorToThrow;

  Map<String?, Object?> userInfoResult = const {};
  String? lastUserInfoWebClientId;
  bool? lastUserInfoCache;
  Object? userInfoErrorToThrow;

  String? lastRevokeWebClientId;
  Object? revokeErrorToThrow;

  bool signOffResult = true;
  String? lastSignOffWebClientId;
  Object? signOffErrorToThrow;

  @override
  Future<String> configureOidc(OidcConfigMessage config) async {
    if (configureErrorToThrow != null) throw configureErrorToThrow!;
    lastConfig = config;
    return configureOidcHandleId ?? 'oidc-client-1';
  }

  @override
  Future<String> createWebClient(
    String clientId,
    BrowserOptionsMessage? options,
  ) async {
    if (createWebClientErrorToThrow != null) throw createWebClientErrorToThrow!;
    lastCreateWebClientClientId = clientId;
    lastCreateWebClientOptions = options;
    return createWebClientHandleId ?? 'oidc-web-client-1';
  }

  @override
  Future<AuthorizeResultMessage> authorize(String webClientId) async {
    if (authorizeErrorToThrow != null) throw authorizeErrorToThrow!;
    lastAuthorizeWebClientId = webClientId;
    return authorizeResult ??
        AuthorizeResultMessage(type: AuthorizeResultType.success);
  }

  @override
  Future<bool> hasUser(String webClientId) async {
    lastHasUserWebClientId = webClientId;
    return hasUserResult;
  }

  @override
  Future<TokenMessage> token(String webClientId) async {
    if (tokenErrorToThrow != null) throw tokenErrorToThrow!;
    lastTokenWebClientId = webClientId;
    return tokenResult ?? TokenMessage(accessToken: 'at', expiresIn: 3600);
  }

  @override
  Future<TokenMessage> refresh(String webClientId) async {
    if (refreshErrorToThrow != null) throw refreshErrorToThrow!;
    lastRefreshWebClientId = webClientId;
    return refreshResult ??
        TokenMessage(accessToken: 'refreshed-at', expiresIn: 3600);
  }

  @override
  Future<Map<String?, Object?>> userInfo(
    String webClientId,
    bool cache,
  ) async {
    if (userInfoErrorToThrow != null) throw userInfoErrorToThrow!;
    lastUserInfoWebClientId = webClientId;
    lastUserInfoCache = cache;
    return userInfoResult;
  }

  @override
  Future<void> revoke(String webClientId) async {
    if (revokeErrorToThrow != null) throw revokeErrorToThrow!;
    lastRevokeWebClientId = webClientId;
  }

  @override
  Future<bool> signOff(String webClientId) async {
    if (signOffErrorToThrow != null) throw signOffErrorToThrow!;
    lastSignOffWebClientId = webClientId;
    return signOffResult;
  }

  @override
  Future<void> dispose(String handleId) async {
    final shouldThrow =
        disposeErrorToThrow != null &&
        (disposeErrorHandleIds.isEmpty ||
            disposeErrorHandleIds.contains(handleId));
    if (shouldThrow) throw disposeErrorToThrow!;
    disposeHandleIds.add(handleId);
  }
}

void main() {
  late _FakeHostApi hostApi;

  setUp(() {
    hostApi = _FakeHostApi();
  });

  OidcConfig config() => const OidcConfig(
    clientId: 'client-1',
    redirectUri: 'https://example.com/callback',
    discoveryEndpoint: 'https://example.com/.well-known/openid-configuration',
  );

  group('OidcClient.configure', () {
    test('forwards the config and builds a web client from the returned handleId', () async {
      hostApi.configureOidcHandleId = 'oidc-client-42';

      await OidcClient.configure(config(), hostApi: hostApi);

      expect(hostApi.lastConfig?.clientId, 'client-1');
      expect(hostApi.lastConfig?.redirectUri, 'https://example.com/callback');
      expect(
        hostApi.lastConfig?.discoveryEndpoint,
        'https://example.com/.well-known/openid-configuration',
      );
      expect(hostApi.lastCreateWebClientClientId, 'oidc-client-42');
    });

    test('forwards browserOptions to createWebClient', () async {
      const options = OidcBrowserOptions(browserType: 'authSession');

      await OidcClient.configure(
        config(),
        browserOptions: options,
        hostApi: hostApi,
      );

      expect(hostApi.lastCreateWebClientOptions?.browserType, 'authSession');
    });

    test('throws ArgumentError when redirectUri is null', () async {
      const noRedirectUri = OidcConfig(
        clientId: 'client-1',
        discoveryEndpoint: 'https://example.com/.well-known/openid-configuration',
      );

      expect(
        () => OidcClient.configure(noRedirectUri, hostApi: hostApi),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('wraps a PlatformException into a PingException', () async {
      hostApi.configureErrorToThrow = PlatformException(
        code: 'OIDC_CONFIGURE_ERROR',
        message: 'bad config',
        details: 'argument',
      );

      expect(
        () => OidcClient.configure(config(), hostApi: hostApi),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'OIDC_CONFIGURE_ERROR')
              .having((e) => e.type, 'type', 'argument')
              .having((e) => e.message, 'message', 'bad config'),
        ),
      );
    });

    test(
      'disposes the already-registered client handle when createWebClient fails',
      () async {
        hostApi.configureOidcHandleId = 'oidc-client-99';
        hostApi.createWebClientErrorToThrow = PlatformException(
          code: 'OIDC_CREATE_WEB_CLIENT_ERROR',
          message: 'unsupported browser options',
          details: 'argument',
        );

        await expectLater(
          () => OidcClient.configure(config(), hostApi: hostApi),
          throwsA(
            isA<PingException>().having(
              (e) => e.code,
              'code',
              'OIDC_CREATE_WEB_CLIENT_ERROR',
            ),
          ),
        );

        expect(hostApi.disposeHandleIds, ['oidc-client-99']);
      },
    );
  });

  group('OidcClient.authorize', () {
    test('resolves AuthorizeSuccess for a success result', () async {
      hostApi.createWebClientHandleId = 'oidc-web-client-1';
      hostApi.authorizeResult = AuthorizeResultMessage(
        type: AuthorizeResultType.success,
      );
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      final result = await client.authorize();

      expect(result, isA<AuthorizeSuccess>());
      expect(hostApi.lastAuthorizeWebClientId, 'oidc-web-client-1');
    });

    test('resolves AuthorizeCancel for a cancel result, not an error', () async {
      hostApi.authorizeResult = AuthorizeResultMessage(
        type: AuthorizeResultType.cancel,
      );
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      final result = await client.authorize();

      expect(result, isA<AuthorizeCancel>());
    });

    test('wraps a PlatformException into a PingException', () async {
      hostApi.authorizeErrorToThrow = PlatformException(
        code: 'OIDC_AUTHORIZE_ERROR',
        message: 'boom',
        details: 'unknown',
      );
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      expect(() => client.authorize(), throwsA(isA<PingException>()));
    });
  });

  group('OidcClient.hasUser', () {
    test('forwards the bound web handleId and returns the native result', () async {
      hostApi.createWebClientHandleId = 'oidc-web-client-7';
      hostApi.hasUserResult = true;
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      final result = await client.hasUser();

      expect(result, isTrue);
      expect(hostApi.lastHasUserWebClientId, 'oidc-web-client-7');
    });
  });

  group('OidcClient.token', () {
    test('forwards the bound web handleId and maps TokenMessage to OidcToken', () async {
      hostApi.createWebClientHandleId = 'oidc-web-client-1';
      hostApi.tokenResult = TokenMessage(
        accessToken: 'access-1',
        tokenType: 'Bearer',
        scope: 'openid',
        expiresIn: 60,
        refreshToken: 'refresh-1',
        idToken: 'id-1',
      );
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      final token = await client.token();

      expect(hostApi.lastTokenWebClientId, 'oidc-web-client-1');
      expect(token.accessToken, 'access-1');
      expect(token.tokenType, 'Bearer');
      expect(token.scope, 'openid');
      expect(token.expiresIn, 60);
      expect(token.refreshToken, 'refresh-1');
      expect(token.idToken, 'id-1');
    });

    test('wraps a PlatformException into a PingException', () async {
      hostApi.tokenErrorToThrow = PlatformException(
        code: 'OIDC_TOKEN_ERROR',
        message: 'no session',
        details: 'state',
      );
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      expect(
        () => client.token(),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'OIDC_TOKEN_ERROR')
              .having((e) => e.type, 'type', 'state'),
        ),
      );
    });
  });

  group('OidcClient.refresh', () {
    test('forwards the bound web handleId and maps TokenMessage to OidcToken', () async {
      hostApi.createWebClientHandleId = 'oidc-web-client-2';
      hostApi.refreshResult = TokenMessage(
        accessToken: 'access-2',
        expiresIn: 120,
      );
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      final token = await client.refresh();

      expect(hostApi.lastRefreshWebClientId, 'oidc-web-client-2');
      expect(token.accessToken, 'access-2');
      expect(token.expiresIn, 120);
    });

    test('wraps a PlatformException into a PingException', () async {
      hostApi.refreshErrorToThrow = PlatformException(
        code: 'OIDC_REFRESH_ERROR',
        message: 'no refresh token',
        details: 'exchange',
      );
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      expect(
        () => client.refresh(),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'OIDC_REFRESH_ERROR')
              .having((e) => e.type, 'type', 'exchange'),
        ),
      );
    });
  });

  group('OidcClient.userInfo', () {
    test('sends cache: false by default', () async {
      hostApi.createWebClientHandleId = 'oidc-web-client-3';
      hostApi.userInfoResult = {'sub': 'user-1'};
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      final info = await client.userInfo();

      expect(hostApi.lastUserInfoWebClientId, 'oidc-web-client-3');
      expect(hostApi.lastUserInfoCache, isFalse);
      expect(info, {'sub': 'user-1'});
    });

    test('forwards an explicit cache: true', () async {
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      await client.userInfo(cache: true);

      expect(hostApi.lastUserInfoCache, isTrue);
    });

    test('wraps a PlatformException into a PingException', () async {
      hostApi.userInfoErrorToThrow = PlatformException(
        code: 'OIDC_USERINFO_ERROR',
        message: 'boom',
        details: 'network',
      );
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      expect(
        () => client.userInfo(),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'OIDC_USERINFO_ERROR')
              .having((e) => e.type, 'type', 'network'),
        ),
      );
    });
  });

  group('OidcClient.revoke', () {
    test('forwards the bound web handleId', () async {
      hostApi.createWebClientHandleId = 'oidc-web-client-4';
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      await client.revoke();

      expect(hostApi.lastRevokeWebClientId, 'oidc-web-client-4');
    });

    test('wraps a PlatformException into a PingException', () async {
      hostApi.revokeErrorToThrow = PlatformException(
        code: 'OIDC_REVOKE_ERROR',
        message: 'no session',
        details: 'state',
      );
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      expect(
        () => client.revoke(),
        throwsA(
          isA<PingException>().having(
            (e) => e.code,
            'code',
            'OIDC_REVOKE_ERROR',
          ),
        ),
      );
    });
  });

  group('OidcClient.signOff', () {
    test('forwards the bound web handleId and returns the native result', () async {
      hostApi.createWebClientHandleId = 'oidc-web-client-5';
      hostApi.signOffResult = true;
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      final result = await client.signOff();

      expect(result, isTrue);
      expect(hostApi.lastSignOffWebClientId, 'oidc-web-client-5');
    });

    test('wraps a PlatformException into a PingException', () async {
      hostApi.signOffErrorToThrow = PlatformException(
        code: 'OIDC_LOGOUT_ERROR',
        message: 'no session',
        details: 'state',
      );
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      expect(
        () => client.signOff(),
        throwsA(
          isA<PingException>().having(
            (e) => e.code,
            'code',
            'OIDC_LOGOUT_ERROR',
          ),
        ),
      );
    });
  });

  group('OidcClient.dispose', () {
    test('disposes both the client and web-client handles', () async {
      hostApi.configureOidcHandleId = 'oidc-client-1';
      hostApi.createWebClientHandleId = 'oidc-web-client-1';
      final client = await OidcClient.configure(config(), hostApi: hostApi);

      await client.dispose();

      expect(hostApi.disposeHandleIds, ['oidc-client-1', 'oidc-web-client-1']);
    });

    test(
      'still disposes the web-client handle when disposing the client handle fails',
      () async {
        hostApi.configureOidcHandleId = 'oidc-client-1';
        hostApi.createWebClientHandleId = 'oidc-web-client-1';
        final client = await OidcClient.configure(config(), hostApi: hostApi);

        hostApi.disposeErrorToThrow = PlatformException(
          code: 'OIDC_DISPOSE_ERROR',
          message: 'native dispose failed',
          details: 'argument',
        );
        hostApi.disposeErrorHandleIds.add('oidc-client-1');

        await expectLater(
          () => client.dispose(),
          throwsA(
            isA<PingException>().having(
              (e) => e.code,
              'code',
              'OIDC_DISPOSE_ERROR',
            ),
          ),
        );

        expect(hostApi.disposeHandleIds, ['oidc-web-client-1']);
      },
    );
  });

  group('OidcClient._guard error mapping', () {
    test('falls back to "unknown" type when error.details is not a String', () async {
      hostApi.configureErrorToThrow = PlatformException(
        code: 'OIDC_CONFIGURE_ERROR',
        message: 'bad config',
        details: {'not': 'a string'},
      );

      expect(
        () => OidcClient.configure(config(), hostApi: hostApi),
        throwsA(isA<PingException>().having((e) => e.type, 'type', 'unknown')),
      );
    });

    test('falls back to a default message when error.message is null', () async {
      hostApi.configureErrorToThrow = PlatformException(
        code: 'OIDC_CONFIGURE_ERROR',
        details: 'argument',
      );

      expect(
        () => OidcClient.configure(config(), hostApi: hostApi),
        throwsA(
          isA<PingException>().having(
            (e) => e.message,
            'message',
            'Unknown OIDC error',
          ),
        ),
      );
    });

    test('propagates non-PlatformException errors unchanged', () async {
      hostApi.configureErrorToThrow = StateError('boom');

      expect(
        () => OidcClient.configure(config(), hostApi: hostApi),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('OidcToken.fromMessage', () {
    test('every TokenMessage field lands in the matching OidcToken field', () {
      final message = TokenMessage(
        accessToken: 'at',
        tokenType: 'Bearer',
        scope: 'openid profile',
        expiresIn: 3600,
        refreshToken: 'rt',
        idToken: 'idt',
      );

      final token = OidcToken.fromMessage(message);

      expect(token.accessToken, 'at');
      expect(token.tokenType, 'Bearer');
      expect(token.scope, 'openid profile');
      expect(token.expiresIn, 3600);
      expect(token.refreshToken, 'rt');
      expect(token.idToken, 'idt');
    });
  });

  group('OidcToken.fromJson / toJson', () {
    test('round-trips through toJson/fromJson', () {
      const token = OidcToken(
        accessToken: 'at',
        tokenType: 'Bearer',
        scope: 'openid',
        expiresIn: 60,
        refreshToken: 'rt',
        idToken: 'idt',
      );

      final roundTripped = OidcToken.fromJson(token.toJson());

      expect(roundTripped.accessToken, token.accessToken);
      expect(roundTripped.tokenType, token.tokenType);
      expect(roundTripped.scope, token.scope);
      expect(roundTripped.expiresIn, token.expiresIn);
      expect(roundTripped.refreshToken, token.refreshToken);
      expect(roundTripped.idToken, token.idToken);
    });

    test('omits null optional fields from toJson', () {
      const token = OidcToken(accessToken: 'at', expiresIn: 60);

      expect(token.toJson(), {'accessToken': 'at', 'expiresIn': 60});
    });

    test('throws FormatException when accessToken is missing', () {
      expect(
        () => OidcToken.fromJson({'expiresIn': 60}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when accessToken is empty', () {
      expect(
        () => OidcToken.fromJson({'accessToken': '', 'expiresIn': 60}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when expiresIn is missing', () {
      expect(
        () => OidcToken.fromJson({'accessToken': 'at'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when expiresIn is not an int', () {
      expect(
        () => OidcToken.fromJson({'accessToken': 'at', 'expiresIn': '60'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when refreshToken is present but not a string', () {
      expect(
        () => OidcToken.fromJson({
          'accessToken': 'at',
          'expiresIn': 60,
          'refreshToken': 42,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
