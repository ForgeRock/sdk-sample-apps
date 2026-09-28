/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/validated_password_callback_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

ValidatedPasswordCallback _callback({
  String password = '',
  bool echoOn = false,
  List<Map<String, Object?>> failedPolicies = const [],
}) => ValidatedPasswordCallback(
  type: 'ValidatedPasswordCallback',
  index: 0,
  prompt: 'Password',
  password: password,
  echoOn: echoOn,
  failedPolicies: failedPolicies,
);

void main() {
  testWidgets('renders a TextField with the Password label', (tester) async {
    final callback = _callback();

    await _pump(
      tester,
      ValidatedPasswordCallbackView(callback: callback, onChanged: () {}),
    );

    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
  });

  testWidgets(
    'entering text updates the callback password and invokes onChanged',
    (tester) async {
      final callback = _callback();
      var changed = false;

      await _pump(
        tester,
        ValidatedPasswordCallbackView(
          callback: callback,
          onChanged: () => changed = true,
        ),
      );

      await tester.enterText(find.byType(TextField), 's3cr3t');
      await tester.pump();

      expect(callback.password, 's3cr3t');
      expect(changed, isTrue);
    },
  );

  testWidgets('obscures text by default and can be toggled visible', (
    tester,
  ) async {
    final callback = _callback();

    await _pump(
      tester,
      ValidatedPasswordCallbackView(callback: callback, onChanged: () {}),
    );

    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    expect(find.byIcon(Icons.visibility), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('renders failedPolicies as error text below the field', (
    tester,
  ) async {
    final callback = _callback(
      failedPolicies: [
        {'policyRequirement': 'MIN_LENGTH'},
      ],
    );

    await _pump(
      tester,
      ValidatedPasswordCallbackView(callback: callback, onChanged: () {}),
    );

    expect(find.text('MIN_LENGTH'), findsOneWidget);
  });

  testWidgets('shows no error text when there are no failedPolicies', (
    tester,
  ) async {
    final callback = _callback();

    await _pump(
      tester,
      ValidatedPasswordCallbackView(callback: callback, onChanged: () {}),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.errorText, isNull);
  });
}
