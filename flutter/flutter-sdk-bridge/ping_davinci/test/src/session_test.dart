/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_davinci/ping_davinci.dart';

void main() {
  group('DaVinciSession', () {
    test('round-trips through JSON', () {
      final session = DaVinciSession.fromJson({'authorizationCode': 'code'});

      expect(session.authorizationCode, 'code');
      expect(session.toJson(), {'authorizationCode': 'code'});
    });

    for (final (label, json) in <(String, Map<String, Object?>)>[
      ('missing', {}),
      ('empty', {'authorizationCode': ''}),
      ('not a string', {'authorizationCode': 42}),
    ]) {
      test('throws a FormatException when the code is $label', () {
        expect(() => DaVinciSession.fromJson(json), throwsFormatException);
      });
    }
  });

  group('DaVinciToken', () {
    test('round-trips every field', () {
      final json = <String, Object?>{
        'accessToken': 'access',
        'tokenType': 'Bearer',
        'scope': 'openid',
        'expiresIn': 60,
        'refreshToken': 'refresh',
        'idToken': 'id',
      };

      expect(DaVinciToken.fromJson(json).toJson(), json);
    });

    test('omits absent optional fields from toJson', () {
      final token = DaVinciToken.fromJson({
        'accessToken': 'access',
        'expiresIn': 60,
        'refreshToken': null,
      });

      expect(token.refreshToken, isNull);
      expect(token.toJson(), {'accessToken': 'access', 'expiresIn': 60});
    });

    for (final (label, json) in <(String, Map<String, Object?>)>[
      ('accessToken is missing', {'expiresIn': 1}),
      ('accessToken is empty', {'accessToken': '', 'expiresIn': 1}),
      ('expiresIn is missing', {'accessToken': 'a'}),
      ('expiresIn is not an int', {'accessToken': 'a', 'expiresIn': '1'}),
      (
        'tokenType is not a string',
        {'accessToken': 'a', 'expiresIn': 1, 'tokenType': 1},
      ),
      (
        'scope is not a string',
        {'accessToken': 'a', 'expiresIn': 1, 'scope': true},
      ),
      (
        'refreshToken is not a string',
        {'accessToken': 'a', 'expiresIn': 1, 'refreshToken': 1},
      ),
      (
        'idToken is not a string',
        {'accessToken': 'a', 'expiresIn': 1, 'idToken': <String>[]},
      ),
    ]) {
      test('throws a FormatException when $label', () {
        expect(() => DaVinciToken.fromJson(json), throwsFormatException);
      });
    }
  });
}
