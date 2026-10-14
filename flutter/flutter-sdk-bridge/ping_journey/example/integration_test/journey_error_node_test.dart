/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_journey/ping_journey.dart';

import 'support/journey_fixtures.dart';
import 'support/journey_harness.dart';
import 'support/mock_am_server.dart';
import 'support/test_config.dart';

/// A rejected credential yields a recoverable [ErrorNode], not a [FailureNode].
///
/// This is the distinction the sample app's UI hangs off — an ErrorNode means "show the message and
/// let them try again", a FailureNode means "the flow is over". Both native SDKs classify a 4xx with
/// a JSON body as an ErrorNode carrying the body's `message`, so the assertion below holds on either
/// platform.
///
/// Hermetic only: a live tree's failure shape depends on how that tree is configured — some return
/// 401, others loop back to another ContinueNode with a message attached. Asserting one shape
/// against an arbitrary tenant would be a flaky test pretending to be a strict one.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a rejected credential yields a recoverable ErrorNode', (
    tester,
  ) async {
    if (E2eConfig.isLive) {
      markTestSkipped(E2eConfig.hermeticOnlySkipReason);
      return;
    }

    final harness = await JourneyHarness.start(
      authenticate: <MockResponse>[
        MockResponse.json(JourneyFixtures.usernamePasswordNode()),
        MockResponse.json(
          JourneyFixtures.authenticationFailed(),
          status: HttpStatus.unauthorized,
        ),
        // A second login page, to prove the flow is genuinely recoverable.
        MockResponse.json(JourneyFixtures.usernamePasswordNode()),
        MockResponse.json(JourneyFixtures.success()),
      ],
    );
    addTearDown(harness.dispose);

    final node = harness.expectContinue(
      await harness.client.start(harness.journeyName, forceAuth: true),
    );
    harness.fillCredentials(node);

    final error = harness.expectError(await harness.client.next(node));
    expect(error.message, 'Authentication Failed');
    // Both platforms report 401 here, but by different routes: iOS surfaces the HTTP status while
    // Android reads the body's `code`. The fixture keeps the two in agreement on purpose — asserting
    // a status where they disagree would pass on one platform and fail on the other.
    expect(error.status, 401);

    // Recoverable means restartable: the same client can begin the journey again.
    final retry = harness.expectContinue(
      await harness.client.start(harness.journeyName, forceAuth: true),
    );
    harness.fillCredentials(retry);
    harness.expectSuccess(await harness.client.next(retry));

    expect(harness.mock.authenticateRequests, hasLength(4));
    harness.mock.expectNoUnmatchedRequests();
  });
}
