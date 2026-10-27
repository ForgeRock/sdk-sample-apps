/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'support/davinci_fixtures.dart';
import 'support/davinci_harness.dart';
import 'support/test_config.dart';

/// The leak check: start → poll → navigate away (cancel the subscription), five times on one
/// client, leaves the bridge holding no native polling task, and each round's poll is the only
/// one running. On iOS the SDK's own polling task outlives the cancel (see
/// `davinci_polling_cancel_test`); this counts the bridge's tasks, which the bridge can release.
///
/// Hermetic only: it needs five starts of the same scripted flow.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('repeated poll-and-leave holds no native polling task', (
    tester,
  ) async {
    if (E2eConfig.isLive) {
      markTestSkipped(
        'Hermetic only: it restarts one scripted flow five times.',
      );
      return;
    }
    const rounds = 5;
    final harness = await DaVinciHarness.create(
      liveAcr: '',
      hermeticAcr: 'polling',
      hermeticFlow: (baseUrl) => [
        for (var i = 0; i < rounds; i++) ...[
          DaVinciFixtures.pollingMenu(baseUrl),
          DaVinciFixtures.withPolling(
            DaVinciFixtures.pollingContinueForm(baseUrl),
            intervalMillis: 60000,
            retries: 3,
          ),
        ],
      ],
    );
    addTearDown(harness.dispose);
    final api = PingDaVinciHostApi();

    for (var round = 0; round < rounds; round++) {
      final menu = await harness.client.start() as ContinueNode;
      collectorWithKey<SubmitCollector>(
        menu,
        DaVinciFixtures.continuePollingBranch,
      ).select();
      final form = await harness.client.next(menu) as ContinueNode;
      final polling = form.collectors.whereType<PollingCollector>().single;

      final subscription = harness.client.poll(polling).listen((_) {});
      await _until(() async => await api.activePollCount() == 1);
      await subscription.cancel();

      expect(await api.activePollCount(), 0, reason: 'round $round');
    }
    harness.mock!.expectNoUnmatchedRequests();
  });
}

Future<void> _until(Future<bool> Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) fail('condition not met in 5s');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
