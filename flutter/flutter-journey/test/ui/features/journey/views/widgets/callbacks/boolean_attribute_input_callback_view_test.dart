/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/boolean_attribute_input_callback_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

BooleanAttributeInputCallback _callback({
  String name = 'marketingOptIn',
  String? prompt = 'Receive marketing emails',
  bool required = false,
  bool value = false,
}) => BooleanAttributeInputCallback(
  type: 'BooleanAttributeInputCallback',
  index: 0,
  prompt: prompt,
  name: name,
  required: required,
  value: value,
);

void main() {
  testWidgets('renders a SwitchListTile labelled with the prompt and initial value', (
    tester,
  ) async {
    final callback = _callback(value: true);

    await _pump(
      tester,
      BooleanAttributeInputCallbackView(callback: callback, onChanged: () {}),
    );

    expect(
      find.widgetWithText(SwitchListTile, 'Receive marketing emails'),
      findsOneWidget,
    );
    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isTrue);
  });

  testWidgets('appends " *" to the label when the attribute is required', (
    tester,
  ) async {
    final callback = _callback(required: true);

    await _pump(
      tester,
      BooleanAttributeInputCallbackView(callback: callback, onChanged: () {}),
    );

    expect(
      find.widgetWithText(SwitchListTile, 'Receive marketing emails *'),
      findsOneWidget,
    );
  });

  testWidgets(
    'falls back to the attribute name when prompt is null',
    (tester) async {
      final callback = _callback(prompt: null, name: 'marketingOptIn');

      await _pump(
        tester,
        BooleanAttributeInputCallbackView(
          callback: callback,
          onChanged: () {},
        ),
      );

      expect(
        find.widgetWithText(SwitchListTile, 'marketingOptIn'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'toggling the switch updates the callback value and invokes onChanged',
    (tester) async {
      final callback = _callback(value: false);
      var changed = false;

      await _pump(
        tester,
        BooleanAttributeInputCallbackView(
          callback: callback,
          onChanged: () => changed = true,
        ),
      );

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(callback.value, isTrue);
      expect(changed, isTrue);
    },
  );
}
