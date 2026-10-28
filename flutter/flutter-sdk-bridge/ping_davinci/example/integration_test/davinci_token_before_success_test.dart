/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'support/davinci_harness.dart';
import 'support/test_config.dart';

/// Asking for tokens before the flow reaches a `SuccessNode` throws a typed `PingException`, not a
/// crash and not an empty token. Runs in both modes, with no user needed.
///
/// The type depends on what an earlier run left in secure storage, which outlives the app (and on
/// iOS, its reinstall). With no session cookie there is no user: `state`. With one, both SDKs hand
/// back a user that can't sign in: `start()` has revoked its stored tokens, and its agent can't
/// authorize outside a flow, so `token()` fails with `auth`.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getToken before a SuccessNode is a typed error', (tester) async {
    final skipReason = E2eConfig.liveSsoSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.signOnFlow();
    addTearDown(harness.dispose);

    final start = await harness.client.start();
    expect(start, isA<ContinueNode>(), reason: harness.diagnose(start));

    expect(await harness.client.getSession(), isNull);
    await expectLater(
      harness.client.getToken(),
      throwsA(
        isA<PingException>()
            .having((e) => e.code, 'code', 'DAVINCI_GET_TOKEN_ERROR')
            .having((e) => e.type, 'type', anyOf('state', 'auth')),
      ),
    );
    harness.mock?.expectNoUnmatchedRequests();
  });
}
