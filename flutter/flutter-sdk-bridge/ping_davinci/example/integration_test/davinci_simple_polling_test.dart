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

/// A simple-mode poll is one `PollingComplete('continue')` per cycle on both platforms (iOS's
/// extra leading `continue` is dropped by the bridge). Submitting it makes the server rewind to
/// the same form, which both SDKs rebuild with `retriesAllowed` one lower; the form's "Finish"
/// button then ends the branch. Runs in both modes: live, each cycle waits the tenant's 2 s.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('simple polling cycles through rewinds, then finishes', (
    tester,
  ) async {
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
          DaVinciFixtures.pollingContinueForm(baseUrl),
          intervalMillis: 100,
          retries: 3,
        ),
        DaVinciFixtures.pollingContinueSubmitted(baseUrl),
        DaVinciFixtures.pollingDone(baseUrl),
      ],
    );
    addTearDown(harness.dispose);

    final menu = await harness.client.start();
    expect(menu, isA<ContinueNode>(), reason: harness.diagnose(menu));
    collectorWithKey<SubmitCollector>(
      menu as ContinueNode,
      DaVinciFixtures.continuePollingBranch,
    ).select();
    final form = await harness.client.next(menu);
    expect(form, isA<ContinueNode>(), reason: harness.diagnose(form));
    form as ContinueNode;
    final polling = form.collectors.whereType<PollingCollector>().single;
    expect(polling.pollChallengeStatus, isFalse);
    expect((polling.pollRetries, polling.retriesAllowed), (3, 3));

    expect(await harness.client.poll(polling).toList(), const <PollingStatus>[
      PollingComplete('continue'),
    ]);

    final rewound = await harness.client.next(form);
    expect(rewound, isA<ContinueNode>(), reason: harness.diagnose(rewound));
    rewound as ContinueNode;
    final again = rewound.collectors.whereType<PollingCollector>().single;
    expect(again.key, 'polling-field');
    expect(again.retriesAllowed, 2, reason: 'carried across the rewind');

    collectorWithKey<FlowCollector>(
      rewound,
      DaVinciFixtures.finishButton,
    ).select();
    final done = await harness.client.next(rewound);
    expect(done, isA<ContinueNode>(), reason: harness.diagnose(done));
    expect(
      (done as ContinueNode).collectors.whereType<LabelCollector>().map(
        (label) => label.content,
      ),
      contains('Message: Done'),
    );

    final mock = harness.mock;
    if (mock == null) return;
    mock.expectNoUnmatchedRequests();
    final [..., cycle, finish] = mock.flowRequests;
    expect((cycle.json?['parameters'] as Map)['eventType'], 'polling');
    expect(cycle.submittedData?['formData'], {'polling-field': 'continue'});
    expect(finish.submittedData?['actionKey'], DaVinciFixtures.finishButton);
  });
}
