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

/// A registration-style form exercising select, multi-select, boolean and phone-number
/// collectors submits successfully: the server accepts every value and moves on. Runs in both
/// modes — the live tenant's `Form Fields` form is reachable anonymously.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('select, boolean and phone-number values submit', (tester) async {
    final skipReason = E2eConfig.liveConfigSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.formFields(
      then: (baseUrl) => [DaVinciFixtures.formFieldsSubmitted(baseUrl)],
    );
    addTearDown(harness.dispose);

    final menu = await harness.client.start();
    expect(menu, isA<ContinueNode>(), reason: harness.diagnose(menu));
    collectorWithKey<ButtonCollector>(
      menu as ContinueNode,
      DaVinciFixtures.formFieldsBranch,
    ).select();
    final form = await harness.client.next(menu);
    expect(form, isA<ContinueNode>(), reason: harness.diagnose(form));
    form as ContinueNode;

    form.collectors.whereType<TextCollector>().single.value = 'Flutter';
    for (final select in form.collectors.whereType<SingleSelectCollector>()) {
      select.value = select.options.last.value;
    }
    for (final multi in form.collectors.whereType<MultiSelectCollector>()) {
      multi.value = [multi.options.first.value];
    }
    // The server validates the number, so this is libphonenumber's example US number.
    form.collectors.whereType<PhoneNumberCollector>().single.value =
        const PhoneNumberValue(countryCode: 'US', phoneNumber: '2015550123');
    form.collectors.whereType<BooleanCollector>().single.value = true;
    form.collectors.whereType<SubmitCollector>().single.select();

    final next = await harness.client.next(form);

    expect(next, isA<ContinueNode>(), reason: harness.diagnose(next));
    expect((next as ContinueNode).id, isNot(form.id));
    final mock = harness.mock;
    if (mock != null) {
      mock.expectNoUnmatchedRequests();
      final formData = mock.flowRequests.last.submittedData?['formData'] as Map;
      expect(formData['dropdown-field-key'], 'dropdown-option3-value');
      expect(formData['radio-group-key'], 'option3 value');
      expect(formData['checkbox-field-key'], ['option1 value']);
      expect(formData['single-checkbox-field'], true);
      expect(formData['phone-field'], {
        'countryCode': 'US',
        'phoneNumber': '2015550123',
        'extension': '',
      });
    }
  });
}
