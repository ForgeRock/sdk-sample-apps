/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

void main() {
  group('PollingStatus.fromMessage', () {
    PollingStatus map(
      PollingStatusKind kind, {
      int? retryCount,
      int? maxRetries,
      String? status,
      String? errorMessage,
    }) => PollingStatus.fromMessage(
      PollingEventMessage(
        pollId: 'p',
        kind: kind,
        retryCount: retryCount,
        maxRetries: maxRetries,
        status: status,
        errorMessage: errorMessage,
      ),
    );

    test('maps all five cases', () {
      expect(
        map(PollingStatusKind.continuing, retryCount: 2, maxRetries: 3),
        const PollingContinue(retryCount: 2, maxRetries: 3),
      );
      expect(map(PollingStatusKind.timedOut), const PollingTimedOut());
      expect(map(PollingStatusKind.expired), const PollingExpired());
      expect(
        map(PollingStatusKind.error, errorMessage: 'Server error: 500'),
        const PollingError('Server error: 500'),
      );
      expect(
        map(PollingStatusKind.complete, status: 'approved'),
        const PollingComplete('approved'),
      );
    });

    test('only continue is not terminal', () {
      expect(
        PollingStatusKind.values.where(
          (kind) => !map(kind, status: '', errorMessage: '').isTerminal,
        ),
        [PollingStatusKind.continuing],
      );
    });

    test('missing fields fall back instead of throwing', () {
      expect(
        map(PollingStatusKind.continuing),
        const PollingContinue(retryCount: 0, maxRetries: 0),
      );
      expect(
        map(PollingStatusKind.error),
        const PollingError('Polling failed'),
      );
      expect(map(PollingStatusKind.complete), const PollingComplete(''));
    });
  });
}
