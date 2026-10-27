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

/// A value of the wrong type fails native `next()` with a typed `argument` error (which
/// `DaVinciClient` surfaces as a `PingException`) and submits nothing: the same node then advances
/// once the value is corrected. Runs in both modes.
///
/// The typed `Collector` API can't produce a wrong-typed value, so this scenario addresses the
/// native side through the generated host API, as any other caller of it could.
///
/// `testWidgets` is used only because it is `IntegrationTestWidgetsFlutterBinding`'s supported
/// entry point; nothing is ever pumped, and the `tester` is deliberately unused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a wrong-typed value is a typed error and submits nothing', (
    tester,
  ) async {
    final skipReason = E2eConfig.liveConfigSkipReason;
    if (skipReason != null) {
      markTestSkipped(skipReason);
      return;
    }
    final harness = await DaVinciHarness.formFields();
    addTearDown(harness.dispose);

    final start = await harness.client.start();
    expect(start, isA<ContinueNode>(), reason: harness.diagnose(start));
    final menu = start as ContinueNode;
    final branch = collectorWithKey<ButtonCollector>(
      menu,
      DaVinciFixtures.formFieldsBranch,
    );

    // A button takes a String.
    await expectLater(
      PingDaVinciHostApi().next(harness.client.handleId, [
        CollectorValueMessage(
          type: branch.type,
          index: branch.index,
          value: true,
        ),
      ]),
      throwsA(
        isA<PlatformException>()
            .having((e) => e.code, 'code', 'DAVINCI_NEXT_ERROR')
            .having((e) => e.details, 'details', 'argument'),
      ),
    );
    if (harness.mock != null) {
      expect(
        harness.mock!.flowRequests,
        hasLength(1),
        reason: 'only the authorize request',
      );
    }

    branch.select();
    final form = await harness.client.next(menu);
    expect(form, isA<ContinueNode>(), reason: harness.diagnose(form));
    expect((form as ContinueNode).id, isNot(menu.id));
  });
}
