/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ping_oidc/ping_oidc.dart';

import 'support/oidc_harness.dart';
import 'support/test_config.dart';

/// What `hasUser`/`token`/`refresh`/`userInfo`/`revoke`/`signOff` do before any login completes —
/// and a platform divergence in the native SDKs this scenario exists to pin down.
///
/// This is the one leg of `OidcClient` this suite can exercise past `configure`: `authorize` opens
/// a system browser, and nothing under `integration_test/` can drive or complete that UI, so a
/// genuine signed-in session is unreachable here. A real browser login → token → userinfo →
/// refresh → revoke/sign-off round trip is covered manually against the `flutter/flutter-oidc`
/// sample app instead; see its README.
///
/// **Known SDK gap** (verified against both native implementations, not just read from source):
/// Android's `OidcWebClient.user()` checks its token storage and returns `null` when nothing was
/// ever signed in, so `hasUser` is honestly `false` and every one of the five calls below fails
/// resolving the session — a `PingException` with `type: 'state'` and a "No OIDC user session"
/// message, before touching the network. iOS's `OidcWebClient.user()` does not check storage: once
/// OIDC is configured it always hands back a live `OidcUser` proxy, so `hasUser` is `true` even
/// with nothing signed in, `token`/`userInfo` fail deeper (attempting a token exchange with no
/// auth code), `refresh` fails differently again (no refresh token), and — the most surprising
/// part — `revoke`/`signOff` report *success* against a session that was never established. File a
/// native-SDK ticket against `ping-ios-sdk`'s `OidcWebClient.user()` if you land here chasing this;
/// as of writing none exists yet. This scenario asserts the current (divergent) behavior of both
/// platforms rather than pretend they agree, so a fix on either side shows up as a failure here
/// instead of silently drifting.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'hasUser and the session calls behave differently per platform with no session',
    (tester) async {
      final skipReason = E2eConfig.liveConfigSkipReason;
      if (skipReason != null) {
        markTestSkipped(skipReason);
        return;
      }

      final harness = await OidcHarness.start();
      addTearDown(harness.dispose);

      if (Platform.isAndroid) {
        expect(
          await harness.client.hasUser(),
          isFalse,
          reason:
              'Android checks token storage, and nothing was ever stored. '
              'Mode: ${E2eConfig.describe}.',
        );

        Future<void> expectNoSession(Future<Object?> Function() call) =>
            expectLater(
              call(),
              throwsA(
                isA<PingException>()
                    .having((error) => error.type, 'type', 'state')
                    .having(
                      (error) => error.message,
                      'message',
                      contains('No OIDC user session'),
                    ),
              ),
              reason: 'Mode: ${E2eConfig.describe}.',
            );

        await expectNoSession(harness.client.token);
        await expectNoSession(harness.client.refresh);
        await expectNoSession(harness.client.userInfo);
        await expectNoSession(harness.client.revoke);
        await expectNoSession(harness.client.signOff);
      } else if (Platform.isIOS) {
        expect(
          await harness.client.hasUser(),
          isTrue,
          reason:
              'iOS hands back a live user proxy once OIDC is configured, regardless of whether '
              'anyone ever signed in — see this file\'s doc comment. Mode: ${E2eConfig.describe}.',
        );

        await expectLater(
          harness.client.token(),
          throwsA(
            isA<PingException>().having(
              (error) => error.message,
              'message',
              contains('No AuthCode is available'),
            ),
          ),
          reason: 'Mode: ${E2eConfig.describe}.',
        );
        await expectLater(
          harness.client.userInfo(),
          throwsA(
            isA<PingException>().having(
              (error) => error.message,
              'message',
              contains('No AuthCode is available'),
            ),
          ),
          reason: 'Mode: ${E2eConfig.describe}.',
        );
        await expectLater(
          harness.client.refresh(),
          throwsA(isA<PingException>()),
          reason:
              'refresh fails for lack of a refresh token, not for lack of a session — the '
              'exact error text is not pinned here since it is not part of the gap this scenario '
              'tracks. Mode: ${E2eConfig.describe}.',
        );

        // Not a bug in this suite: iOS really does report success for both, with no session ever
        // having existed. See this file's doc comment.
        await harness.client.revoke();
        await harness.client.signOff();
      } else {
        fail('This scenario only has documented behavior for Android and iOS.');
      }
    },
  );
}
