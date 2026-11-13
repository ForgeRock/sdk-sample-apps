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

/// A registration whose password fails the server's policy comes back as a recoverable
/// `ErrorNode` whose `fieldErrors` name the `password` field, and the same `DaVinciClient` can
/// submit again from its `continueNode`.
///
/// Hermetic, the corrected retry advances to a `SuccessNode`. Live, the retry uses another
/// password the policy rejects, so it proves the tenant accepts a resubmission without creating
/// a user; a passing password would register one on a shared tenant.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a rejected password is an ErrorNode that can be retried', (
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
        DaVinciFixtures.ssoRegisterForm(baseUrl),
        DaVinciFixtures.ssoRegisterWeakPassword(),
        DaVinciFixtures.signOnSuccess(),
      ],
    );
    addTearDown(harness.dispose);

    final menu = await harness.client.start();
    expect(menu, isA<ContinueNode>(), reason: harness.diagnose(menu));
    collectorWithKey<FlowCollector>(
      menu as ContinueNode,
      DaVinciFixtures.registerBranch,
    ).select();
    final registration = await harness.client.next(menu);
    expect(
      registration,
      isA<ContinueNode>(),
      reason: harness.diagnose(registration),
    );
    final form = registration as ContinueNode;
    collectorWithKey<TextCollector>(form, 'email').value =
        'flutter-integration@example.invalid';
    collectorWithKey<TextCollector>(form, 'givenName').value = 'Flutter';
    collectorWithKey<TextCollector>(form, 'familyName').value = 'Integration';
    collectorWithKey<PasswordCollector>(form, 'password').value = 'a';
    collectorWithKey<SubmitCollector>(
      form,
      DaVinciFixtures.registerButton,
    ).select();

    final rejected = await harness.client.next(form);

    expect(rejected, isA<ErrorNode>(), reason: harness.diagnose(rejected));
    final error = rejected as ErrorNode;
    expect(error.status, 400);
    expect(error.input['code'], 'invalidValue');
    expect(error.fieldErrors.keys, ['password']);
    expect(
      error.fieldErrors['password'],
      startsWith('User password did not satisfy password policy requirements'),
    );
    expect(
      error.errorDetails.single.rawResponse.details.single.innerErrors,
      contains('length'),
    );
    // The retry node is the form just submitted: its other values survive, its password was
    // wiped by the SDK, and the server's message sits on the password field.
    final retry = error.continueNode;
    expect(retry, isNotNull, reason: 'a 4xx from createUser is recoverable');
    final password = collectorWithKey<PasswordCollector>(retry!, 'password');
    expect(password.serverError, error.fieldErrors['password']);
    expect(password.value, isEmpty);
    expect(
      collectorWithKey<TextCollector>(retry, 'email').value,
      'flutter-integration@example.invalid',
    );
    expect(collectorWithKey<TextCollector>(retry, 'email').serverError, isNull);

    password.value = harness.isHermetic ? 'Correct-h0rse-battery' : 'aa';
    collectorWithKey<SubmitCollector>(
      retry,
      DaVinciFixtures.registerButton,
    ).select();
    final retried = await harness.client.next(retry);

    final mock = harness.mock;
    if (mock == null) {
      expect(retried, isA<ErrorNode>(), reason: harness.diagnose(retried));
      expect((retried as ErrorNode).fieldErrors.keys, ['password']);
      return;
    }
    expect(retried, isA<SuccessNode>(), reason: harness.diagnose(retried));
    mock.expectNoUnmatchedRequests();
    final [..., first, second] = mock.flowRequests;
    expect(
      second.path,
      first.path,
      reason: 'the retry resubmits the same node',
    );
    // Only the password was set on the retry node, but the native node kept the rest.
    expect(second.submittedData?['formData'], <String, Object?>{
      'email': 'flutter-integration@example.invalid',
      'password': 'Correct-h0rse-battery',
      'givenName': 'Flutter',
      'familyName': 'Integration',
    });
  });
}
