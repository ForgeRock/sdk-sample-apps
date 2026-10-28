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

/// A challenge-mode poll streams the same normalized sequence on both platforms: a
/// `PollingContinue` per incomplete attempt, then the completed status. Hermetically the mock
/// answers the status endpoint "pending, pending, approved", so the sequence is asserted exactly
/// — Android's `Flow` emits it as is, iOS's `AsyncStream` only after the bridge drops the
/// `continue` iOS sends before the completing request. The poll's value is then submitted with
/// the `polling` event type.
///
/// Live, the test approves the challenge the way ping-android-sdk's `PollingCollectorE2ETests`
/// does: once the first attempt comes back incomplete it opens the magic link the form's label
/// carries. The tenant allows three attempts two seconds apart, so a slow approval times out.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a challenge poll continues, then completes', (tester) async {
    final skipReason = E2eConfig.liveFlowSkipReason(
      E2eConfig.acrPolling,
      'E2E_ACR_POLLING',
    );
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.create(
      liveAcr: E2eConfig.acrPolling,
      hermeticAcr: 'polling',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.pollingMenu(baseUrl),
        DaVinciFixtures.withPolling(
          DaVinciFixtures.pollingChallengeForm(baseUrl),
          intervalMillis: 100,
          retries: 5,
        ),
        DaVinciFixtures.pollingDone(baseUrl),
      ],
      challengeStatus: [
        DaVinciFixtures.challengeStatus(),
        DaVinciFixtures.challengeStatus(),
        DaVinciFixtures.challengeStatus(completedWith: 'approved'),
      ],
    );
    addTearDown(harness.dispose);

    final menu = await harness.client.start();
    expect(menu, isA<ContinueNode>(), reason: harness.diagnose(menu));
    collectorWithKey<FlowCollector>(
      menu as ContinueNode,
      DaVinciFixtures.challengePollingBranch,
    ).select();
    final form = await harness.client.next(menu);
    expect(form, isA<ContinueNode>(), reason: harness.diagnose(form));
    form as ContinueNode;
    final polling = form.collectors.whereType<PollingCollector>().single;
    expect(polling.pollChallengeStatus, isTrue);
    expect(polling.challenge, isNotEmpty);

    final statuses = <PollingStatus>[];
    var approved = false;
    await for (final status in harness.client.poll(polling)) {
      statuses.add(status);
      if (!harness.isHermetic && status is PollingContinue && !approved) {
        approved = true;
        await _approve(form);
      }
    }

    if (harness.isHermetic) {
      expect(statuses, <PollingStatus>[
        const PollingContinue(retryCount: 1, maxRetries: 5),
        const PollingContinue(retryCount: 2, maxRetries: 5),
        const PollingComplete('approved'),
      ]);
    } else {
      expect(statuses.last, const PollingComplete('approved'));
      final progress = statuses.take(statuses.length - 1).toList();
      expect(progress, everyElement(isA<PollingContinue>()));
      expect(
        progress.cast<PollingContinue>().map((s) => s.retryCount),
        List<int>.generate(progress.length, (i) => i + 1),
      );
    }

    final done = await harness.client.next(form);
    expect(done, isA<ContinueNode>(), reason: harness.diagnose(done));
    expect(
      (done as ContinueNode).collectors.whereType<LabelCollector>().map(
        (label) => label.content,
      ),
      contains(harness.isHermetic ? 'Message: Done' : 'Message: approved'),
    );

    final mock = harness.mock;
    if (mock == null) return;
    mock.expectNoUnmatchedRequests();
    final polls = mock.challengeStatusRequests;
    expect(polls, hasLength(3));
    expect(
      polls.first.path,
      endsWith(
        '/davinci/user/credentials/challenge/${polling.challenge}/status',
      ),
    );
    expect(
      polls.map((r) => r.headers['interactionid']),
      everyElement('scrubbed'),
    );
    final submit = mock.flowRequests.last;
    expect((submit.json?['parameters'] as Map)['eventType'], 'polling');
    expect(submit.submittedData?['formData'], {'polling-field': 'approved'});
    expect(submit.submittedData?.containsKey('actionKey'), isFalse);
  });
}

/// Opens the out-of-band approval link that [form]'s `Number Challenge <url>` label carries.
Future<void> _approve(ContinueNode form) async {
  const prefix = 'Number Challenge ';
  final link = form.collectors
      .whereType<LabelCollector>()
      .map((label) => label.content)
      .firstWhere((content) => content.startsWith(prefix))
      .substring(prefix.length)
      .trim();
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(Uri.parse(link))).close();
    await response.drain<void>();
  } finally {
    client.close(force: true);
  }
}
