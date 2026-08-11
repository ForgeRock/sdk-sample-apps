/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';

void main() {
  group('CallbackHelpers.resolveFieldKind', () {
    const expectedKinds = {
      CallbackType.nameCallback: FieldKind.text,
      CallbackType.passwordCallback: FieldKind.password,
      CallbackType.validatedUsernameCallback: FieldKind.text,
      CallbackType.validatedPasswordCallback: FieldKind.password,
      CallbackType.choiceCallback: FieldKind.choice,
      CallbackType.kbaCreateCallback: FieldKind.kba,
      CallbackType.termsAndConditionsCallback: FieldKind.boolean,
      CallbackType.textInputCallback: FieldKind.text,
      CallbackType.textOutputCallback: FieldKind.output,
      CallbackType.stringAttributeInputCallback: FieldKind.text,
      CallbackType.numberAttributeInputCallback: FieldKind.number,
      CallbackType.booleanAttributeInputCallback: FieldKind.boolean,
    };

    expectedKinds.forEach((type, expectedKind) {
      test('$type -> $expectedKind', () {
        expect(CallbackHelpers.resolveFieldKind(type), expectedKind);
      });
    });

    test('unrecognized type resolves to unknown', () {
      expect(
        CallbackHelpers.resolveFieldKind('SomeFutureCallback'),
        FieldKind.unknown,
      );
    });
  });

  group('CallbackHelpers.resolveExecutionMode', () {
    const manualTypes = [
      CallbackType.nameCallback,
      CallbackType.passwordCallback,
      CallbackType.textInputCallback,
      CallbackType.stringAttributeInputCallback,
      CallbackType.numberAttributeInputCallback,
      CallbackType.booleanAttributeInputCallback,
      CallbackType.choiceCallback,
      CallbackType.kbaCreateCallback,
      CallbackType.termsAndConditionsCallback,
      CallbackType.validatedUsernameCallback,
      CallbackType.validatedPasswordCallback,
    ];

    for (final type in manualTypes) {
      test('$type -> manual', () {
        expect(
          CallbackHelpers.resolveExecutionMode(type),
          ExecutionMode.manual,
        );
      });
    }

    test('TextOutputCallback -> outputOnly', () {
      expect(
        CallbackHelpers.resolveExecutionMode(CallbackType.textOutputCallback),
        ExecutionMode.outputOnly,
      );
    });

    test('SuspendedTextOutputCallback -> outputOnly', () {
      expect(
        CallbackHelpers.resolveExecutionMode(
          CallbackType.suspendedTextOutputCallback,
        ),
        ExecutionMode.outputOnly,
      );
    });

    test('unrecognized type resolves to unsupported', () {
      expect(
        CallbackHelpers.resolveExecutionMode('SomeFutureCallback'),
        ExecutionMode.unsupported,
      );
    });
  });
}
