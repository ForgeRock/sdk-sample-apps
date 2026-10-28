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

/// A sign-on with wrong credentials is a recoverable `ErrorNode`, and correcting them on its
/// `continueNode` signs in.
///
/// The tenant's SSO flow names no field for wrong credentials: its only detail is the user
/// lookup's result, so `fieldErrors` is empty and the app shows `ErrorNode.message`. Live mode
/// signs in on the retry only with `E2E_USERNAME`/`E2E_PASSWORD`; without them it retries with
/// other wrong credentials and expects another `ErrorNode`, which still proves the resubmission.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wrong credentials can be corrected on the ErrorNode', (
    tester,
  ) async {
    final skipReason = E2eConfig.liveSsoSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.create(
      liveAcr: E2eConfig.acrSso,
      hermeticAcr: 'sso',
      hermeticFlow: (baseUrl) => [
        DaVinciFixtures.ssoMenu(baseUrl),
        DaVinciFixtures.ssoWrongPassword(),
        DaVinciFixtures.signOnSuccess(),
      ],
    );
    addTearDown(harness.dispose);
    final canSignIn =
        harness.isHermetic || E2eConfig.liveSignOnSkipReason == null;

    final start = await harness.client.start();
    expect(start, isA<ContinueNode>(), reason: harness.diagnose(start));
    final form = start as ContinueNode;
    collectorWithKey<TextCollector>(form, 'username').value =
        'flutter-integration-nobody';
    collectorWithKey<PasswordCollector>(form, 'password').value =
        'Not-the-passw0rd';
    collectorWithKey<SubmitCollector>(
      form,
      DaVinciFixtures.signOnButton,
    ).select();

    final rejected = await harness.client.next(form);

    expect(rejected, isA<ErrorNode>(), reason: harness.diagnose(rejected));
    final error = rejected as ErrorNode;
    expect(error.status, 400);
    expect(error.message, 'Invalid username and/or password');
    expect(error.fieldErrors, isEmpty);
    expect(error.errorDetails.single.rawResponse.code, isNull);
    final retry = error.continueNode;
    expect(retry, isNotNull, reason: 'a failed user lookup is recoverable');
    expect(
      collectorWithKey<TextCollector>(retry!, 'username').value,
      'flutter-integration-nobody',
    );

    collectorWithKey<TextCollector>(retry, 'username').value = !canSignIn
        ? 'flutter-integration-nobody-2'
        : harness.isHermetic
        ? 'alice'
        : E2eConfig.username;
    collectorWithKey<PasswordCollector>(retry, 'password').value = !canSignIn
        ? 'Still-not-the-passw0rd'
        : harness.isHermetic
        ? 'Passw0rd!'
        : E2eConfig.password;
    collectorWithKey<SubmitCollector>(
      retry,
      DaVinciFixtures.signOnButton,
    ).select();
    final retried = await harness.client.next(retry);

    expect(
      retried,
      canSignIn ? isA<SuccessNode>() : isA<ErrorNode>(),
      reason: harness.diagnose(retried),
    );
    harness.mock?.expectNoUnmatchedRequests();
  });
}
