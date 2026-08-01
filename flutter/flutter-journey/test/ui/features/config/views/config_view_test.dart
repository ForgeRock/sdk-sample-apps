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
    'renders the Server URL, Realm, and Cookie rows for the injected config',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConfigView(
            onContinue: () {},
            serverUrl: 'https://openam.example.com/am',
            realm: 'alpha',
            cookie: 'iPlanetDirectoryPro',
          ),
        ),
      );

      expect(find.text('Active Environment'), findsOneWidget);
      expect(find.text('SERVER URL'), findsOneWidget);
      expect(find.text('https://openam.example.com/am'), findsOneWidget);
      expect(find.text('REALM'), findsOneWidget);
      expect(find.text('alpha'), findsOneWidget);
      expect(find.text('COOKIE'), findsOneWidget);
      expect(find.text('iPlanetDirectoryPro'), findsOneWidget);
    },
  );

  testWidgets('omits the OIDC rows when oidcConfig is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConfigView(onContinue: () {}, oidcConfig: null),
      ),
    );

    expect(find.text('CLIENT ID'), findsNothing);
    expect(find.text('DISCOVERY ENDPOINT'), findsNothing);
    expect(find.text('REDIRECT URI'), findsNothing);
  });

  testWidgets('renders the OIDC rows when oidcConfig is set', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ConfigView(
          onContinue: () {},
          oidcConfig: const OidcConfig(
            clientId: 'my-client',
            discoveryEndpoint: 'https://openam.example.com/.well-known',
            scopes: ['openid'],
            redirectUri: 'myapp://callback',
          ),
        ),
      ),
    );

    expect(find.text('CLIENT ID'), findsOneWidget);
    expect(find.text('my-client'), findsOneWidget);
    expect(find.text('DISCOVERY ENDPOINT'), findsOneWidget);
    expect(find.text('REDIRECT URI'), findsOneWidget);
    expect(find.text('myapp://callback'), findsOneWidget);
  });

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
