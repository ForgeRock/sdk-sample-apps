/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_journey/config/env.dart';
import 'package:flutter_journey/ui/features/config/views/config_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders the Server URL, Realm, and Cookie rows for the active Env',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ConfigView(onContinue: () {})),
      );

      expect(find.text('Active Environment'), findsOneWidget);
      expect(find.text('SERVER URL'), findsOneWidget);
      expect(find.text(Env.serverUrl), findsOneWidget);
      expect(find.text('REALM'), findsOneWidget);
      expect(find.text(Env.realm), findsOneWidget);
      expect(find.text('COOKIE'), findsOneWidget);
      expect(find.text(Env.cookie), findsOneWidget);
    },
  );

  testWidgets(
    'omits the OIDC rows when Env.oidcConfig is null',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ConfigView(onContinue: () {})),
      );

      // The sample app ships with Env.oidcConfig == null by default.
      expect(Env.oidcConfig, isNull);
      expect(find.text('CLIENT ID'), findsNothing);
      expect(find.text('DISCOVERY ENDPOINT'), findsNothing);
      expect(find.text('REDIRECT URI'), findsNothing);
    },
  );

  testWidgets('tapping Continue invokes onContinue', (tester) async {
    var continued = false;

    await tester.pumpWidget(
      MaterialApp(home: ConfigView(onContinue: () => continued = true)),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pump();

    expect(continued, isTrue);
  });
}
