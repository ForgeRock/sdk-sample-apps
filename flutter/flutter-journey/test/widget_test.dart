/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_journey/main.dart';

/// This is a basic Flutter widget test.
/// Runs a basic test to verify that the app boots to the active-environment config screen.
void main() {
  testWidgets('boots to the active-environment config screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlutterJourneyApp());
    await tester.pumpAndSettle();

    expect(find.text('Active Environment'), findsOneWidget);
  });
}
