/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_example/core/routing/router.dart';
import 'package:ping_example/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// These tests run without `--dart-define-from-file`, so every flow still has its `<placeholder>`
// defaults and counts as not configured.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    router.go('/');
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const PingExampleApp());
    await tester.pumpAndSettle();
  }

  testWidgets('Home lists the three flows and marks them not configured', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('DaVinci Flow'), findsOneWidget);
    expect(find.text('Journey Flow'), findsOneWidget);
    expect(find.text('OIDC (Web) Login'), findsOneWidget);
    expect(find.text('Not configured'), findsNWidgets(3));
    expect(find.text('SESSION'), findsNothing);
    expect(find.text('Built with Flutter'), findsOneWidget);
    expect(find.byType(FlutterLogo), findsOneWidget);
  });

  testWidgets('tapping an unconfigured flow shows the guard, not the flow', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Journey Flow'));
    await tester.pumpAndSettle();
    expect(find.text("Journey isn't configured"), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('AUTHENTICATION'), findsOneWidget);
    expect(find.text('Journey Name'), findsNothing);
  });

  testWidgets('the guard can jump to the Environments screen', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('DaVinci Flow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Environments'));
    await tester.pumpAndSettle();

    expect(find.text('Environments'), findsOneWidget);
    expect(find.text('Incomplete'), findsWidgets);
  });

  testWidgets('Environments screen shows all flows and flags placeholders', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Environments'));
    await tester.pumpAndSettle();

    expect(find.text('Environments'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Incomplete'), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('AUTHENTICATION'), findsOneWidget);
  });

  // A configured flow opens straight onto its editable input, not an environment summary. The
  // guard is bypassed by navigating to the route directly.
  const entryScreens = {
    '/journey/name': 'Journey Name',
    '/davinci/config': 'ACR values (flow policy)',
    '/oidc/login': 'Login with browser',
  };
  for (final MapEntry(key: path, value: expected) in entryScreens.entries) {
    testWidgets('$path opens onto "$expected" and back returns Home', (
      tester,
    ) async {
      await pumpApp(tester);

      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
      expect(find.text('Active Environment'), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('AUTHENTICATION'), findsOneWidget);
    });
  }
}
