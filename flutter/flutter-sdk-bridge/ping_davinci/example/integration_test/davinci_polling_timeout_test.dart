/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'support/davinci_fixtures.dart';
import 'support/davinci_harness.dart';
import 'support/test_config.dart';

/// Pins the one `4xx` the native SDKs route differently (2.2.0): a `code: "timedOut"` response
/// is a `FailureNode` on iOS (`Transform.swift` checks `pollingValueTimedOut`) but a recoverable
/// `ErrorNode` on Android (`Transform.kt` checks only `1999` and `requestTimedOut`). The bridge
/// passes the native node type through, as RN v1.1.0 does.
///
/// **When this fails after an SDK bump, the platforms have aligned:** update the `ErrorNode` /
/// `FailureNode` docs and the README's platform differences, then flip the assertion.
///
/// Hermetic only: no tenant times out on request.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
// TODO(SDKS-5461): flip the assertion once the native SDKs classify the timeout the same way.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a polling timeout keeps its native node type', (tester) async {
    if (E2eConfig.isLive) {
      markTestSkipped(
        'Hermetic only: the scripted timeout body is the thing under test, and no tenant '
        'times out on request.',
      );
      return;
    }
    final harness = await DaVinciHarness.create(
      liveAcr: E2eConfig.acrSso,
      hermeticAcr: 'sso',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.ssoMenu(baseUrl),
        DaVinciFixtures.pollingTimedOut(),
      ],
    );
    addTearDown(harness.dispose);

    final start = await harness.client.start();
    expect(start, isA<ContinueNode>(), reason: harness.diagnose(start));
    collectorWithKey<SubmitCollector>(
      start as ContinueNode,
      DaVinciFixtures.signOnButton,
    ).select();

    final timedOut = await harness.client.next(start);

    if (Platform.isIOS) {
      expect(timedOut, isA<FailureNode>(), reason: harness.diagnose(timedOut));
    } else {
      expect(timedOut, isA<ErrorNode>(), reason: harness.diagnose(timedOut));
      expect((timedOut as ErrorNode).input['code'], 'timedOut');
      expect(timedOut.continueNode, isNotNull);
    }
    harness.mock!.expectNoUnmatchedRequests();
  });
}
