/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';
import 'package:ping_journey/src/node_mapper.dart';

void main() {
  group('NodeMapper.map', () {
    test(
      'maps NodeType.continueNode to ContinueNode, carrying journeyId + page metadata',
      () {
        final message = NodeMessage(
          type: NodeType.continueNode,
          header: 'Sign On',
          pageDescription: 'Enter your credentials',
          stage: 'Login',
          callbacks: [
            CallbackMessage(
              type: 'NameCallback',
              index: 0,
              prompt: 'User Name',
              value: '',
            ),
          ],
        );

        final node = NodeMapper.map(message, 'journey-1');

        expect(node, isA<ContinueNode>());
        final continueNode = node as ContinueNode;
        expect(continueNode.journeyId, 'journey-1');
        expect(continueNode.header, 'Sign On');
        expect(continueNode.description, 'Enter your credentials');
        expect(continueNode.stage, 'Login');
        expect(continueNode.callbacks, hasLength(1));
        expect(continueNode.callbacks.single, isA<NameCallback>());
      },
    );

    test('maps NodeType.successNode to SuccessNode', () {
      final node = NodeMapper.map(
        NodeMessage(type: NodeType.successNode),
        'journey-1',
      );
      expect(node, isA<SuccessNode>());
    });

    test(
      'maps NodeType.errorNode to ErrorNode, preserving message and status',
      () {
        final node = NodeMapper.map(
          NodeMessage(
            type: NodeType.errorNode,
            message: 'Invalid credentials',
            status: 401,
          ),
          'journey-1',
        );

        expect(node, isA<ErrorNode>());
        final errorNode = node as ErrorNode;
        expect(errorNode.message, 'Invalid credentials');
        expect(errorNode.status, 401);
      },
    );

    test(
      'maps NodeType.errorNode with no status to a null status (Android has no equivalent field)',
      () {
        final node = NodeMapper.map(
          NodeMessage(type: NodeType.errorNode, message: 'Invalid credentials'),
          'journey-1',
        );

        expect((node as ErrorNode).status, isNull);
      },
    );

    test('maps NodeType.failureNode to FailureNode, preserving cause', () {
      final node = NodeMapper.map(
        NodeMessage(type: NodeType.failureNode, cause: 'Network error'),
        'journey-1',
      );

      expect(node, isA<FailureNode>());
      expect((node as FailureNode).cause, 'Network error');
    });

    test('falls back to a default cause when a FailureNode has none', () {
      final node = NodeMapper.map(
        NodeMessage(type: NodeType.failureNode),
        'journey-1',
      );
      expect((node as FailureNode).cause, isNotEmpty);
    });
  });

  group('NodeMapper.mapCallback — representative ContinueNode re-inflation', () {
    test(
      're-inflates NameCallback + PasswordCallback with correct per-type indices',
      () {
        final message = NodeMessage(
          type: NodeType.continueNode,
          callbacks: [
            CallbackMessage(
              type: 'NameCallback',
              index: 0,
              prompt: 'User Name',
            ),
            CallbackMessage(
              type: 'PasswordCallback',
              index: 0,
              prompt: 'Password',
            ),
          ],
        );

        final node = NodeMapper.map(message, 'journey-1') as ContinueNode;

        final name = node.callbacks[0];
        expect(name, isA<NameCallback>());
        expect(name.type, 'NameCallback');
        expect(name.index, 0);
        expect(name.prompt, 'User Name');

        final password = node.callbacks[1];
        expect(password, isA<PasswordCallback>());
        expect(password.type, 'PasswordCallback');
        expect(password.index, 0);
      },
    );

    test(
      'assigns a running per-type index when multiple callbacks share a type',
      () {
        final message = NodeMessage(
          type: NodeType.continueNode,
          callbacks: [
            CallbackMessage(
              type: 'StringAttributeInputCallback',
              index: 0,
              name: 'firstName',
            ),
            CallbackMessage(
              type: 'StringAttributeInputCallback',
              index: 1,
              name: 'lastName',
            ),
          ],
        );

        final node = NodeMapper.map(message, 'journey-1') as ContinueNode;

        expect((node.callbacks[0] as StringAttributeInputCallback).index, 0);
        expect(
          (node.callbacks[0] as StringAttributeInputCallback).name,
          'firstName',
        );
        expect((node.callbacks[1] as StringAttributeInputCallback).index, 1);
        expect(
          (node.callbacks[1] as StringAttributeInputCallback).name,
          'lastName',
        );
      },
    );
  });

  group('Callback.toValue()', () {
    test('NameCallback submits its text value', () {
      final callback = NodeMapper.mapCallback(
        CallbackMessage(type: 'NameCallback', index: 0, value: 'jdoe'),
      );

      final value = callback.toValue();
      expect(value, isNotNull);
      expect(value!.type, 'NameCallback');
      expect(value.index, 0);
      expect(value.value, 'jdoe');
    });

    test('ChoiceCallback submits the selected index as an int', () {
      final callback = NodeMapper.mapCallback(
        CallbackMessage(
          type: 'ChoiceCallback',
          index: 0,
          choices: const ['A', 'B'],
          selectedIndex: 1,
        ),
      );

      expect(callback.toValue()!.value, 1);
    });

    test('KbaCreateCallback submits an object-shaped value', () {
      final callback =
          NodeMapper.mapCallback(
                CallbackMessage(
                  type: 'KbaCreateCallback',
                  index: 0,
                  predefinedQuestions: const ['What is your pet\'s name?'],
                ),
              )
              as KbaCreateCallback;
      callback.selectedQuestion = 'What is your pet\'s name?';
      callback.selectedAnswer = 'Fido';

      final value = callback.toValue().value as Map<Object?, Object?>;
      expect(value['selectedQuestion'], 'What is your pet\'s name?');
      expect(value['selectedAnswer'], 'Fido');
      expect(value['allowUserDefinedQuestions'], false);
    });

    test('TextOutputCallback is output-only and contributes no value', () {
      final callback = NodeMapper.mapCallback(
        CallbackMessage(
          type: 'TextOutputCallback',
          index: 0,
          message: 'Welcome',
        ),
      );

      expect(callback, isA<TextOutputCallback>());
      expect(callback.toValue(), isNull);
    });

    test(
      'PasswordCallback re-inflates to an empty password (native never sends it back), '
      'then submits whatever the UI sets',
      () {
        final callback =
            NodeMapper.mapCallback(
                  CallbackMessage(type: 'PasswordCallback', index: 0),
                )
                as PasswordCallback;
        expect(callback.password, '');

        callback.password = 'super-secret';

        final value = callback.toValue();
        expect(value.type, 'PasswordCallback');
        expect(value.index, 0);
        expect(value.value, 'super-secret');
      },
    );

    test('ValidatedUsernameCallback submits the username value', () {
      final callback =
          NodeMapper.mapCallback(
                CallbackMessage(
                  type: 'ValidatedUsernameCallback',
                  index: 0,
                  value: 'jdoe',
                ),
              )
              as ValidatedUsernameCallback;

      final value = callback.toValue();
      expect(value.type, 'ValidatedUsernameCallback');
      expect(value.value, 'jdoe');
    });

    test(
      'ValidatedPasswordCallback re-inflates to an empty password (native never sends it '
      'back), then submits whatever the UI sets',
      () {
        final callback =
            NodeMapper.mapCallback(
                  CallbackMessage(type: 'ValidatedPasswordCallback', index: 0),
                )
                as ValidatedPasswordCallback;
        expect(callback.password, '');

        callback.password = 'super-secret';

        final value = callback.toValue();
        expect(value.type, 'ValidatedPasswordCallback');
        expect(value.value, 'super-secret');
      },
    );

    test('TermsAndConditionsCallback submits the accepted flag', () {
      final callback =
          NodeMapper.mapCallback(
                CallbackMessage(type: 'TermsAndConditionsCallback', index: 0),
              )
              as TermsAndConditionsCallback;
      callback.accepted = true;

      final value = callback.toValue();
      expect(value.type, 'TermsAndConditionsCallback');
      expect(value.value, true);
    });

    test('TextInputCallback submits its text value', () {
      final callback =
          NodeMapper.mapCallback(
                CallbackMessage(
                  type: 'TextInputCallback',
                  index: 0,
                  value: 'hello',
                ),
              )
              as TextInputCallback;

      final value = callback.toValue();
      expect(value.type, 'TextInputCallback');
      expect(value.value, 'hello');
    });

    test('StringAttributeInputCallback submits its string value', () {
      final callback =
          NodeMapper.mapCallback(
                CallbackMessage(
                  type: 'StringAttributeInputCallback',
                  index: 0,
                  name: 'firstName',
                  value: 'Alice',
                ),
              )
              as StringAttributeInputCallback;

      final value = callback.toValue();
      expect(value.type, 'StringAttributeInputCallback');
      expect(value.value, 'Alice');
    });

    test('NumberAttributeInputCallback submits its numeric value', () {
      final callback =
          NodeMapper.mapCallback(
                CallbackMessage(
                  type: 'NumberAttributeInputCallback',
                  index: 0,
                  name: 'age',
                  value: 42,
                ),
              )
              as NumberAttributeInputCallback;

      final value = callback.toValue();
      expect(value.type, 'NumberAttributeInputCallback');
      expect(value.value, 42.0);
    });

    test('BooleanAttributeInputCallback submits its boolean value', () {
      final callback =
          NodeMapper.mapCallback(
                CallbackMessage(
                  type: 'BooleanAttributeInputCallback',
                  index: 0,
                  name: 'subscribed',
                  value: true,
                ),
              )
              as BooleanAttributeInputCallback;

      final value = callback.toValue();
      expect(value.type, 'BooleanAttributeInputCallback');
      expect(value.value, true);
    });
  });
}
