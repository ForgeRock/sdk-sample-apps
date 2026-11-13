/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_davinci/ping_davinci.dart';
import 'package:ping_davinci/src/node_mapper.dart';

/// Fake [PingDaVinciHostApi]: overrides the methods [DaVinciClient] calls instead of hitting a
/// platform channel, so the client can be exercised without a native bridge.
class _FakeHostApi extends PingDaVinciHostApi {
  String configureResult = 'davinci-1';
  DaVinciConfigMessage? lastConfig;
  String? lastDisposeId;
  String? lastStartId;
  NodeMessage startResult = NodeMessage(type: NodeType.successNode);
  String? lastNextId;
  List<CollectorValueMessage?>? lastNextValues;
  NodeMessage nextResult = NodeMessage(type: NodeType.successNode);
  List<CollectorValueMessage?>? lastValidateValues;
  List<ValidationErrorMessage?> validateResult = const [];
  SessionMessage? sessionResult;
  TokenMessage tokenResult = TokenMessage(accessToken: 'at', expiresIn: 1);
  Map<String?, Object?> userInfoResult = const {};
  bool? lastUserInfoCache;
  bool signOffResult = true;
  final List<String> calls = <String>[];
  Object? errorToThrow;

  @override
  Future<SessionMessage?> getSession(String daVinciId) async {
    if (errorToThrow != null) throw errorToThrow!;
    calls.add('getSession:$daVinciId');
    return sessionResult;
  }

  @override
  Future<TokenMessage> getToken(String daVinciId) async {
    if (errorToThrow != null) throw errorToThrow!;
    calls.add('getToken:$daVinciId');
    return tokenResult;
  }

  @override
  Future<Map<String?, Object?>> getUserInfo(
    String daVinciId,
    bool cache,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    calls.add('getUserInfo:$daVinciId');
    lastUserInfoCache = cache;
    return userInfoResult;
  }

  @override
  Future<bool> signOff(String daVinciId) async {
    if (errorToThrow != null) throw errorToThrow!;
    calls.add('signOff:$daVinciId');
    return signOffResult;
  }

  @override
  Future<List<ValidationErrorMessage?>> validate(
    String daVinciId,
    List<CollectorValueMessage?> values,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastValidateValues = values;
    return validateResult;
  }

  @override
  Future<NodeMessage> start(String daVinciId) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastStartId = daVinciId;
    return startResult;
  }

  @override
  Future<NodeMessage> next(
    String daVinciId,
    List<CollectorValueMessage?> values,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastNextId = daVinciId;
    lastNextValues = values;
    return nextResult;
  }

  @override
  Future<String> configureDaVinci(DaVinciConfigMessage config) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastConfig = config;
    return configureResult;
  }

  @override
  Future<void> dispose(String daVinciId) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastDisposeId = daVinciId;
  }

  @override
  Future<void> startPolling(
    String daVinciId,
    String pollId,
    String collectorType,
    int index,
  ) async {
    if (startPollingError != null) throw startPollingError!;
    calls.add('startPolling:$daVinciId:$collectorType:$index');
    startedPollIds.add(pollId);
  }

  final List<String> startedPollIds = <String>[];
  Object? startPollingError;

  @override
  Future<void> cancelPolling(String pollId) async {
    calls.add('cancelPolling:$pollId');
  }
}

DaVinciConfigMessage _config() => DaVinciConfigMessage()
  ..clientId = 'client'
  ..redirectUri = 'com.example://callback'
  ..discoveryEndpoint = 'https://example.com/.well-known/openid-configuration';

void main() {
  group('DaVinciClient', () {
    test(
      'configure forwards the config and exposes the native handle id',
      () async {
        final api = _FakeHostApi()..configureResult = 'handle-42';
        final config = _config();

        final client = await DaVinciClient.configure(config, hostApi: api);

        expect(client.handleId, 'handle-42');
        expect(api.lastConfig, same(config));
      },
    );

    test('start maps the first node for this handle', () async {
      final api = _FakeHostApi()
        ..configureResult = 'handle-3'
        ..startResult = NodeMessage(
          type: NodeType.continueNode,
          name: 'Menu',
          collectors: [
            CollectorMessage(
              type: 'FLOW_BUTTON',
              index: 0,
              kind: CollectorKind.flow,
            ),
          ],
        );
      final client = await DaVinciClient.configure(_config(), hostApi: api);

      final node = await client.start();

      expect(api.lastStartId, 'handle-3');
      expect((node as ContinueNode).name, 'Menu');
      expect(node.collectors.single, isA<FlowCollector>());
      expect(node.collectors.single.type, 'FLOW_BUTTON');
    });

    test('next sends only the values the app set', () async {
      final api = _FakeHostApi()
        ..nextResult = NodeMessage(type: NodeType.errorNode, message: 'x');
      final client = await DaVinciClient.configure(_config(), hostApi: api);
      Collector collector(
        String type,
        int index,
        String kind, {
        Object? value,
      }) => Collector.fromMessage(
        CollectorMessage(
          type: type,
          index: index,
          kind: kind,
          key: type.toLowerCase(),
          value: value,
        ),
      );
      final node = ContinueNode(
        collectors: [
          collector('LABEL', 0, CollectorKind.label),
          collector('TEXT', 1, CollectorKind.text, value: 'untouched'),
          collector('TEXT', 2, CollectorKind.text) as TextCollector
            ..value = 'alice',
          collector('SUBMIT_BUTTON', 3, CollectorKind.submit) as SubmitCollector
            ..select(),
        ],
      );

      final next = await client.next(node);

      expect(api.lastNextId, 'davinci-1');
      expect(api.lastNextValues!.map((v) => (v!.type, v.index, v.value)), [
        ('TEXT', 2, 'alice'),
        ('SUBMIT_BUTTON', 3, 'submit_button'),
      ]);
      expect(next, isA<ErrorNode>());
    });

    test(
      'next maps a native argument error to a typed PingException',
      () async {
        final api = _FakeHostApi();
        final client = await DaVinciClient.configure(_config(), hostApi: api);
        api.errorToThrow = PlatformException(
          code: 'DAVINCI_NEXT_ERROR',
          message: 'BOOLEAN at index=0 expects a bool, got String',
          details: 'argument',
        );

        await expectLater(
          client.next(const ContinueNode(collectors: [])),
          throwsA(
            isA<PingException>()
                .having((e) => e.code, 'code', 'DAVINCI_NEXT_ERROR')
                .having((e) => e.type, 'type', 'argument'),
          ),
        );
      },
    );

    test('dispose releases the handle it was configured with', () async {
      final api = _FakeHostApi()..configureResult = 'handle-7';
      final client = await DaVinciClient.configure(_config(), hostApi: api);

      await client.dispose();

      expect(api.lastDisposeId, 'handle-7');
    });

    test(
      'configure maps a PlatformException to a typed PingException',
      () async {
        final api = _FakeHostApi()
          ..errorToThrow = PlatformException(
            code: 'DAVINCI_CONFIGURE_ERROR',
            message: 'DaVinciConfigMessage requires redirectUri.',
            details: 'argument',
          );

        await expectLater(
          DaVinciClient.configure(_config(), hostApi: api),
          throwsA(
            isA<PingException>()
                .having((e) => e.code, 'code', 'DAVINCI_CONFIGURE_ERROR')
                .having((e) => e.type, 'type', 'argument')
                .having(
                  (e) => e.message,
                  'message',
                  'DaVinciConfigMessage requires redirectUri.',
                ),
          ),
        );
      },
    );

    test(
      'a PlatformException without a string type maps to "unknown"',
      () async {
        final api = _FakeHostApi()..errorToThrow = PlatformException(code: 'X');

        await expectLater(
          DaVinciClient.configure(_config(), hostApi: api),
          throwsA(
            isA<PingException>().having((e) => e.type, 'type', 'unknown'),
          ),
        );
      },
    );
  });

  group('DaVinciClient.validate', () {
    ContinueNode form() =>
        NodeMapper.map(
              NodeMessage(
                type: NodeType.continueNode,
                collectors: [
                  CollectorMessage(
                    type: 'TEXT',
                    index: 0,
                    kind: CollectorKind.text,
                    key: 'user.username',
                    required: true,
                  ),
                  CollectorMessage(
                    type: 'PASSWORD_VERIFY',
                    index: 1,
                    kind: CollectorKind.password,
                    key: 'user.password',
                    required: true,
                  ),
                  CollectorMessage(
                    type: 'SUBMIT_BUTTON',
                    index: 2,
                    kind: CollectorKind.submit,
                    key: 'submit',
                  ),
                ],
              ),
            )
            as ContinueNode;

    ValidationErrorMessage error(
      int index,
      String type,
      ValidationErrorKind kind, {
      String? message,
      int? min,
      int? max,
      String? character,
    }) => ValidationErrorMessage(
      collectorType: type,
      index: index,
      kind: kind,
      message: message,
      min: min,
      max: max,
      character: character,
    );

    test('sends the values the app set, as next would', () async {
      final api = _FakeHostApi();
      final client = await DaVinciClient.configure(_config(), hostApi: api);
      final node = form();
      node.collectors.whereType<PasswordCollector>().single.value = 'secret';

      await client.validate(node);

      expect(api.lastValidateValues, hasLength(1));
      expect(api.lastValidateValues!.single!.type, 'PASSWORD_VERIFY');
      expect(api.lastValidateValues!.single!.value, 'secret');
    });

    test('every kind round-trips with its parameters', () async {
      final api = _FakeHostApi()
        ..validateResult = [
          error(0, 'TEXT', ValidationErrorKind.required),
          error(
            0,
            'TEXT',
            ValidationErrorKind.regex,
            message: 'Must be alphanumeric',
          ),
          error(
            1,
            'PASSWORD_VERIFY',
            ValidationErrorKind.invalidLength,
            min: 8,
            max: 255,
          ),
          error(
            1,
            'PASSWORD_VERIFY',
            ValidationErrorKind.invalidLength,
            min: 8,
          ),
          error(
            1,
            'PASSWORD_VERIFY',
            ValidationErrorKind.uniqueCharacter,
            min: 5,
          ),
          error(1, 'PASSWORD_VERIFY', ValidationErrorKind.maxRepeat, max: 2),
          error(
            1,
            'PASSWORD_VERIFY',
            ValidationErrorKind.minCharacters,
            min: 1,
            character: '0123456789',
          ),
        ];
      final client = await DaVinciClient.configure(_config(), hostApi: api);
      final node = form();

      final errors = await client.validate(node);

      final [username, password, _] = node.collectors;
      expect(errors, hasLength(7));
      expect(
        errors.take(2).every((e) => identical(e.collector, username)),
        isTrue,
      );
      expect(
        errors.skip(2).every((e) => identical(e.collector, password)),
        isTrue,
      );
      expect(errors[0], isA<RequiredError>());
      expect(errors[1], isA<RegexError>());
      expect(errors[1].message, 'Must be alphanumeric');
      final length = errors[2] as InvalidLengthError;
      expect((length.min, length.max), (8, 255));
      expect(length.message, 'Must be between 8 and 255 characters long.');
      final openEnded = errors[3] as InvalidLengthError;
      expect((openEnded.min, openEnded.max), (8, null));
      expect(openEnded.message, 'Must be at least 8 characters long.');
      expect((errors[4] as UniqueCharacterError).min, 5);
      expect((errors[5] as MaxRepeatError).max, 2);
      final characters = errors[6] as MinCharactersError;
      expect((characters.characters, characters.min), ('0123456789', 1));
    });

    test(
      'attaches the errors to their collectors, replacing the last run',
      () async {
        final api = _FakeHostApi()
          ..validateResult = [error(0, 'TEXT', ValidationErrorKind.required)];
        final client = await DaVinciClient.configure(_config(), hostApi: api);
        final node = form();
        final username = node.collectors[0] as TextCollector;
        final password = node.collectors[1] as PasswordCollector;

        await client.validate(node);
        expect(username.validationErrors.single, isA<RequiredError>());
        expect(password.validationErrors, isEmpty);

        api.validateResult = [
          error(
            1,
            'PASSWORD_VERIFY',
            ValidationErrorKind.uniqueCharacter,
            min: 5,
          ),
        ];
        await client.validate(node);
        expect(username.validationErrors, isEmpty);
        expect(password.validationErrors.single, isA<UniqueCharacterError>());
      },
    );

    test('leaves out errors that address no typed collector', () async {
      final api = _FakeHostApi()
        ..validateResult = [
          error(7, 'METADATA', ValidationErrorKind.required),
          error(0, 'PASSWORD', ValidationErrorKind.required),
        ];
      final client = await DaVinciClient.configure(_config(), hostApi: api);

      expect(await client.validate(form()), isEmpty);
    });

    test('surfaces a native failure as a PingException', () async {
      final api = _FakeHostApi();
      final client = await DaVinciClient.configure(_config(), hostApi: api);
      api.errorToThrow = PlatformException(
        code: 'DAVINCI_VALIDATE_ERROR',
        message: 'No active ContinueNode found',
        details: 'state',
      );

      expect(
        () => client.validate(form()),
        throwsA(
          isA<PingException>()
              .having((e) => e.code, 'code', 'DAVINCI_VALIDATE_ERROR')
              .having((e) => e.type, 'type', 'state'),
        ),
      );
    });
  });

  group('DaVinciClient post-success', () {
    late _FakeHostApi api;
    late DaVinciClient client;

    setUp(() async {
      api = _FakeHostApi()..configureResult = 'handle-9';
      client = await DaVinciClient.configure(_config(), hostApi: api);
    });

    test('getSession maps the authorization code', () async {
      api.sessionResult = SessionMessage(authorizationCode: 'code-1');

      final session = await client.getSession();

      expect(session?.authorizationCode, 'code-1');
      expect(api.calls, ['getSession:handle-9']);
    });

    test('getSession is null before a SuccessNode', () async {
      expect(await client.getSession(), isNull);
    });

    test('getSession rejects an empty code with a FormatException', () async {
      api.sessionResult = SessionMessage(authorizationCode: '');

      expect(client.getSession, throwsFormatException);
    });

    test('getToken maps every field', () async {
      api.tokenResult = TokenMessage(
        accessToken: 'access',
        tokenType: 'Bearer',
        scope: 'openid profile',
        expiresIn: 3599,
        refreshToken: 'refresh',
        idToken: 'id',
      );

      final token = await client.getToken();

      expect(token.toJson(), {
        'accessToken': 'access',
        'tokenType': 'Bearer',
        'scope': 'openid profile',
        'expiresIn': 3599,
        'refreshToken': 'refresh',
        'idToken': 'id',
      });
      expect(api.calls, ['getToken:handle-9']);
    });

    test(
      'getToken rejects an empty access token with a FormatException',
      () async {
        api.tokenResult = TokenMessage(accessToken: '', expiresIn: 1);

        expect(client.getToken, throwsFormatException);
      },
    );

    test(
      'getUserInfo passes cache: false unless asked, on every platform',
      () async {
        await client.getUserInfo();
        expect(api.lastUserInfoCache, isFalse);

        await client.getUserInfo(cache: true);
        expect(api.lastUserInfoCache, isTrue);
      },
    );

    test('getUserInfo keeps nested claims and drops null keys', () async {
      api.userInfoResult = <String?, Object?>{
        'sub': 'user-1',
        'address': <Object?, Object?>{'country': 'CA'},
        'groups': <Object?>['a', 'b'],
        null: 'ignored',
      };

      final claims = await client.getUserInfo();

      expect(claims, {
        'sub': 'user-1',
        'address': {'country': 'CA'},
        'groups': ['a', 'b'],
      });
      expect(() => claims['x'] = 1, throwsUnsupportedError);
    });

    test('signOff returns the native outcome', () async {
      expect(await client.signOff(), isTrue);
      api.signOffResult = false;
      expect(await client.signOff(), isFalse);
      expect(api.calls, ['signOff:handle-9', 'signOff:handle-9']);
    });

    // One row per post-success error code: native classifies, Dart carries code and type intact.
    final cases = <(String, String, Future<Object?> Function(DaVinciClient))>[
      ('DAVINCI_GET_SESSION_ERROR', 'auth', (c) => c.getSession()),
      ('DAVINCI_GET_TOKEN_ERROR', 'state', (c) => c.getToken()),
      ('DAVINCI_GET_TOKEN_ERROR', 'exchange', (c) => c.getToken()),
      ('DAVINCI_USERINFO_ERROR', 'network', (c) => c.getUserInfo()),
      ('DAVINCI_SIGN_OFF_ERROR', 'state', (c) => c.signOff()),
      ('DAVINCI_DISPOSE_ERROR', 'state', (c) => c.dispose()),
    ];
    for (final (code, type, call) in cases) {
      test('$code ($type) surfaces as a typed PingException', () async {
        api.errorToThrow = PlatformException(
          code: code,
          message: 'native message',
          details: type,
        );

        await expectLater(
          call(client),
          throwsA(
            isA<PingException>()
                .having((e) => e.code, 'code', code)
                .having((e) => e.type, 'type', type)
                .having((e) => e.message, 'message', 'native message'),
          ),
        );
      });
    }
  });

  group('DaVinciClient.poll', () {
    late _FakeHostApi api;
    late StreamController<PollingEventMessage> events;
    late DaVinciClient client;
    final polling =
        Collector.fromMessage(
              CollectorMessage(
                type: 'POLLING',
                index: 2,
                kind: CollectorKind.polling,
                key: 'polling-field',
              ),
            )
            as PollingCollector;

    setUp(() async {
      api = _FakeHostApi();
      events = StreamController<PollingEventMessage>.broadcast();
      client = await DaVinciClient.configure(
        _config(),
        hostApi: api,
        pollingEvents: events.stream,
      );
    });

    tearDown(() => events.close());

    /// Lets the listen-time `startPolling` call land.
    Future<String> started() async {
      await pumpEventQueue();
      return api.startedPollIds.last;
    }

    test(
      'starts the collector on listen and streams its statuses to the terminal one',
      () async {
        final statuses = <PollingStatus>[];
        final done = Completer<void>();
        client.poll(polling).listen(statuses.add, onDone: done.complete);
        final id = await started();

        expect(api.calls, contains('startPolling:davinci-1:POLLING:2'));
        events
          ..add(
            PollingEventMessage(
              pollId: 'someone-else',
              kind: PollingStatusKind.timedOut,
            ),
          )
          ..add(
            PollingEventMessage(
              pollId: id,
              kind: PollingStatusKind.continuing,
              retryCount: 1,
              maxRetries: 3,
            ),
          )
          ..add(
            PollingEventMessage(
              pollId: id,
              kind: PollingStatusKind.complete,
              status: 'approved',
            ),
          );
        await done.future;

        expect(statuses, const <PollingStatus>[
          PollingContinue(retryCount: 1, maxRetries: 3),
          PollingComplete('approved'),
        ]);
        expect(
          api.calls.where((c) => c.startsWith('cancelPolling')),
          isEmpty,
          reason: 'a poll that finished is already released natively',
        );
      },
    );

    test('cancelling the subscription cancels the native poll', () async {
      final subscription = client.poll(polling).listen((_) {});
      final id = await started();

      await subscription.cancel();

      expect(api.calls.last, 'cancelPolling:$id');
    });

    test('next ends a running poll, and still submits', () async {
      final done = Completer<void>();
      final statuses = <PollingStatus>[];
      client.poll(polling).listen(statuses.add, onDone: done.complete);
      final id = await started();

      await client.next(ContinueNode(collectors: [polling]));
      await done.future;
      events.add(
        PollingEventMessage(pollId: id, kind: PollingStatusKind.timedOut),
      );
      await pumpEventQueue();

      expect(statuses, isEmpty);
      expect(api.lastNextValues, isEmpty, reason: 'polling sets its own value');
    });

    test('start, signOff and dispose end running polls', () async {
      for (final advance in <Future<Object?> Function()>[
        client.start,
        client.signOff,
        client.dispose,
      ]) {
        final done = Completer<void>();
        client.poll(polling).listen((_) {}, onDone: done.complete);
        await started();
        await advance();
        await done.future;
      }
    });

    test('a failure to start is a PingException, then done', () async {
      api.startPollingError = PlatformException(
        code: 'DAVINCI_START_POLLING_ERROR',
        message: 'No active ContinueNode',
        details: 'state',
      );
      final errors = <Object>[];
      final done = Completer<void>();
      client
          .poll(polling)
          .listen((_) {}, onError: errors.add, onDone: done.complete);

      await done.future;

      expect(
        errors.single,
        isA<PingException>()
            .having((e) => e.code, 'code', 'DAVINCI_START_POLLING_ERROR')
            .having((e) => e.type, 'type', 'state'),
      );
    });

    test('each poll gets its own id', () async {
      client.poll(polling).listen((_) {});
      final first = await started();
      client.poll(polling).listen((_) {});
      final second = await started();

      expect(first, isNot(second));
    });
  });
}
