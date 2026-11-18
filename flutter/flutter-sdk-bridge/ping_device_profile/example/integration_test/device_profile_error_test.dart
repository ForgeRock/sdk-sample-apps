/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_device_profile/ping_device_profile.dart';

import 'support/device_profile_harness.dart';
import 'support/test_config.dart';

/// A `collect` against a journey whose active node is gone fails with a typed state error.
///
/// The callback addresses itself by its own index, so a mismatched index is not reachable through
/// the public API — the realistic failure is a stale callback: the flow moved on (here, the node
/// was submitted and the journey completed) and the app then tries to collect with the old object.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('collect after the node was submitted throws a typed state error', (tester) async {
    final liveSkipReason = E2eConfig.liveCredentialsSkipReason;
    if (liveSkipReason != null) {
      markTestSkipped(liveSkipReason);
      return;
    }

    final harness = await DeviceProfileHarness.start(
      authenticate: DeviceProfileHarness.collectScript(),
    );
    addTearDown(harness.dispose);

    final node = harness.expectContinue(await harness.client.start('Login', forceAuth: true));
    final callback = node.callbacks.single as DeviceProfileCallback;

    // Submit the node; the journey completes and the callback's node is gone.
    harness.expectSuccess(await harness.client.next(node));

    await expectLater(
      callback.collect(),
      throwsA(
        isA<PingException>()
          .having((e) => e.type, 'type', 'state')
          .having((e) => e.code, 'code', 'DEVICE_PROFILE_COLLECT_ERROR'),
      ),
    );
  });
}
