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

/// Choosing a `DEVICE_REGISTRATION` device submits it and advances: Dart names the device, the
/// native collector re-resolves it in its own list, and the payload is the SDK's (the device
/// `type`). The form has no button, so the event type comes from the collector, `submit`, with
/// no `actionKey`. Runs in both modes: anonymously the tenant then asks for the email address to
/// enrol, which creates nothing.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a chosen device is submitted and the flow advances', (
    tester,
  ) async {
    final skipReason = E2eConfig.liveFlowSkipReason(
      E2eConfig.acrMfaDevice,
      'E2E_ACR_MFA_DEVICE',
    );
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.create(
      liveAcr: E2eConfig.acrMfaDevice,
      hermeticAcr: 'mfa-device',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.mfaDeviceMenu(baseUrl),
        DaVinciFixtures.deviceRegistrationForm(baseUrl),
        DaVinciFixtures.deviceRegistrationSubmitted(baseUrl),
      ],
    );
    addTearDown(harness.dispose);

    final menu = await harness.client.start();
    expect(menu, isA<ContinueNode>(), reason: harness.diagnose(menu));
    collectorWithKey<SubmitCollector>(
      menu as ContinueNode,
      DaVinciFixtures.deviceRegistrationBranch,
    ).select();
    final form = await harness.client.next(menu);
    expect(form, isA<ContinueNode>(), reason: harness.diagnose(form));
    form as ContinueNode;
    final registration = form.collectors
        .whereType<DeviceRegistrationCollector>()
        .single;
    expect(registration.devices.map((d) => d.type), ['EMAIL', 'SMS', 'VOICE']);
    expect(form.canSubmit, isFalse, reason: 'required, and nothing chosen');

    registration.selectDevice(
      registration.devices.firstWhere((d) => d.type == 'EMAIL'),
    );
    final next = await harness.client.next(form);

    expect(next, isA<ContinueNode>(), reason: harness.diagnose(next));
    final email = (next as ContinueNode).collectors.whereType<TextCollector>();
    expect(email.map((c) => c.key), ['email']);

    final mock = harness.mock;
    if (mock == null) return;
    mock.expectNoUnmatchedRequests();
    final submit = mock.flowRequests.last;
    expect((submit.json?['parameters'] as Map)['eventType'], 'submit');
    expect(submit.submittedData?['formData'], {'device-registration': 'EMAIL'});
    expect(submit.submittedData?.containsKey('actionKey'), isFalse);
  });
}
