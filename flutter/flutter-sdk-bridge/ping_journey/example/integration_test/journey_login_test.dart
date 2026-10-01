/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_journey/ping_journey.dart';

import 'support/journey_fixtures.dart';
import 'support/journey_harness.dart';
import 'support/mock_am_server.dart';
import 'support/test_config.dart';

/// The happy path: start a Journey, submit username and password, land on a success node.
///
/// This exercises the full stack — Dart facade, Pigeon codec, native `Journey`, HTTP — with no widget
/// tree involved. `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s
/// supported entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('username/password login reaches a success node', (tester) async {
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

    final first = harness.expectContinue(
      await harness.client.start(harness.journeyName, forceAuth: true),
    );

    if (harness.isHermetic) {
      expect(first.header, 'Sign In');
      expect(first.description, 'Enter your credentials');
      expect(first.callbacks.map((callback) => callback.type), <String>[
        CallbackType.nameCallback,
        CallbackType.passwordCallback,
      ]);
      expect(
        first.callbacks.whereType<NameCallback>().single.prompt,
        'User Name',
      );
      expect(
        first.callbacks.whereType<PasswordCallback>().single.prompt,
        'Password',
      );

      // The start request is a POST to the realm's authenticate endpoint, carrying the journey name
      // as authIndexValue and the versioned Accept-API-Version header the SDK pins.
      final startRequest = harness.mock.authenticateRequests.single;
      expect(startRequest.method, 'POST');
      expect(startRequest.path, '/json/realms/root/authenticate');
      expect(startRequest.query['authIndexType'], 'service');
      expect(startRequest.query['authIndexValue'], harness.journeyName);
      expect(startRequest.query['ForceAuth'], 'true');
      expect(
        startRequest.headers['accept-api-version'],
        contains('resource=2.1'),
      );
    }

    // Advance until the flow terminates. Hermetically this loops exactly once; against a live tenant
    // a Login tree may present more than one credential page, and looping keeps the test honest
    // without hard-coding one tenant's shape.
    var node = await _advance(harness, first);
    for (var step = 0; node is ContinueNode && step < 4; step++) {
      node = await _advance(harness, node);
    }

    harness.expectSuccess(node);

    if (harness.isHermetic) {
      final submitted = harness.mock.authenticateRequests[1];
      expect(submitted.method, 'POST');
      expect(submitted.json?['authId'], JourneyFixtures.authId);
      // The submitted payload echoes the whole node back with the input values filled in, addressed
      // by the input names AM chose (IDToken1, IDToken2), not by position.
      expect(
        submitted.inputValues(0)['IDToken1'],
        JourneyHarness.hermeticUsername,
      );
      expect(
        submitted.inputValues(1)['IDToken2'],
        JourneyHarness.hermeticPassword,
      );
      harness.mock.expectNoUnmatchedRequests();
    }
  });
}

Future<JourneyNode> _advance(JourneyHarness harness, ContinueNode node) async {
  expect(
    harness.fillCredentials(node),
    greaterThan(0),
    reason:
        'Expected the node to carry at least one credential callback to fill, but it had '
        '${node.callbacks.map((callback) => callback.type).toList()}. '
        'Mode: ${E2eConfig.describe}.',
  );
  return harness.client.next(node);
}
