/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_device_profile/ping_device_profile.dart';
import 'package:ping_device_profile/src/messages.g.dart';
import 'package:ping_journey/ping_journey.dart';
import 'package:ping_journey/src/node_mapper.dart';

/// Fake [PingDeviceProfileHostApi]: overrides every method instead of hitting a platform channel,
/// so [DeviceProfileCallback] can be exercised without a native bridge.
class _FakeHostApi extends PingDeviceProfileHostApi {
  String? lastJourneyId;
  int? lastCallbackIndex;
  Map<String?, Object?>? collectResult;
  Object? collectError;

  @override
  Future<Map<String?, Object?>> collect(String journeyId, int callbackIndex) async {
    if (collectError != null) throw collectError!;
    lastJourneyId = journeyId;
    lastCallbackIndex = callbackIndex;
    return collectResult ?? <String?, Object?>{};
  }
}

CallbackMessage _message({int index = 0, Map<String?, Object?>? raw}) =>
    CallbackMessage(type: 'DeviceProfileCallback', index: index)..raw = raw;

/// Builds a callback bound to [hostApi] the way `NodeMapper` does after [registerWith], so the
/// tests exercise the registered factory path rather than the constructor alone.
DeviceProfileCallback _mapped({int index = 0, Map<String?, Object?>? raw}) =>
    NodeMapper.mapCallback(_message(index: index, raw: raw), journeyId: 'journey-1')
        as DeviceProfileCallback;

DeviceProfileCallback _withHost(_FakeHostApi hostApi, {int index = 0}) =>
    DeviceProfileCallback(_message(index: index), 'journey-1', hostApi: hostApi);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('registration', () {
    test('registerWith makes NodeMapper produce a DeviceProfileCallback', () {
      DeviceProfileCallback.registerWith();

      final callback =
          NodeMapper.mapCallback(_message()..prompt = 'Collecting', journeyId: 'journey-9')
              as DeviceProfileCallback;

      expect(callback.journeyId, 'journey-9');
      expect(callback.prompt, 'Collecting');
    });

    test('registerWith is idempotent', () {
      DeviceProfileCallback.registerWith();
      DeviceProfileCallback.registerWith();

      expect(NodeMapper.mapCallback(_message(), journeyId: 'j'), isA<DeviceProfileCallback>());
    });
  });

  group('display fields from raw', () {
    test('parses metadata, location and message from the output array', () {
      final callback = _mapped(
        raw: <String?, Object?>{
          'output': <Object?>[
            <String?, Object?>{'name': 'metadata', 'value': true},
            <String?, Object?>{'name': 'location', 'value': false},
            <String?, Object?>{'name': 'message', 'value': 'Profiling your device'},
          ],
        },
      );

      expect(callback.metadata, isTrue);
      expect(callback.location, isFalse);
      expect(callback.message, 'Profiling your device');
    });

    test('defaults to false/empty when raw has no output array', () {
      final callback = _mapped();

      expect(callback.metadata, isFalse);
      expect(callback.location, isFalse);
      expect(callback.message, isEmpty);
    });

    test('defaults to false when a flag is absent from the output array', () {
      final callback = _mapped(
        raw: <String?, Object?>{
          'output': <Object?>[
            <String?, Object?>{'name': 'metadata', 'value': true},
          ],
        },
      );

      expect(callback.metadata, isTrue);
      expect(callback.location, isFalse);
    });
  });

  group('collect', () {
    test('calls the host API with the journeyId and the callback index', () async {
      final hostApi = _FakeHostApi()
        ..collectResult = <String?, Object?>{'identifier': 'device-1'};
      final callback = _withHost(hostApi, index: 2);

      final profile = await callback.collect();

      expect(hostApi.lastJourneyId, 'journey-1');
      expect(hostApi.lastCallbackIndex, 2);
      expect(profile, {'identifier': 'device-1'});
    });

    test('returns a nested profile unchanged', () async {
      final hostApi = _FakeHostApi()
        ..collectResult = <String?, Object?>{
          'identifier': 'device-1',
          'metadata': <String?, Object?>{'model': 'Pixel 8'},
          'sensors': <Object?>[
            <String?, Object?>{'name': 'gps'},
          ],
        };
      final callback = _withHost(hostApi);

      final profile = await callback.collect();

      expect(profile['identifier'], 'device-1');
      expect((profile['metadata'] as Map)['model'], 'Pixel 8');
      expect(((profile['sensors'] as List).first as Map)['name'], 'gps');
    });

    test('a PlatformException becomes a typed PingException', () async {
      final hostApi = _FakeHostApi()
        ..collectError = PlatformException(
          code: 'DEVICE_PROFILE_COLLECT_ERROR',
          message: 'denied',
          details: 'permission',
        );
      final callback = _withHost(hostApi);

      await expectLater(
        callback.collect(),
        throwsA(
          isA<PingException>()
            .having((e) => e.code, 'code', 'DEVICE_PROFILE_COLLECT_ERROR')
            .having((e) => e.type, 'type', 'permission')
            .having((e) => e.message, 'message', 'denied'),
        ),
      );
    });

    test('a non-string details falls back to type unknown', () async {
      final hostApi = _FakeHostApi()
        ..collectError = PlatformException(code: 'DEVICE_PROFILE_COLLECT_ERROR', details: 42);
      final callback = _withHost(hostApi);

      await expectLater(
        callback.collect(),
        throwsA(isA<PingException>().having((e) => e.type, 'type', 'unknown')),
      );
    });
  });

  group('add-on contract', () {
    test('submits nothing: toValue is null so next() carries the native result', () {
      final callback = _mapped();

      expect(callback.toValue(), isNull);
    });
  });
}
