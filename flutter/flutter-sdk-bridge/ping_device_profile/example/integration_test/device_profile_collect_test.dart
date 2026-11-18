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

/// The golden path: a Journey page carrying a `DeviceProfileCallback` maps to the add-on Dart
/// type, the native collection runs, and the flow completes end-to-end.
///
/// Hermetic mode: the mock's first response is the device profile page, the second is success.
/// The profile payload itself is produced by the native SDK in-process — the mock only proves the
/// flow submits and completes. Live mode: point E2E_* defines at a tenant whose Journey shows a
/// Device Profile Collector node.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a journey with a DeviceProfileCallback collects and completes', (tester) async {
    final liveSkipReason = E2eConfig.liveCredentialsSkipReason;
    if (liveSkipReason != null) {
      markTestSkipped(liveSkipReason);
      return;
    }

    final harness = await DeviceProfileHarness.start(
      authenticate: DeviceProfileHarness.collectScript(),
    );
    addTearDown(harness.dispose);

    final first = harness.expectContinue(await harness.client.start('Login', forceAuth: true));

    // The add-on mapping produced our type, not the TextOutputCallback placeholder, and the
    // server's display fields made it through `raw`.
    expect(first.callbacks, hasLength(1));
    final callback = first.callbacks.single;
    expect(callback, isA<DeviceProfileCallback>());
    final profileCallback = callback as DeviceProfileCallback;
    expect(profileCallback.metadata, isTrue);
    expect(profileCallback.location, isFalse);
    expect(profileCallback.message, 'Profiling your device');

    final profile = await profileCallback.collect();

    // The native SDK produced a profile with an identifier. Its full shape is the native SDK's
    // own and differs per platform, so only the load-bearing key is asserted.
    expect(profile, isNotEmpty);
    expect(profile['identifier'], isNotNull);

    // `next()` submits the node; the profile rides natively via the callback's stored input.
    final success = harness.expectSuccess(await harness.client.next(first));
    expect(success.sessionToken, isNotNull);

    if (harness.isHermetic) {
      final requests = harness.server!.requests;
      // The follow-up authenticate (the next) carried the profile the native SDK stored.
      final submit = requests.last;
      final body = submit.body;
      expect(body, contains('DeviceProfileCallback'));
    }
  });
}
