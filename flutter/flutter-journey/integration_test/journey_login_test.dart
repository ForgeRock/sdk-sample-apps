/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_journey/main.dart';
import 'package:flutter_journey/routing/router.dart';

/// Drives the Login Journey end-to-end against a real, reachable tenant. Requires network access
/// and a Journey named `"Login"` returning `NameCallback` + `PasswordCallback` on its first node.
///
/// `lib/config/env.dart` ships with placeholder values (`'<server-url>'`, etc.) and must be
/// replaced with a real tenant's `serverUrl`/`realm`/`cookie` before this test can run at all —
/// see `flutter-journey/README.md` step 3.
///
/// Run standalone, not combined with `journey_registration_test.dart` in the same test binary —
/// the native SDK persists the AM session cookie on-device across `Journey` instances within one
/// app install, so running both Journeys back-to-back in one process leaves session-cookie state
/// from one that changes the other's first-node response.
///
/// The credential-dependent assertions (login, success screen, sign-off) only run when
/// `E2E_USERNAME`/`E2E_PASSWORD` are supplied via `--dart-define`, since no test credentials are
/// committed to this public sample repo:
///
/// ```
/// flutter test integration_test/journey_login_test.dart \
///   --dart-define=E2E_USERNAME=<username> --dart-define=E2E_PASSWORD=<password>
/// ```
///
/// Without them, only the tenant-reachable / callback-rendering assertion runs.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const username = String.fromEnvironment('E2E_USERNAME');
  const password = String.fromEnvironment('E2E_PASSWORD');
  final hasCredentials = username.isNotEmpty && password.isNotEmpty;

  testWidgets('starts the Login journey and renders Name + Password fields', (
    tester,
  ) async {
    router.go('/config');
    await tester.pumpWidget(const FlutterJourneyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Login');
    await tester.tap(find.text('Start Journey'));
    await tester.pumpAndSettle(const Duration(seconds: 20));

    expect(find.text('User Name'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets(
    'completes login with valid credentials and reaches Success',
    (tester) async {
      router.go('/config');
      await tester.pumpWidget(const FlutterJourneyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Login');
      await tester.tap(find.text('Start Journey'));
      await tester.pumpAndSettle(const Duration(seconds: 20));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), username);
      await tester.enterText(textFields.at(1), password);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle(const Duration(seconds: 20));

      expect(find.text('Journey completed successfully.'), findsOneWidget);

      await tester.tap(find.text('Sign Off'));
      await tester.pumpAndSettle(const Duration(seconds: 20));

      expect(find.text('Start a Journey'), findsOneWidget);
    },
    skip: !hasCredentials,
  );
}
