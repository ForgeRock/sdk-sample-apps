/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_davinci/ping_davinci.dart';
import 'package:ping_davinci/src/node_mapper.dart';

/// Compiles only while the `switch` covers every [DaVinciNode] subtype with no default branch —
/// the proof that the hierarchy is sealed and exhaustive.
String describe(DaVinciNode node) => switch (node) {
  ContinueNode() => 'continue',
  SuccessNode() => 'success',
  ErrorNode() => 'error',
  FailureNode() => 'failure',
};

void main() {
  group('NodeMapper', () {
    test('maps a continue node with its page fields and collectors', () {
      final node = NodeMapper.map(
        NodeMessage(
          type: NodeType.continueNode,
          id: 'node-1',
          name: 'Sign On',
          pageDescription: 'Enter your credentials',
          category: 'CUSTOM_HTML',
          collectors: [
            CollectorMessage(
              type: 'TEXT',
              index: 0,
              kind: CollectorKind.text,
              id: 'username',
              key: 'username',
              label: 'Username',
              required: true,
              value: 'alice',
            ),
            null,
            CollectorMessage(
              type: 'SUBMIT_BUTTON',
              index: 1,
              kind: CollectorKind.submit,
              key: 'submit',
            ),
          ],
        ),
      );

      expect(node, isA<ContinueNode>());
      final continueNode = node as ContinueNode;
      expect(continueNode.id, 'node-1');
      expect(continueNode.name, 'Sign On');
      expect(continueNode.pageDescription, 'Enter your credentials');
      expect(continueNode.category, 'CUSTOM_HTML');
      expect(continueNode.collectors, hasLength(2));
      final text = continueNode.collectors.first as TextCollector;
      expect(text.type, 'TEXT');
      expect(text.index, 0);
      expect(text.id, 'username');
      expect(text.label, 'Username');
      expect(text.required, isTrue);
      expect(text.value, 'alice');
      expect(
        (continueNode.collectors.last as SubmitCollector).required,
        isFalse,
      );
      expect(continueNode.unsupportedFields, isEmpty);
    });

    test('classifies the fields the native factory dropped', () {
      final node =
          NodeMapper.map(
                NodeMessage(
                  type: NodeType.continueNode,
                  unsupportedFields: <Object?>[
                    <Object?, Object?>{'key': null, 'type': 'ERROR_DISPLAY'},
                    <Object?, Object?>{'key': 'protectsdk', 'type': 'PROTECT'},
                    <Object?, Object?>{'key': 'future', 'type': 'FUTURE_FIELD'},
                    'not a map',
                  ],
                ),
              )
              as ContinueNode;

      expect(node.unsupportedFields.map((f) => (f.key, f.type, f.reason)), [
        (null, 'ERROR_DISPLAY', UnsupportedFieldReason.knownIgnorable),
        ('protectsdk', 'PROTECT', UnsupportedFieldReason.addOnRequired),
        ('future', 'FUTURE_FIELD', UnsupportedFieldReason.unknown),
      ]);
    });

    test(
      'reports a collector it has no Dart type for, and keeps the rest addressable',
      () {
        final node =
            NodeMapper.map(
                  NodeMessage(
                    type: NodeType.continueNode,
                    collectors: [
                      // An add-on linked natively whose Dart package isn't registered.
                      CollectorMessage(
                        type: 'MOBILE_PAIRING',
                        index: 0,
                        kind: 'mobilePairing',
                        key: 'pair',
                      ),
                      CollectorMessage(
                        type: 'SUBMIT_BUTTON',
                        index: 1,
                        kind: CollectorKind.submit,
                        key: 'submit',
                      ),
                    ],
                    unsupportedFields: <Object?>[
                      <Object?, Object?>{'key': null, 'type': 'ERROR_DISPLAY'},
                    ],
                  ),
                )
                as ContinueNode;

        final submit = node.collectors.single as SubmitCollector..select();
        expect(submit.toValue()!.index, 1);
        final [pairing, errorDisplay] = node.unsupportedFields;
        expect(pairing.reason, UnsupportedFieldReason.notBridged);
        expect(pairing.kind, 'mobilePairing');
        expect(pairing.key, 'pair');
        expect(pairing.type, 'MOBILE_PAIRING');
        expect(errorDisplay.reason, UnsupportedFieldReason.knownIgnorable);
      },
    );

    test('maps a continue node with no collectors to an empty list', () {
      final node = NodeMapper.map(NodeMessage(type: NodeType.continueNode));
      expect((node as ContinueNode).collectors, isEmpty);
    });

    test('maps success, error, and failure nodes', () {
      expect(
        NodeMapper.map(NodeMessage(type: NodeType.successNode)),
        isA<SuccessNode>(),
      );

      final error = NodeMapper.map(
        NodeMessage(
          type: NodeType.errorNode,
          message: 'Invalid value',
          status: 400,
        ),
      );
      expect(error, isA<ErrorNode>());
      expect((error as ErrorNode).message, 'Invalid value');
      expect(error.status, 400);
      // No collectors on the wire: nothing to retry from.
      expect(error.continueNode, isNull);
      expect(error.errorDetails, isEmpty);
      expect(error.fieldErrors, isEmpty);

      final failure = NodeMapper.map(
        NodeMessage(type: NodeType.failureNode, cause: 'Network down'),
      );
      expect((failure as FailureNode).cause, 'Network down');
    });

    test('defaults missing error and failure text', () {
      expect(
        (NodeMapper.map(NodeMessage(type: NodeType.errorNode)) as ErrorNode)
            .message,
        '',
      );
      expect(
        (NodeMapper.map(NodeMessage(type: NodeType.failureNode)) as FailureNode)
            .cause,
        'Unknown failure',
      );
    });

    test('every node type maps to its own subtype', () {
      expect(
        NodeType.values.map(
          (type) => describe(NodeMapper.map(NodeMessage(type: type))),
        ),
        ['continue', 'success', 'error', 'failure'],
      );
    });
  });

  group('ErrorNode', () {
    NodeMessage registration() => NodeMessage(
      type: NodeType.errorNode,
      message:
          'password: User password did not satisfy password policy requirements',
      status: 400,
      input: {'code': 'invalidValue', 'httpResponseCode': 400},
      name: 'Registration',
      collectors: [
        CollectorMessage(
          type: 'TEXT',
          index: 0,
          kind: CollectorKind.text,
          key: 'email',
          value: 'flutter@example.com',
        ),
        CollectorMessage(
          type: 'PASSWORD',
          index: 1,
          kind: CollectorKind.password,
          key: 'password',
        ),
        CollectorMessage(
          type: 'SUBMIT_BUTTON',
          index: 2,
          kind: CollectorKind.submit,
          key: 'REGISTER',
        ),
      ],
      unsupportedFields: [
        {'key': null, 'type': 'ERROR_DISPLAY'},
      ],
      errorDetails: [
        {
          'statusCode': 400,
          'rawResponse': {
            'code': 'INVALID_DATA',
            'details': [
              {
                'code': 'INVALID_VALUE',
                'target': 'password',
                'message': 'Too weak',
                'innerError': {'length': 'Too short'},
              },
              {'target': 'nickname', 'message': 'Not on this form'},
            ],
          },
        },
      ],
    );

    test('carries the retry node, with server errors on its collectors', () {
      final node = NodeMapper.map(registration()) as ErrorNode;

      expect(node.status, 400);
      expect(node.input['code'], 'invalidValue');
      expect(node.fieldErrors, {
        'password': 'Too weak\nToo short',
        'nickname': 'Not on this form',
      });
      final retry = node.continueNode!;
      expect(retry.name, 'Registration');
      expect(retry.unsupportedFields.single.type, 'ERROR_DISPLAY');
      final [email, password, submit] = retry.collectors;
      expect((email as TextCollector).value, 'flutter@example.com');
      expect(email.serverError, isNull);
      expect(
        (password as PasswordCollector).serverError,
        'Too weak\nToo short',
      );
      expect((submit as SubmitCollector).serverError, isNull);
    });

    test('a retry node with no collectors is still a retry node', () {
      final node =
          NodeMapper.map(
                NodeMessage(
                  type: NodeType.errorNode,
                  collectors: const <CollectorMessage?>[],
                ),
              )
              as ErrorNode;

      expect(node.continueNode, isNotNull);
      expect(node.continueNode!.collectors, isEmpty);
    });
  });

  group('ContinueNode.canSubmit', () {
    ContinueNode form(List<CollectorMessage> collectors) =>
        NodeMapper.map(
              NodeMessage(type: NodeType.continueNode, collectors: collectors),
            )
            as ContinueNode;

    CollectorMessage field(int index, String kind, {Object? value}) =>
        CollectorMessage(
          type: kind.toUpperCase(),
          index: index,
          kind: kind,
          key: 'field-$index',
          required: true,
          value: value,
        );

    test('needs every required field filled, buttons exempt', () {
      final node = form([
        field(0, CollectorKind.text),
        field(1, CollectorKind.boolean),
        field(2, CollectorKind.multiSelect),
        field(3, CollectorKind.phoneNumber),
        field(4, CollectorKind.submit),
        CollectorMessage(
          type: 'TEXT',
          index: 5,
          kind: CollectorKind.text,
          key: 'optional',
        ),
      ]);
      final [text, box, multi, phone, ...] = node.collectors;
      expect(node.canSubmit, isFalse);

      (text as TextCollector).value = 'flutter';
      (box as BooleanCollector).value = true;
      (multi as MultiSelectCollector).value = ['a'];
      expect(node.canSubmit, isFalse, reason: 'the phone number is empty');

      (phone as PhoneNumberCollector).value = const PhoneNumberValue(
        countryCode: 'US',
        phoneNumber: '',
      );
      expect(
        node.canSubmit,
        isFalse,
        reason: 'a country code alone is not a number',
      );

      phone.value = const PhoneNumberValue(
        countryCode: 'US',
        phoneNumber: '2015550123',
      );
      expect(node.canSubmit, isTrue);

      box.value = false;
      expect(node.canSubmit, isFalse, reason: 'a required box must be checked');
    });

    test('a form with no required fields can always submit', () {
      expect(form(const <CollectorMessage>[]).canSubmit, isTrue);
    });
  });
}
