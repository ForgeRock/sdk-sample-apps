/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/number_attribute_input_callback_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

NumberAttributeInputCallback _callback({
  String name = 'age',
  String? prompt = 'Age',
  bool required = false,
  double value = 0,
  List<Map<String, Object?>> failedPolicies = const [],
}) => NumberAttributeInputCallback(
  type: 'NumberAttributeInputCallback',
  index: 0,
  prompt: prompt,
  name: name,
  required: required,
  value: value,
  failedPolicies: failedPolicies,
);

void main() {
  testWidgets('renders a TextField labelled with the prompt and initial value', (
    tester,
  ) async {
    final callback = _callback(value: 42);

    await _pump(
      tester,
      NumberAttributeInputCallbackView(callback: callback, onChanged: () {}),
    );

    expect(find.widgetWithText(TextField, 'Age'), findsOneWidget);
    expect(find.text('42.0'), findsOneWidget);
  });

  testWidgets('appends " *" to the label when the attribute is required', (
    tester,
  ) async {
    final callback = _callback(required: true);

    await _pump(
      tester,
      NumberAttributeInputCallbackView(callback: callback, onChanged: () {}),
    );

    expect(find.widgetWithText(TextField, 'Age *'), findsOneWidget);
  });

  testWidgets(
    'typing non-numeric text sets the parse-error helper and error sentinel without '
    'updating the value',
    (tester) async {
      final callback = _callback(value: 10);
      var changed = false;

      await _pump(
        tester,
        NumberAttributeInputCallbackView(
          callback: callback,
          onChanged: () => changed = true,
        ),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.helperText, 'Enter a valid number');
      // Empty-string sentinel: triggers the themed error border without duplicating the
      // helperText message above (Material only renders one of helper/error at a time, so the
      // helperText itself isn't shown on screen once errorText is non-null).
      expect(field.decoration?.errorText, '');
      expect(callback.value, 10);
      expect(changed, isTrue);
    },
  );

  testWidgets(
    'typing valid numeric text updates the callback value and clears the parse error',
    (tester) async {
      final callback = _callback(value: 0);
      var changed = false;

      await _pump(
        tester,
        NumberAttributeInputCallbackView(
          callback: callback,
          onChanged: () => changed = true,
        ),
      );

      // First introduce a parse error, then correct it, to exercise the clearing path too.
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.helperText,
        'Enter a valid number',
      );

      await tester.enterText(find.byType(TextField), '12.5');
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.helperText, isNull);
      expect(field.decoration?.errorText, isNull);
      expect(callback.value, 12.5);
      expect(changed, isTrue);
    },
  );

  testWidgets('renders failedPolicies as error text below the field', (
    tester,
  ) async {
    final callback = _callback(
      failedPolicies: [
        {'policyRequirement': 'MIN_VALUE'},
      ],
    );

    await _pump(
      tester,
      NumberAttributeInputCallbackView(callback: callback, onChanged: () {}),
    );

    expect(find.text('MIN_VALUE'), findsOneWidget);
  });
}
