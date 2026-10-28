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

/// After a `SuccessNode`, `getSession()` returns the authorization code, `getToken()` the OIDC
/// tokens, and `getUserInfo()` the claims. Runs in both modes; live needs
/// `E2E_USERNAME`/`E2E_PASSWORD`.
///
/// The code is exchanged exactly once: Android at `SuccessNode` time, iOS on the first `token()`.
/// Either way a second `getToken()` reads the stored token without another exchange.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('session, token and userinfo after a SuccessNode', (
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

    final session = await harness.client.getSession();
    expect(session?.authorizationCode, isNotEmpty);

    final token = await harness.client.getToken();
    expect(token.accessToken, isNotEmpty);
    expect(token.expiresIn, greaterThan(0));

    final again = await harness.client.getToken();
    expect(again.accessToken, token.accessToken);

    final claims = await harness.client.getUserInfo();
    expect(claims['sub'], isA<String>().having((s) => s, 'sub', isNotEmpty));

    final mock = harness.mock;
    if (mock != null) {
      mock.expectNoUnmatchedRequests();
      expect(session!.authorizationCode, 'mock-authorization-code');
      expect(token.accessToken, 'mock-access-token');
      expect(token.refreshToken, 'mock-refresh-token');
      expect(token.tokenType, 'Bearer');
      expect(claims, {'sub': 'mock-subject'});
      final exchanges = mock.requestsTo('/as/token');
      expect(exchanges, hasLength(1), reason: mock.requestLog);
      expect(
        Uri.splitQueryString(exchanges.single.body)['code'],
        'mock-authorization-code',
      );
      expect(
        mock.requestsTo('/as/userinfo').single.headers['authorization'],
        'Bearer mock-access-token',
      );
    }
  });
}
