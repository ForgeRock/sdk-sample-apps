/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';

/// Fake [PingJourneyHostApi]: overrides every method instead of hitting a platform channel,
/// so [JourneyClient] can be exercised without a native bridge.
class _FakeHostApi extends PingJourneyHostApi {
  String? configureJourneyId;
  JourneyConfigMessage? lastConfig;

  String? lastStartJourneyId;
  String? lastStartName;
  StartOptionsMessage? lastStartOptions;
  NodeMessage? startResult;

  String? lastNextJourneyId;
  List<CallbackValueMessage?>? lastNextValues;
  NodeMessage? nextResult;

  String? lastGetSessionJourneyId;
  SessionMessage? getSessionResult;

  String? lastRefreshJourneyId;
  SessionMessage? refreshTokenResult;

  String? lastRevokeJourneyId;

  String? lastUserInfoJourneyId;
  bool? lastUserInfoCache;
  Map<String?, Object?>? getUserInfoResult;

  String? lastSignOffJourneyId;
  bool signOffResult = true;

  String? lastDisposeJourneyId;

  Object? errorToThrow;

  @override
  Future<String> configureJourney(JourneyConfigMessage config) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastConfig = config;
    return configureJourneyId ?? 'journey-1';
  }

  @override
  Future<NodeMessage> start(
    String journeyId,
    String name,
    StartOptionsMessage options,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastStartJourneyId = journeyId;
    lastStartName = name;
    lastStartOptions = options;
    return startResult ?? NodeMessage(type: NodeType.successNode);
  }

  @override
  Future<NodeMessage> next(
    String journeyId,
    List<CallbackValueMessage?> values,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastNextJourneyId = journeyId;
    lastNextValues = values;
    return nextResult ?? NodeMessage(type: NodeType.successNode);
  }

  @override
  Future<SessionMessage?> getSession(String journeyId) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastGetSessionJourneyId = journeyId;
    return getSessionResult;
  }

  @override
  Future<SessionMessage> refreshToken(String journeyId) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastRefreshJourneyId = journeyId;
    return refreshTokenResult ??
        SessionMessage(accessToken: 'refreshed-token', expiresIn: 3600);
  }

  @override
  Future<void> revokeToken(String journeyId) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastRevokeJourneyId = journeyId;
  }

  @override
  Future<Map<String?, Object?>> getUserInfo(
    String journeyId,
    bool cache,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastUserInfoJourneyId = journeyId;
    lastUserInfoCache = cache;
    return getUserInfoResult ?? {'sub': 'user-1'};
  }

  @override
  Future<bool> signOff(String journeyId) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastSignOffJourneyId = journeyId;
    return signOffResult;
  }

  @override
  Future<void> dispose(String journeyId) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastDisposeJourneyId = journeyId;
  }
}

void main() {
  late _FakeHostApi hostApi;

  setUp(() {
    hostApi = _FakeHostApi();
  });

  Future<JourneyClient> configureClient() => JourneyClient.configure(
    JourneyConfigMessage(serverUrl: 'https://example.com'),
    hostApi: hostApi,
  );

  group('JourneyClient.configure', () {
    test('forwards the config and binds the returned journeyId', () async {
      hostApi.configureJourneyId = 'journey-42';
      final config = JourneyConfigMessage(serverUrl: 'https://example.com');

      final client = await JourneyClient.configure(config, hostApi: hostApi);

      expect(hostApi.lastConfig, config);
      // Bound journeyId is exercised indirectly via next/dispose below.
      await client.dispose();
      expect(hostApi.lastDisposeJourneyId, 'journey-42');
    });

    test('wraps a PlatformException into a PingException', () async {
      hostApi.errorToThrow = PlatformException(
        code: 'JOURNEY_CONFIGURE_ERROR',
        message: 'bad config',
        details: 'argument',
      );

      expect(
        () => JourneyClient.configure(
          JourneyConfigMessage(serverUrl: 'https://example.com'),
          hostApi: hostApi,
        ),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'JOURNEY_CONFIGURE_ERROR')
              .having((e) => e.type, 'type', 'argument')
              .having((e) => e.message, 'message', 'bad config'),
        ),
      );
    });

    test(
      'throws ArgumentError when both oidcClientId and an inline field are set',
      () async {
        final config = JourneyConfigMessage(serverUrl: 'https://example.com')
          ..oidcClientId = 'oidc-client-1'
          ..clientId = 'client-1';

        await expectLater(
          () => JourneyClient.configure(config, hostApi: hostApi),
          throwsA(isA<ArgumentError>()),
        );
        expect(hostApi.lastConfig, isNull);
      },
    );

    test(
      'does not call configureJourney when oidcClientId/discoveryEndpoint conflict',
      () async {
        final config = JourneyConfigMessage(serverUrl: 'https://example.com')
          ..oidcClientId = 'oidc-client-1'
          ..discoveryEndpoint =
              'https://example.com/.well-known/openid-configuration';

        await expectLater(
          () => JourneyClient.configure(config, hostApi: hostApi),
          throwsA(isA<ArgumentError>()),
        );
        expect(hostApi.lastConfig, isNull);
      },
    );

    test('oidcClientId alone is accepted and forwarded unchanged', () async {
      final config = JourneyConfigMessage(serverUrl: 'https://example.com')
        ..oidcClientId = 'oidc-client-1';

      await JourneyClient.configure(config, hostApi: hostApi);

      expect(hostApi.lastConfig?.oidcClientId, 'oidc-client-1');
    });
  });

  group('JourneyClient.start', () {
    test('maps the returned NodeMessage to a JourneyNode', () async {
      final client = await configureClient();
      hostApi.startResult = NodeMessage(type: NodeType.successNode);

      final node = await client.start('Login', forceAuth: true);

      expect(node, isA<SuccessNode>());
      expect(hostApi.lastStartName, 'Login');
      expect(hostApi.lastStartOptions?.forceAuth, true);
      expect(hostApi.lastStartOptions?.noSession, false);
    });
  });

  group('JourneyClient.next', () {
    test(
      'submits toValue() for each callback and maps the next node',
      () async {
        final client = await configureClient();
        hostApi.nextResult = NodeMessage(type: NodeType.successNode);
        final node = ContinueNode(
          journeyId: 'journey-1',
          callbacks: [
            NameCallback(type: 'NameCallback', index: 0, name: 'jdoe'),
          ],
        );

        await client.next(node);

        final values = hostApi.lastNextValues!;
        expect(values, hasLength(1));
        expect(values.single!.value, 'jdoe');
      },
    );

    test('drops callbacks whose toValue() is null (output-only)', () async {
      final client = await configureClient();
      hostApi.nextResult = NodeMessage(type: NodeType.successNode);
      final node = ContinueNode(
        journeyId: 'journey-1',
        callbacks: [
          TextOutputCallback(
            type: 'TextOutputCallback',
            index: 0,
            message: 'Welcome',
          ),
        ],
      );

      await client.next(node);

      expect(hostApi.lastNextValues, isEmpty);
    });
  });

  group('JourneyClient.user', () {
    test('returns null when there is no session', () async {
      final client = await configureClient();
      hostApi.getSessionResult = null;

      expect(await client.user(), isNull);
    });

    test('maps a SessionMessage to a Session', () async {
      final client = await configureClient();
      hostApi.getSessionResult = SessionMessage(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        idToken: 'id-token',
        tokenType: 'Bearer',
        scope: 'openid profile',
        expiresIn: 3600,
        userInfo: {'sub': 'user-1'},
      );

      final session = await client.user();

      expect(session, isNotNull);
      expect(session!.accessToken, 'access-token');
      expect(session.refreshToken, 'refresh-token');
      expect(session.idToken, 'id-token');
      expect(session.tokenType, 'Bearer');
      expect(session.scope, 'openid profile');
      expect(session.expiresIn, 3600);
      expect(session.userInfo['sub'], 'user-1');
    });
  });

  group('JourneyClient.refresh', () {
    test('returns a Session built from the refreshed token message', () async {
      final client = await configureClient();
      hostApi.refreshTokenResult = SessionMessage(
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        idToken: 'new-id-token',
        tokenType: 'Bearer',
        scope: 'openid profile',
        expiresIn: 1800,
      );

      final session = await client.refresh();

      expect(hostApi.lastRefreshJourneyId, 'journey-1');
      expect(session.accessToken, 'new-access-token');
      expect(session.refreshToken, 'new-refresh-token');
      expect(session.idToken, 'new-id-token');
      expect(session.tokenType, 'Bearer');
      expect(session.scope, 'openid profile');
      expect(session.expiresIn, 1800);
      expect(session.userInfo, isEmpty);
    });

    test('propagates JOURNEY_REFRESH_ERROR as a PingException', () async {
      final client = await configureClient();
      hostApi.errorToThrow = PlatformException(
        code: 'JOURNEY_REFRESH_ERROR',
        message: 'no session',
        details: 'state',
      );

      await expectLater(
        () => client.refresh(),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'JOURNEY_REFRESH_ERROR')
              .having((e) => e.type, 'type', 'state'),
        ),
      );
    });
  });

  group('JourneyClient.revoke', () {
    test('forwards the bound journeyId and completes', () async {
      final client = await configureClient();

      await client.revoke();

      expect(hostApi.lastRevokeJourneyId, 'journey-1');
    });

    test('propagates JOURNEY_REVOKE_ERROR as a PingException', () async {
      final client = await configureClient();
      hostApi.errorToThrow = PlatformException(
        code: 'JOURNEY_REVOKE_ERROR',
        message: 'no session',
        details: 'state',
      );

      await expectLater(
        () => client.revoke(),
        throwsA(
          isA<PingException>().having(
            (e) => e.code,
            'code',
            'JOURNEY_REVOKE_ERROR',
          ),
        ),
      );
    });
  });

  group('JourneyClient.userInfo', () {
    test('passes cache through and casts the returned map', () async {
      final client = await configureClient();
      hostApi.getUserInfoResult = {'sub': 'user-9', 'name': 'Jane'};

      final info = await client.userInfo(cache: true);

      expect(hostApi.lastUserInfoJourneyId, 'journey-1');
      expect(hostApi.lastUserInfoCache, true);
      expect(info, {'sub': 'user-9', 'name': 'Jane'});
    });

    test('defaults cache to false', () async {
      final client = await configureClient();

      await client.userInfo();

      expect(hostApi.lastUserInfoCache, false);
    });

    test('propagates JOURNEY_USERINFO_ERROR as a PingException', () async {
      final client = await configureClient();
      hostApi.errorToThrow = PlatformException(
        code: 'JOURNEY_USERINFO_ERROR',
        message: 'no session',
        details: 'state',
      );

      await expectLater(
        () => client.userInfo(),
        throwsA(
          isA<PingException>().having(
            (e) => e.code,
            'code',
            'JOURNEY_USERINFO_ERROR',
          ),
        ),
      );
    });
  });

  group('JourneyClient.signOff', () {
    test(
      'forwards the bound journeyId and returns the native result',
      () async {
        final client = await configureClient();
        hostApi.signOffResult = true;

        expect(await client.signOff(), true);
      },
    );
  });

  group('JourneyClient.dispose', () {
    test('forwards the bound journeyId', () async {
      final client = await configureClient();

      await client.dispose();

      expect(hostApi.lastDisposeJourneyId, isNotNull);
    });
  });

  group('JourneyClient._guard error mapping', () {
    test('maps error.details String to PingException.type', () async {
      final client = await configureClient();
      hostApi.errorToThrow = PlatformException(
        code: 'JOURNEY_NEXT_ERROR',
        message: 'no active node',
        details: 'state',
      );

      expect(
        () => client.next(
          ContinueNode(journeyId: 'journey-1', callbacks: const []),
        ),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'JOURNEY_NEXT_ERROR')
              .having((e) => e.type, 'type', 'state')
              .having((e) => e.message, 'message', 'no active node'),
        ),
      );
    });

    test(
      'falls back to "unknown" type when error.details is not a String',
      () async {
        final client = await configureClient();
        hostApi.errorToThrow = PlatformException(
          code: 'JOURNEY_NEXT_ERROR',
          message: 'no active node',
          details: {'not': 'a string'},
        );

        expect(
          () => client.next(
            ContinueNode(journeyId: 'journey-1', callbacks: const []),
          ),
          throwsA(
            isA<PingException>().having((e) => e.type, 'type', 'unknown'),
          ),
        );
      },
    );

    test(
      'falls back to a default message when error.message is null',
      () async {
        final client = await configureClient();
        hostApi.errorToThrow = PlatformException(
          code: 'JOURNEY_NEXT_ERROR',
          details: 'state',
        );

        expect(
          () => client.next(
            ContinueNode(journeyId: 'journey-1', callbacks: const []),
          ),
          throwsA(
            isA<PingException>().having(
              (e) => e.message,
              'message',
              'Unknown journey error',
            ),
          ),
        );
      },
    );

    test('propagates non-PlatformException errors unchanged', () async {
      final client = await configureClient();
      hostApi.errorToThrow = StateError('boom');

      expect(
        () => client.next(
          ContinueNode(journeyId: 'journey-1', callbacks: const []),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
