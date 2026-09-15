/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/oidc_harness.dart';
import 'support/test_config.dart';

/// `configure`/`createWebClient` never touch the network; the first call that resolves a `User`
/// does, exactly once.
///
/// `OidcClientFactory.create`/`OidcWebClientFactory.create` (both platforms) only build local
/// config objects — neither one calls into the workflow engine, so nothing before the first
/// `user()`-resolving call can reach discovery. `hasUser` is that first call on both platforms,
/// but for different reasons — see `oidc_no_session_test.dart` for how differently the two
/// platforms answer "is there a user" once discovery has run. What is identical across platforms,
/// and what this scenario actually asserts, is the shape of *when* the network gets touched:
/// nothing, then exactly one request, cached from then on.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('discovery is untouched until the first call that resolves a user', (
    tester,
  ) async {
    final skipReason = E2eConfig.liveConfigSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }

    final harness = await OidcHarness.start();
    addTearDown(harness.dispose);

    if (harness.isHermetic) {
      expect(
        harness.mock.requests,
        isEmpty,
        reason:
            'OidcClient.configure just built OidcHarness.client; that alone should never reach '
            'discovery. Mode: ${E2eConfig.describe}.',
      );
    }

    await harness.client.hasUser();

    if (harness.isHermetic) {
      expect(
        harness.mock.requests,
        <String>['GET /.well-known/openid-configuration'],
        reason:
            'hasUser is the first call that resolves a User on either platform, so it should be '
            'the one call in this scenario that reaches discovery — exactly once. '
            'Mode: ${E2eConfig.describe}.',
      );
    }

    // A second call must reuse the cached discovery document rather than refetch it.
    await harness.client.hasUser();

    if (harness.isHermetic) {
      expect(
        harness.mock.requests,
        <String>['GET /.well-known/openid-configuration'],
        reason: 'A repeat hasUser call re-fetched discovery instead of reusing the cached '
            'document. Mode: ${E2eConfig.describe}.',
      );
    }
  });
}
