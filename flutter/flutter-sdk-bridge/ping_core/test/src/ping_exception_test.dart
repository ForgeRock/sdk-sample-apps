/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_core/ping_core.dart';

void main() {
  group('PingException', () {
    test('exposes code, type, and message from the constructor', () {
      const exception = PingException(
        'JOURNEY_START_ERROR',
        'state',
        'No active ContinueNode',
      );
      expect(exception.code, 'JOURNEY_START_ERROR');
      expect(exception.type, 'state');
      expect(exception.message, 'No active ContinueNode');
    });

    test('toString includes code, type, and message', () {
      const exception = PingException('CODE', 'type', 'message');
      expect(
        exception.toString(),
        'PingException(code: CODE, type: type, message: message)',
      );
    });

    test('implements Exception', () {
      const exception = PingException('CODE', 'type', 'message');
      expect(exception, isA<Exception>());
    });
  });
}
