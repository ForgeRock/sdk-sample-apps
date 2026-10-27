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
import 'support/mock_davinci_server.dart';
import 'support/test_config.dart';

/// `signOff()` after a `SuccessNode` returns `true`, and the user is gone: `getToken()` and
/// `getUserInfo()` fail with a typed `state` error instead of returning a stale token, and
/// `getSession()` is null. Runs in both modes; live needs `E2E_USERNAME`/`E2E_PASSWORD`.
///
/// Deliberately signs off **without** asking for a token first. iOS defers the code exchange to
/// the first `token()`, and its SDK keeps the signed-in user cached through `signOff()`; without
/// the bridge dropping that cache, the `getToken()` below would redeem the unused code and return
/// a fresh token after sign-off.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getToken fails with a typed error after signOff', (
    tester,
  ) async {
    final skipReason = E2eConfig.liveSignOnSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.signOnFlow();
    addTearDown(harness.dispose);

    final node = await harness.signOn();
    expect(node, isA<SuccessNode>(), reason: harness.diagnose(node));
    final exchangesBefore = harness.mock?.requestsTo('/as/token').length;

    expect(await harness.client.signOff(), isTrue);

    final noUser = isA<PingException>()
        .having((e) => e.type, 'type', 'state')
        .having(
          (e) => e.message,
          'message',
          contains('No signed-in DaVinci user'),
        );
    await expectLater(
      harness.client.getToken(),
      throwsA(noUser.having((e) => e.code, 'code', 'DAVINCI_GET_TOKEN_ERROR')),
    );
    await expectLater(
      harness.client.getUserInfo(),
      throwsA(noUser.having((e) => e.code, 'code', 'DAVINCI_USERINFO_ERROR')),
    );
    expect(await harness.client.getSession(), isNull);

    final mock = harness.mock;
    if (mock != null) {
      mock.expectNoUnmatchedRequests();
      expect(
        mock.requestsTo('/as/token'),
        hasLength(exchangesBefore!),
        reason: 'no exchange after sign-off\n${mock.requestLog}',
      );
      final signOff = mock.requestsTo('/as/signoff');
      expect(signOff, hasLength(1), reason: mock.requestLog);
      expect(
        signOff.single.headers['cookie'],
        contains(MockDaVinciServer.sessionCookie),
        reason: 'sign-off carries the persisted session cookie',
      );
    }
  });
}
