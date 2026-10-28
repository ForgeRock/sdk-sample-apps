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

/// A `FlowCollector` (`FLOW_BUTTON`, registry key `ACTION`) navigates the flow with `eventType`
/// `action`, distinct from a submit button's `submit`. The branch it opens is the agreement form,
/// whose `READ_ONLY_TEXT` carries its display fields, whose key-less `ERROR_DISPLAY` is reported
/// as ignorable, and whose submit leaves the agreement out of the payload. Runs in both modes.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a flow button takes the flow down its branch', (tester) async {
    final skipReason = E2eConfig.liveConfigSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.create(
      liveAcr: E2eConfig.acrFormFields,
      hermeticAcr: 'form-fields',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.formFieldsMenu(baseUrl),
        DaVinciFixtures.agreementForm(baseUrl),
        DaVinciFixtures.formFieldsSubmitted(baseUrl),
      ],
    );
    addTearDown(harness.dispose);

    final menu = await harness.client.start();
    expect(menu, isA<ContinueNode>(), reason: harness.diagnose(menu));
    collectorWithKey<FlowCollector>(
      menu as ContinueNode,
      DaVinciFixtures.agreementBranch,
    ).select();

    final agreementForm = await harness.client.next(menu);

    expect(
      agreementForm,
      isA<ContinueNode>(),
      reason: harness.diagnose(agreementForm),
    );
    agreementForm as ContinueNode;
    expect(agreementForm.id, isNot(menu.id));
    final agreement = agreementForm.collectors
        .whereType<ReadOnlyTextCollector>()
        .single;
    expect(agreement.type, 'AGREEMENT');
    expect(agreement.content, isNotEmpty);
    expect(agreement.toValue(), isNull);
    expect(
      agreementForm.unsupportedFields.map((f) => (f.type, f.reason)),
      contains(('ERROR_DISPLAY', UnsupportedFieldReason.knownIgnorable)),
    );

    agreementForm.collectors.whereType<BooleanCollector>().single.value = true;
    agreementForm.collectors.whereType<SubmitCollector>().single.select();
    final next = await harness.client.next(agreementForm);

    expect(next, isNot(isA<FailureNode>()), reason: harness.diagnose(next));
    expect(next, isNot(isA<ErrorNode>()), reason: harness.diagnose(next));
    final mock = harness.mock;
    if (mock != null) {
      mock.expectNoUnmatchedRequests();
      final [_, choose, submit] = mock.flowRequests;
      expect((choose.json?['parameters'] as Map)['eventType'], 'action');
      expect(
        choose.submittedData?['actionKey'],
        DaVinciFixtures.agreementBranch,
      );
      expect((submit.json?['parameters'] as Map)['eventType'], 'submit');
      expect(submit.submittedData?['formData'], {'agreement-checkbox': true});
    }
  });
}
