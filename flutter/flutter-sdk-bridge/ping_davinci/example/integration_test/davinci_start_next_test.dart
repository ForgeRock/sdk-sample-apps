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

/// `start()` returns the flow's first `ContinueNode` with its form metadata and collectors, and
/// `next()` submits a menu choice and advances to a different node. Runs in both modes.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('start returns a form, and next advances past it', (
    tester,
  ) async {
    final skipReason = E2eConfig.liveConfigSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.formFields();
    addTearDown(harness.dispose);

    final menu = await harness.client.start();
    expect(menu, isA<ContinueNode>(), reason: harness.diagnose(menu));
    menu as ContinueNode;
    expect(menu.name, isNotEmpty);
    expect(menu.collectors, isNotEmpty);
    expect(
      menu.collectors.map((c) => c.index),
      List<int>.generate(menu.collectors.length, (i) => i),
      reason: 'collectors are addressed by their position',
    );

    collectorWithKey<ButtonCollector>(
      menu,
      DaVinciFixtures.formFieldsBranch,
    ).select();
    final form = await harness.client.next(menu);

    expect(form, isA<ContinueNode>(), reason: harness.diagnose(form));
    form as ContinueNode;
    expect(form.id, isNot(menu.id));
    expect(form.name, isNot(menu.name));
    expect(
      form.collectors.map((c) => c.type),
      containsAll(<String>['TEXT', 'SUBMIT_BUTTON']),
    );

    final mock = harness.mock;
    if (mock != null) {
      mock.expectNoUnmatchedRequests();
      final [authorize, submit] = mock.flowRequests;
      expect(authorize.query['response_mode'], 'pi.flow');
      expect(authorize.query['acr_values'], 'form-fields');
      expect(authorize.headers['x-requested-with'], 'ping-sdk');
      expect(submit.json?['id'], menu.id);
      expect(
        submit.submittedData?['actionKey'],
        DaVinciFixtures.formFieldsBranch,
      );
    }
  });
}
