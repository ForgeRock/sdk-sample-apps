/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'support/davinci_fixtures.dart';

/// Every core collector type resolves the moment `configure` returns.
///
/// On iOS this is the registration race: `DaVinci.createDaVinci` registers collectors in a
/// detached `Task {}`, so without the bridge's own awaited registration a `start()` sent straight
/// after `configure` can meet an empty factory. Reading the factory immediately — no delay, no
/// retry — is the point. Android registers eagerly at process start, so it passes either way.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'all core collector types are registered when configure returns',
    (tester) async {
      final client = await DaVinciClient.configure(validConfig());
      addTearDown(client.dispose);

      final types = await PingDaVinciHostApi().registeredCollectorTypes(
        client.handleId,
      );

      final expected = Platform.isIOS
          ? {...coreCollectorTypes, ...iosAliasCollectorTypes}
          : coreCollectorTypes;
      expect(
        types.toSet(),
        expected,
        reason:
            'expected ${expected.length} core collector types on '
            '${Platform.operatingSystem} with no add-on modules linked',
      );
    },
  );
}
