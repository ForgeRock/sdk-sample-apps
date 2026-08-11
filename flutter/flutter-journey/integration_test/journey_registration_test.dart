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

/// Drives the self-registration Journey end-to-end against a real, reachable tenant with a
/// Journey named `"Registration"`.
///
/// `lib/config/env.dart` ships with placeholder values (`'<server-url>'`, etc.) and must be
/// replaced with a real tenant's `serverUrl`/`realm`/`cookie` before this test can run at all —
/// see `flutter-journey/README.md` step 3.
///
/// Run standalone, not combined with `journey_login_test.dart` in the same test binary — see that
/// file's doc comment for why.
///
/// Needs no credentials — it signs up a fresh, uniquely-suffixed user each run.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'completes self-registration exercising Validated/Attribute/KBA/Terms callbacks',
    (tester) async {
      router.go('/config');
      await tester.pumpWidget(const FlutterJourneyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Registration');
      await tester.tap(find.text('Start Journey'));
      await tester.pumpAndSettle(const Duration(seconds: 20));

      final suffix = DateTime.now().millisecondsSinceEpoch.toString();
      final newUsername = 'flutterE2E$suffix';

      // ValidatedUsername, 2x StringAttributeInput (name), StringAttributeInput (email),
      // BooleanAttributeInput x2 (preferences), ValidatedPassword — all on one ContinueNode.
      final textFields = find.byType(TextField);
      await tester.ensureVisible(textFields.at(0));
      await tester.enterText(textFields.at(0), newUsername);
      await tester.enterText(textFields.at(1), 'first$suffix');
      await tester.enterText(textFields.at(2), 'last$suffix');
      await tester.enterText(textFields.at(3), '$newUsername@example.com');
      await tester.enterText(textFields.at(4), 'Password1!');

      // Each KBA callback defaults to "custom question" mode (selectedQuestion starts empty,
      // which isn't in predefinedQuestions) — select a predefined question via its dropdown so
      // only the Answer field is rendered.
      const questions = [
        "What's your favorite color?",
        'Who was your first employer?',
      ];
      final kbaDropdowns = find.byType(DropdownButtonFormField<String>);
      for (var i = 0; i < kbaDropdowns.evaluate().length; i++) {
        final dropdown = kbaDropdowns.at(i);
        await tester.scrollUntilVisible(
          dropdown,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text(questions[i]).last);
        await tester.pumpAndSettle();
      }

      final answerFields = find.widgetWithText(TextField, 'Answer');
      for (var i = 0; i < answerFields.evaluate().length; i++) {
        final field = answerFields.at(i);
        await tester.scrollUntilVisible(
          field,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.enterText(field, 'Red');
      }

      final terms = find.text('I accept the terms and conditions');
      await tester.scrollUntilVisible(
        terms,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(terms);
      await tester.pumpAndSettle();

      final next = find.text('Next');
      await tester.scrollUntilVisible(
        next,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle(const Duration(seconds: 20));

      expect(find.text('Journey completed successfully.'), findsOneWidget);
    },
  );
}
