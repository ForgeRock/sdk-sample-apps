/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'support/davinci_fixtures.dart';
import 'support/davinci_harness.dart';
import 'support/test_config.dart';

/// The lifecycle leak check: configure → start → next ×3 → error → retry → success → token →
/// signOff → dispose, five times, leaves the bridge holding nothing, read through the diagnostic
/// `retainedState()`: no handle in `davinciRegistry`, no cached node or session, no flow lock, no
/// polling task. A call on a disposed handle fails as a typed `state` error.
///
/// Hermetic only: it needs five scripted sign-ons.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('repeated full flows leave no native state behind', (
    tester,
  ) async {
    if (E2eConfig.isLive) {
      markTestSkipped('Hermetic only: it signs on five times.');
      return;
    }
    final api = PingDaVinciHostApi();
    final baseline = _counts(await api.retainedState());

    for (var round = 0; round < 5; round++) {
      final harness = await DaVinciHarness.create(
        liveAcr: '',
        hermeticAcr: 'sso',
        hermeticFlow: (baseUrl) => [
          DaVinciFixtures.ssoMenu(baseUrl),
          DaVinciFixtures.ssoRegisterForm(baseUrl),
          DaVinciFixtures.ssoMenu(baseUrl),
          DaVinciFixtures.ssoWrongPassword(),
          DaVinciFixtures.signOnSuccess(),
        ],
      );
      final client = harness.client;
      final during = _counts(await api.retainedState());
      expect(during.handles, baseline.handles + 1, reason: 'round $round');

      final menu = await client.start() as ContinueNode;
      collectorWithKey<FlowCollector>(
        menu,
        DaVinciFixtures.registerBranch,
      ).select();
      final register = await client.next(menu) as ContinueNode;
      collectorWithKey<FlowCollector>(register, 'CANCEL').select();
      final signOn = await client.next(register) as ContinueNode;
      _fillSignOn(signOn, 'nobody', 'Not-the-passw0rd');
      final rejected = await client.next(signOn);
      expect(rejected, isA<ErrorNode>(), reason: harness.diagnose(rejected));
      final retry = (rejected as ErrorNode).continueNode!;
      _fillSignOn(retry, 'alice', 'Passw0rd!');
      final success = await client.next(retry);
      expect(success, isA<SuccessNode>(), reason: harness.diagnose(success));
      expect((await client.getToken()).accessToken, isNotEmpty);
      expect(await client.signOff(), isTrue);

      await harness.dispose();

      final after = await api.retainedState();
      expect(
        _counts(after),
        baseline,
        reason: 'round $round: ${_describe(after)}',
      );
      await expectLater(
        api.start(client.handleId),
        throwsA(
          isA<PlatformException>()
              .having((e) => e.code, 'code', 'DAVINCI_START_ERROR')
              .having((e) => e.details, 'type', 'state'),
        ),
      );
      harness.mock!.expectNoUnmatchedRequests();
    }
  });
}

void _fillSignOn(ContinueNode node, String username, String password) {
  collectorWithKey<TextCollector>(node, 'username').value = username;
  collectorWithKey<PasswordCollector>(node, 'password').value = password;
  collectorWithKey<SubmitCollector>(
    node,
    DaVinciFixtures.signOnButton,
  ).select();
}

typedef _Counts = ({
  int handles,
  int nodes,
  int sessions,
  int flowLocks,
  int polls,
});

_Counts _counts(RetainedStateMessage state) => (
  handles: state.registeredHandles,
  nodes: state.cachedNodes,
  sessions: state.cachedSessions,
  flowLocks: state.flowLocks,
  polls: state.activePolls,
);

String _describe(RetainedStateMessage state) => _counts(state).toString();
