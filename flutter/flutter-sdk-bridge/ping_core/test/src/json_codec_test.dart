/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_core/ping_core.dart';

void main() {
  group('JsonCodec.decodeElement', () {
    test('passes through primitives unchanged', () {
      expect(JsonCodec.decodeElement(null), isNull);
      expect(JsonCodec.decodeElement('a string'), 'a string');
      expect(JsonCodec.decodeElement(42), 42);
      expect(JsonCodec.decodeElement(true), true);
    });

    test('normalizes a nested Map<Object?, Object?>', () {
      final result = JsonCodec.decodeElement(<Object?, Object?>{
        'key': 'value',
      });
      expect(result, isA<Map<String, Object?>>());
      expect(result, {'key': 'value'});
    });

    test('normalizes a nested List<Object?>', () {
      final result = JsonCodec.decodeElement(<Object?>[1, 2, 3]);
      expect(result, isA<List<Object?>>());
      expect(result, [1, 2, 3]);
    });
  });

  group('JsonCodec.decodeObject', () {
    test('converts a flat Map<Object?, Object?> to Map<String, Object?>', () {
      final result = JsonCodec.decodeObject(<Object?, Object?>{
        'name': 'Alice',
        'age': 30,
      });
      expect(result, isA<Map<String, Object?>>());
      expect(result, {'name': 'Alice', 'age': 30});
    });

    test('recursively normalizes nested maps', () {
      final result = JsonCodec.decodeObject(<Object?, Object?>{
        'user': <Object?, Object?>{'name': 'Alice', 'age': 30},
      });
      expect(result['user'], isA<Map<String, Object?>>());
      expect(result['user'], {'name': 'Alice', 'age': 30});
    });

    test('recursively normalizes lists of maps', () {
      final result = JsonCodec.decodeObject(<Object?, Object?>{
        'items': <Object?>[
          <Object?, Object?>{'id': 1},
          <Object?, Object?>{'id': 2},
        ],
      });
      final items = result['items'] as List<Object?>;
      expect(items, hasLength(2));
      expect(items[0], isA<Map<String, Object?>>());
      expect(items[0], {'id': 1});
      expect(items[1], {'id': 2});
    });

    test('recursively normalizes maps nested inside lists nested inside maps', () {
      final result = JsonCodec.decodeObject(<Object?, Object?>{
        'groups': <Object?>[
          <Object?, Object?>{
            'members': <Object?>[
              <Object?, Object?>{'name': 'Bob'},
            ],
          },
        ],
      });
      final groups = result['groups'] as List<Object?>;
      final firstGroup = groups[0] as Map<String, Object?>;
      final members = firstGroup['members'] as List<Object?>;
      expect(members[0], isA<Map<String, Object?>>());
      expect(members[0], {'name': 'Bob'});
    });

    test('preserves null values', () {
      final result = JsonCodec.decodeObject(<Object?, Object?>{
        'value': null,
      });
      expect(result['value'], isNull);
      expect(result.containsKey('value'), isTrue);
    });

    test('handles an empty map', () {
      expect(JsonCodec.decodeObject(<Object?, Object?>{}), <String, Object?>{});
    });
  });

  group('JsonCodec.decodeArray', () {
    test('returns a plain list unchanged for primitives', () {
      expect(JsonCodec.decodeArray(<Object?>['a', 1, true, null]), [
        'a',
        1,
        true,
        null,
      ]);
    });

    test('recursively normalizes maps within the list', () {
      final result = JsonCodec.decodeArray(<Object?>[
        <Object?, Object?>{'key': 'value'},
      ]);
      expect(result[0], isA<Map<String, Object?>>());
      expect(result[0], {'key': 'value'});
    });

    test('handles an empty list', () {
      expect(JsonCodec.decodeArray(<Object?>[]), <Object?>[]);
    });
  });
}
