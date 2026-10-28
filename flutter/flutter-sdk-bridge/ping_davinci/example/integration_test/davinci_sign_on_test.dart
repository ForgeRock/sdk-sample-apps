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

/// A username + password sign-on completes to a `SuccessNode`: `TextCollector`,
/// `PasswordCollector` and `SubmitCollector` through the `{type, index}` round trip. Runs in both
/// modes; live needs `E2E_USERNAME`/`E2E_PASSWORD`. Exchanging the code for tokens is Phase 5's
/// concern — iOS defers it until tokens are asked for, so this scenario doesn't assert it.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('username and password sign on to a SuccessNode', (tester) async {
    final skipReason = E2eConfig.liveSignOnSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.create(
      liveAcr: E2eConfig.acrSso,
      hermeticAcr: 'sso',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.ssoMenu(baseUrl),
        DaVinciFixtures.signOnSuccess(),
      ],
    );
    addTearDown(harness.dispose);
    final username = harness.isHermetic ? 'alice' : E2eConfig.username;
    final password = harness.isHermetic ? 'Passw0rd!' : E2eConfig.password;

    final start = await harness.client.start();
    expect(start, isA<ContinueNode>(), reason: harness.diagnose(start));
    final form = start as ContinueNode;
    final user = form.collectors.whereType<TextCollector>().single;
    final secret = form.collectors.whereType<PasswordCollector>().single;
    user.value = username;
    secret.value = password;
    collectorWithKey<SubmitCollector>(
      form,
      DaVinciFixtures.signOnButton,
    ).select();

    final next = await harness.client.next(form);

    expect(next, isA<SuccessNode>(), reason: harness.diagnose(next));
    final mock = harness.mock;
    if (mock != null) {
      mock.expectNoUnmatchedRequests();
      final submit = mock.flowRequests.last;
      expect((submit.json?['parameters'] as Map)['eventType'], 'submit');
      expect(submit.submittedData?['actionKey'], DaVinciFixtures.signOnButton);
      expect(submit.submittedData?['formData'], <String, Object?>{
        user.id: username,
        secret.id: password,
      });
    }
  });
}
