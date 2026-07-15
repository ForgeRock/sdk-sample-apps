/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/validated_username_callback_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

ValidatedUsernameCallback _callback({
  String username = '',
  List<Map<String, Object?>> failedPolicies = const [],
}) => ValidatedUsernameCallback(
  type: 'ValidatedUsernameCallback',
  index: 0,
  prompt: 'Username',
  username: username,
  failedPolicies: failedPolicies,
);

void main() {
  testWidgets('renders a TextField pre-filled with the callback username', (
    tester,
  ) async {
    final callback = _callback(username: 'jdoe');

    await _pump(
      tester,
      ValidatedUsernameCallbackView(callback: callback, onChanged: () {}),
    );

    expect(find.widgetWithText(TextField, 'jdoe'), findsOneWidget);
  });

  testWidgets(
    'entering text updates the callback username and invokes onChanged',
    (tester) async {
      final callback = _callback();
      var changed = false;

      await _pump(
        tester,
        ValidatedUsernameCallbackView(
          callback: callback,
          onChanged: () => changed = true,
        ),
      );

      await tester.enterText(find.byType(TextField), 'new-username');
      await tester.pump();

      expect(callback.username, 'new-username');
      expect(changed, isTrue);
    },
  );

  testWidgets('renders failedPolicies as error text below the field', (
    tester,
  ) async {
    final callback = _callback(
      failedPolicies: [
        {'policyRequirement': 'UNIQUE'},
      ],
    );

    await _pump(
      tester,
      ValidatedUsernameCallbackView(callback: callback, onChanged: () {}),
    );

    expect(find.text('UNIQUE'), findsOneWidget);
  });

  testWidgets('shows no error text when there are no failedPolicies', (
    tester,
  ) async {
    final callback = _callback();

    await _pump(
      tester,
      ValidatedUsernameCallbackView(callback: callback, onChanged: () {}),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.errorText, isNull);
  });
}
