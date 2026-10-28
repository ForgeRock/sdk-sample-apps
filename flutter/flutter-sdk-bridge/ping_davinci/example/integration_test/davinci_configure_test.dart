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

/// `configureDaVinci` builds a native workflow and registers it in `CoreRuntime.davinciRegistry`,
/// so each call yields its own non-empty handle id.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('configure returns a distinct, non-empty handle id per call', (
    tester,
  ) async {
    final first = await DaVinciClient.configure(validConfig());
    addTearDown(first.dispose);
    final second = await DaVinciClient.configure(validConfig());
    addTearDown(second.dispose);

    expect(first.handleId, isNotEmpty);
    expect(second.handleId, isNotEmpty);
    expect(second.handleId, isNot(first.handleId));
  });
}
