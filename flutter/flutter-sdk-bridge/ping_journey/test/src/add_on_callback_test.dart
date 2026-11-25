/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';
import 'package:ping_journey/src/node_mapper.dart';

/// A minimal add-on callback, as an add-on package would declare it.
final class _FakeAddOnCallback extends AddOnCallback {
  _FakeAddOnCallback(super.message, super.journeyId);
}

CallbackMessage _message(
  String type, {
  int index = 0,
  String? prompt,
  Map<String?, Object?>? raw,
}) => CallbackMessage(type: type, index: index)
  ..prompt = prompt
  ..raw = raw;

const _journeyId = 'journey-1';

Callback _mapCallback(CallbackMessage message) =>
    NodeMapper.mapCallback(message, journeyId: _journeyId);

void main() {
  // The add-on registry is process-wide, so every test uses a type name of its own.
  group('Callback.registerAddOn', () {
    test(
      'an unregistered type still maps to the placeholder TextOutputCallback',
      () {
        final callback = _mapCallback(_message('UnregisteredAddOnCallback'));

        expect(callback, isA<TextOutputCallback>());
        expect(
          (callback as TextOutputCallback).message,
          'Unsupported callback: UnregisteredAddOnCallback',
        );
      },
    );

    test('a registered type maps to the add-on subclass', () {
      Callback.registerAddOn('MapsAddOnCallback', _FakeAddOnCallback.new);

      final callback = _mapCallback(
        _message('MapsAddOnCallback', index: 2, prompt: 'Collecting'),
      );

      expect(callback, isA<AddOnCallback>());
      expect(callback, isA<_FakeAddOnCallback>());
      expect(callback.type, 'MapsAddOnCallback');
      expect(callback.index, 2);
      expect(callback.prompt, 'Collecting');
    });

    test('the add-on callback carries the journeyId of its node', () {
      Callback.registerAddOn(
        'JourneyIdAddOnCallback',
        (message, journeyId) => _FakeAddOnCallback(message, journeyId),
      );

      final node =
          NodeMapper.map(
                NodeMessage(type: NodeType.continueNode)
                  ..callbacks = [_message('JourneyIdAddOnCallback')],
                'journey-42',
              )
              as ContinueNode;

      final callback = node.callbacks.single as AddOnCallback;
      expect(callback.journeyId, 'journey-42');
    });

    test(
      'raw carries the native JSON with nested maps and lists normalized',
      () {
        Callback.registerAddOn('RawAddOnCallback', _FakeAddOnCallback.new);

        final callback =
            _mapCallback(
                  _message(
                    'RawAddOnCallback',
                    raw: <String?, Object?>{
                      'type': 'RawAddOnCallback',
                      'output': <Object?>[
                        <Object?, Object?>{'name': 'metadata', 'value': true},
                      ],
                    },
                  ),
                )
                as AddOnCallback;

        expect(callback.raw['type'], 'RawAddOnCallback');
        final output = callback.raw['output']! as List<Object?>;
        expect(output.single, isA<Map<String, Object?>>());
        expect((output.single! as Map<String, Object?>)['name'], 'metadata');
      },
    );

    test('raw is empty when the message carries none', () {
      Callback.registerAddOn('NoRawAddOnCallback', _FakeAddOnCallback.new);

      final callback =
          _mapCallback(_message('NoRawAddOnCallback')) as AddOnCallback;

      expect(callback.raw, isEmpty);
    });

    test('an add-on callback submits nothing by default', () {
      Callback.registerAddOn('ValueAddOnCallback', _FakeAddOnCallback.new);

      final callback = _mapCallback(_message('ValueAddOnCallback'));

      expect(callback.toValue(), isNull);
    });

    test('a later registration for the same type replaces the earlier one', () {
      Callback.registerAddOn('ReplacedAddOnCallback', _FakeAddOnCallback.new);
      Callback.registerAddOn('ReplacedAddOnCallback', _OtherAddOnCallback.new);

      expect(
        _mapCallback(_message('ReplacedAddOnCallback')),
        isA<_OtherAddOnCallback>(),
      );
    });

    test('a core callback type cannot be registered as an add-on', () {
      for (final type in CallbackType.all) {
        expect(
          () => Callback.registerAddOn(type, _FakeAddOnCallback.new),
          throwsArgumentError,
          reason: type,
        );
      }
    });

    test('a core type is not routed to the registry', () {
      final callback = _mapCallback(
        _message(CallbackType.nameCallback, prompt: 'User Name'),
      );

      expect(callback, isA<NameCallback>());
    });

    test(
      'an error thrown by the factory propagates instead of falling back',
      () {
        Callback.registerAddOn(
          'ThrowingAddOnCallback',
          (message, journeyId) => throw StateError('bad add-on'),
        );

        expect(
          () => _mapCallback(_message('ThrowingAddOnCallback')),
          throwsStateError,
        );
      },
    );

    test(
      'a node mixes core and add-on callbacks, indexing each type separately',
      () {
        Callback.registerAddOn('NodeAddOnCallback', _FakeAddOnCallback.new);

        final node =
            NodeMapper.map(
                  NodeMessage(type: NodeType.continueNode)
                    ..callbacks = [
                      _message('NameCallback'),
                      _message('NodeAddOnCallback', index: 0),
                      _message('NodeAddOnCallback', index: 1),
                    ],
                  'journey-1',
                )
                as ContinueNode;

        expect(node.callbacks, hasLength(3));
        expect(node.callbacks[0], isA<NameCallback>());
        expect(node.callbacks[1], isA<AddOnCallback>());
        expect(node.callbacks[2].index, 1);
        expect(
          node.callbacks
              .map((callback) => callback.toValue())
              .whereType<CallbackValueMessage>(),
          hasLength(1),
          reason: 'only the NameCallback contributes a value to next()',
        );
      },
    );
  });
}

final class _OtherAddOnCallback extends AddOnCallback {
  _OtherAddOnCallback(super.message, super.journeyId);
}
