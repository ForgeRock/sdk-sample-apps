/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'support/davinci_fixtures.dart';
import 'support/davinci_harness.dart';
import 'support/test_config.dart';

/// Disposing the client mid-poll ends the poll's stream with no terminal status, and the bridge
/// lets go of its native task. What the native SDK does next is pinned per platform, through the
/// mock's request log:
///
/// - **Android** stops polling: cancelling the collecting coroutine cancels the SDK's cold
///   `Flow`, so no status request follows.
/// - **iOS** can't: `PollingCollector.poll()` runs in an unstructured `Task {}` nobody can
///   cancel, so it goes on requesting until its retries run out, reporting nothing.
///
/// **When the iOS half fails after an SDK bump, iOS can cancel a poll:** update
/// `DaVinciPolling.swift`, `DaVinciClient.poll`'s doc and the README, then assert as for Android.
///
/// Hermetic only: the request log is the instrument.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('disposing mid-poll ends the stream and releases the poll', (
    tester,
  ) async {
    if (E2eConfig.isLive) {
      markTestSkipped('Hermetic only: the mock request log is the instrument.');
      return;
    }
    const interval = Duration(milliseconds: 150);
    const retries = 20;
    final harness = await DaVinciHarness.create(
      liveAcr: '',
      hermeticAcr: 'polling',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.pollingMenu(baseUrl),
        DaVinciFixtures.withPolling(
          DaVinciFixtures.pollingChallengeForm(baseUrl),
          intervalMillis: interval.inMilliseconds,
          retries: retries,
        ),
      ],
      challengeStatus: [DaVinciFixtures.challengeStatus()],
    );
    final mock = harness.mock!;
    addTearDown(mock.stop);

    final menu = await harness.client.start() as ContinueNode;
    collectorWithKey<FlowCollector>(
      menu,
      DaVinciFixtures.challengePollingBranch,
    ).select();
    final form = await harness.client.next(menu) as ContinueNode;
    final polling = form.collectors.whereType<PollingCollector>().single;

    final statuses = <PollingStatus>[];
    final done = Completer<void>();
    final firstAttempt = Completer<void>();
    harness.client.poll(polling).listen((status) {
      statuses.add(status);
      if (!firstAttempt.isCompleted) firstAttempt.complete();
    }, onDone: done.complete);
    await firstAttempt.future.timeout(const Duration(seconds: 10));
    expect(await PingDaVinciHostApi().activePollCount(), 1);

    await harness.client.dispose();
    await done.future.timeout(const Duration(seconds: 5));

    expect(statuses, everyElement(isA<PollingContinue>()));
    expect(await PingDaVinciHostApi().activePollCount(), 0);
    final atDispose = mock.challengeStatusRequests.length;
    await Future<void>.delayed(interval * 4);
    final after = mock.challengeStatusRequests.length;
    if (Platform.isIOS) {
      expect(
        after,
        greaterThan(atDispose),
        reason: 'iOS 2.2.0 cannot cancel the SDK\'s polling task',
      );
    } else {
      expect(after, atDispose, reason: 'Android stops with the coroutine');
    }
    expect(statuses.length, lessThan(retries));
  });
}
