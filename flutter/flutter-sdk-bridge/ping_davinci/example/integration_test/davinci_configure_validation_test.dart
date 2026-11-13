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

/// The native config parsers reject an OIDC configuration that isn't exactly one path with a
/// usable endpoint, before building anything. The check is native, not Dart, so this proves both
/// platforms enforce the same rule.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('configure rejects an ambiguous or endpoint-less OIDC config', (
    tester,
  ) async {
    final isConfigureArgumentError = isA<PingException>()
        .having((e) => e.code, 'code', 'DAVINCI_CONFIGURE_ERROR')
        .having((e) => e.type, 'type', 'argument');

    final bothPaths = validConfig()..oidcClientId = 'some-oidc-client';
    await expectLater(
      DaVinciClient.configure(bothPaths),
      throwsA(isConfigureArgumentError),
      reason: 'hoisted OIDC fields and oidcClientId together must be rejected',
    );

    final noEndpoint = validConfig()..discoveryEndpoint = null;
    await expectLater(
      DaVinciClient.configure(noEndpoint),
      throwsA(isConfigureArgumentError),
      reason:
          'a config with neither discoveryEndpoint nor openId must be rejected',
    );
  });
}
