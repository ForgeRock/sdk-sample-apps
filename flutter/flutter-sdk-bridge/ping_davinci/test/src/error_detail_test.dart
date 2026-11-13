/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_davinci/ping_davinci.dart';
import 'package:ping_davinci/src/node_mapper.dart';

/// A captured 400 body from `example/integration_test/support/fixtures/`.
Map<String, Object?> _captured(String name) =>
    (jsonDecode(
              File(
                'example/integration_test/support/fixtures/$name.json',
              ).readAsStringSync(),
            )
            as Map)
        .cast<String, Object?>();

/// [body]'s `details` in the shape both native mappers send (`NodeMessage.errorDetails`): the
/// SDK model's fields only, with `innerError` as its requirement-to-message map.
List<Object?> _wireDetails(Map<String, Object?> body) => [
  for (final detail in (body['details']! as List).cast<Map<String, Object?>>())
    <String, Object?>{
      'statusCode': detail['statusCode'],
      'rawResponse': () {
        final raw = (detail['rawResponse']! as Map).cast<String, Object?>();
        return <String, Object?>{
          'id': raw['id'],
          'code': raw['code'],
          'message': raw['message'],
          'details': (raw['details'] as List?)
              ?.cast<Map<String, Object?>>()
              .map((error) {
                final inner = (error['innerError'] as Map?)
                    ?.cast<String, Object?>();
                return <String, Object?>{
                  'code': error['code'],
                  'target': error['target'],
                  'message': error['message'],
                  'innerError': inner == null
                      ? null
                      : <String, Object?>{
                          for (final requirement
                              in (inner['unsatisfiedRequirements']! as List)
                                  .cast<String>())
                            requirement: inner[requirement],
                        },
                };
              })
              .toList(),
        };
      }(),
    },
];

/// [message] after a trip through the generated codec — what the platform channel delivers, with
/// every nested map a `Map<Object?, Object?>` and every list a `List<Object?>`.
NodeMessage _overTheChannel(NodeMessage message) {
  final codec = PingDaVinciHostApi.pigeonChannelCodec;
  return codec.decodeMessage(codec.encodeMessage(message))! as NodeMessage;
}

ErrorNode _errorNode(String fixture) {
  final body = _captured(fixture);
  return NodeMapper.map(
        _overTheChannel(
          NodeMessage(
            type: NodeType.errorNode,
            message: body['message'] as String?,
            status: 400,
            input: body,
            errorDetails: _wireDetails(body),
          ),
        ),
      )
      as ErrorNode;
}

ErrorDetail _detail(List<ErrorFieldDetail> details, {String? message}) =>
    ErrorDetail(
      statusCode: 400,
      rawResponse: ErrorRawResponse(message: message, details: details),
    );

void main() {
  group('ErrorDetail', () {
    test('decodes a real non-empty nested body after a channel round trip', () {
      // The exact shape that broke ping_journey's failedPolicies: a non-empty nested map. An
      // empty list would decode either way.
      final node = _errorNode('ssoRegisterWeakPassword');

      final detail = node.errorDetails.single;
      expect(detail.statusCode, 400);
      expect(detail.rawResponse.code, 'INVALID_DATA');
      final error = detail.rawResponse.details.single;
      expect(error.code, 'INVALID_VALUE');
      expect(error.target, 'password');
      expect(error.innerErrors.keys.toSet(), {
        'minCharacters',
        'length',
        'minUniqueCharacters',
        'excludesCommonlyUsed',
      });
      expect(
        error.innerErrors['length'],
        'The provided password is shorter than the minimum required length of 8 characters',
      );
      expect(node.input['code'], 'invalidValue');
    });

    test('flattens a target message and its inner errors in key order', () {
      final node = _errorNode('ssoRegisterWeakPassword');
      final inner =
          node.errorDetails.single.rawResponse.details.single.innerErrors;

      expect(node.fieldErrors.keys, ['password']);
      expect(
        node.fieldErrors['password'],
        [
          'User password did not satisfy password policy requirements',
          inner['excludesCommonlyUsed'],
          inner['length'],
          inner['minCharacters'],
          inner['minUniqueCharacters'],
        ].join('\n'),
      );
    });

    test('a sign-on failure names no field', () {
      final node = _errorNode('ssoWrongPassword');

      expect(node.message, 'Invalid username and/or password');
      final detail = node.errorDetails.single;
      expect(detail.statusCode, 200);
      expect(detail.rawResponse.code, isNull);
      expect(detail.rawResponse.details, isEmpty);
      expect(node.fieldErrors, isEmpty);
    });

    test('several details naming one target append, without repeats', () {
      final fieldErrors = ErrorDetail.fieldErrors([
        _detail([
          const ErrorFieldDetail(target: 'email', message: 'Taken'),
          const ErrorFieldDetail(target: 'email', message: 'Too long'),
        ]),
        _detail([const ErrorFieldDetail(target: 'email', message: 'Taken')]),
      ]);

      expect(fieldErrors, {'email': 'Taken\nToo long'});
    });

    test(
      'a target with no message falls back to the response, then the code',
      () {
        expect(
          ErrorDetail.fieldErrors([
            _detail([
              const ErrorFieldDetail(target: 'email', code: 'INVALID_VALUE'),
            ], message: 'One or more validation errors'),
          ]),
          {'email': 'One or more validation errors'},
        );
        expect(
          ErrorDetail.fieldErrors([
            _detail([
              const ErrorFieldDetail(target: 'email', code: 'INVALID_VALUE'),
            ]),
          ]),
          {'email': 'INVALID_VALUE'},
        );
      },
    );

    test('details without a target, or with an empty one, name no field', () {
      expect(
        ErrorDetail.fieldErrors([
          _detail([
            const ErrorFieldDetail(message: 'No target'),
            const ErrorFieldDetail(target: '', message: 'Empty target'),
          ]),
        ]),
        isEmpty,
      );
    });

    test('skips wire entries without a status or raw response', () {
      final details = ErrorDetail.listFromWire([
        null,
        <Object?, Object?>{'rawResponse': <Object?, Object?>{}},
        <Object?, Object?>{'statusCode': 409},
        <Object?, Object?>{
          'statusCode': 409,
          'rawResponse': <Object?, Object?>{'code': 'KEPT'},
        },
      ]);

      expect(details.single.rawResponse.code, 'KEPT');
      expect(details.single.rawResponse.details, isEmpty);
    });
  });
}
