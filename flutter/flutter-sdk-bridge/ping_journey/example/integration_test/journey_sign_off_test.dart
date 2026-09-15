/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/journey_fixtures.dart';
import 'support/journey_harness.dart';
import 'support/mock_am_server.dart';
import 'support/test_config.dart';

/// Signing off after a successful Journey revokes the AM session.
///
/// Worth an integration test rather than a unit test for a reason that only shows up on a real device:
/// the SSO token lives in platform secure storage (Keychain / EncryptedSharedPreferences), and
/// `signOff()` throws if there is nothing stored. So this asserts the *stateful* contract — log in,
/// then sign off — which no mocked host API can reach.
///
/// It also cleans up after itself in a way the other scenarios cannot: `signOff()` deletes the stored
/// token, so this file leaves the device's secure storage empty for whatever runs next.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signOff revokes the session established by a Journey', (
    tester,
  ) async {
    final liveSkipReason = E2eConfig.liveCredentialsSkipReason;
    if (liveSkipReason != null) {
      markTestSkipped(liveSkipReason);
      return;
    }

    final harness = await JourneyHarness.start(
      authenticate: <MockResponse>[
        MockResponse.json(JourneyFixtures.usernamePasswordNode()),
        MockResponse.json(JourneyFixtures.success()),
      ],
    );
    addTearDown(harness.dispose);

    final node = harness.expectContinue(
      await harness.client.start(harness.journeyName, forceAuth: true),
    );
    harness.fillCredentials(node);
    harness.expectSuccess(await harness.client.next(node));

    expect(await harness.client.signOff(), isTrue);

    if (harness.isHermetic) {
      final logout = harness.mock.requests
          .where((request) => request.path.endsWith('/sessions'))
          .single;
      expect(logout.method, 'POST');
      expect(logout.query['_action'], 'logout');
      // The cookie header proves the SDK signed off the session it had just stored, rather than
      // issuing an anonymous logout that would silently do nothing.
      expect(logout.headers['iplanetdirectorypro'], 'mock-sso-token');

      harness.mock.expectNoUnmatchedRequests();
    }
  });
}
