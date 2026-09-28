/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/string_attribute_input_callback_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

StringAttributeInputCallback _callback({
  String name = 'givenName',
  String? prompt = 'First Name',
  bool required = false,
  String value = '',
  List<Map<String, Object?>> failedPolicies = const [],
}) => StringAttributeInputCallback(
  type: 'StringAttributeInputCallback',
  index: 0,
  prompt: prompt,
  name: name,
  required: required,
  value: value,
  failedPolicies: failedPolicies,
);

void main() {
  testWidgets('renders a TextField labelled with the prompt', (tester) async {
    final callback = _callback();

    await _pump(
      tester,
      StringAttributeInputCallbackView(callback: callback, onChanged: () {}),
    );

    expect(find.widgetWithText(TextField, 'First Name'), findsOneWidget);
  });

  testWidgets('appends " *" to the label when the attribute is required', (
    tester,
  ) async {
    final callback = _callback(required: true);

    await _pump(
      tester,
      StringAttributeInputCallbackView(callback: callback, onChanged: () {}),
    );

    expect(find.widgetWithText(TextField, 'First Name *'), findsOneWidget);
  });

  testWidgets(
    'falls back to the attribute name when prompt is null',
    (tester) async {
      final callback = _callback(prompt: null, name: 'givenName');

      await _pump(
        tester,
        StringAttributeInputCallbackView(
          callback: callback,
          onChanged: () {},
        ),
      );

      expect(find.widgetWithText(TextField, 'givenName'), findsOneWidget);
    },
  );

  testWidgets(
    'entering text updates the callback value and invokes onChanged',
    (tester) async {
      final callback = _callback();
      var changed = false;

      await _pump(
        tester,
        StringAttributeInputCallbackView(
          callback: callback,
          onChanged: () => changed = true,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Jane');
      await tester.pump();

      expect(callback.value, 'Jane');
      expect(changed, isTrue);
    },
  );

  testWidgets('renders failedPolicies as error text below the field', (
    tester,
  ) async {
    final callback = _callback(
      failedPolicies: [
        {'policyRequirement': 'REQUIRED'},
      ],
    );

    await _pump(
      tester,
      StringAttributeInputCallbackView(callback: callback, onChanged: () {}),
    );

    expect(find.text('REQUIRED'), findsOneWidget);
  });

  testWidgets('shows no error text when there are no failedPolicies', (
    tester,
  ) async {
    final callback = _callback();

    await _pump(
      tester,
      StringAttributeInputCallbackView(callback: callback, onChanged: () {}),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.errorText, isNull);
  });
}
