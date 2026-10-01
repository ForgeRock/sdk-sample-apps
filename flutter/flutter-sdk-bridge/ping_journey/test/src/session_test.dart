/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';

void main() {
  group('Session.fromJson', () {
    test('parses a full, well-formed payload', () {
      final session = Session.fromJson({
        'accessToken': 'access-123',
        'refreshToken': 'refresh-456',
        'idToken': 'id-789',
        'tokenType': 'Bearer',
        'scope': 'openid profile',
        'expiresIn': 3600,
        'userInfo': {'sub': 'user-1'},
      });

      expect(session.accessToken, 'access-123');
      expect(session.refreshToken, 'refresh-456');
      expect(session.idToken, 'id-789');
      expect(session.tokenType, 'Bearer');
      expect(session.scope, 'openid profile');
      expect(session.expiresIn, 3600);
      expect(session.userInfo, {'sub': 'user-1'});
    });

    test('parses a payload with no refreshToken/userInfo', () {
      final session = Session.fromJson({
        'accessToken': 'access-123',
        'expiresIn': 3600,
      });

      expect(session.accessToken, 'access-123');
      expect(session.refreshToken, isNull);
      expect(session.userInfo, isEmpty);
    });

    test('throws FormatException when accessToken is missing', () {
      expect(
        () => Session.fromJson({'expiresIn': 3600}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when accessToken is empty', () {
      expect(
        () => Session.fromJson({'accessToken': '', 'expiresIn': 3600}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when expiresIn has the wrong type', () {
      expect(
        () => Session.fromJson({
          'accessToken': 'access-123',
          'expiresIn': '3600',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when userInfo has the wrong type', () {
      expect(
        () => Session.fromJson({
          'accessToken': 'access-123',
          'expiresIn': 3600,
          'userInfo': 'not-a-map',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when idToken has the wrong type', () {
      expect(
        () => Session.fromJson({
          'accessToken': 'access-123',
          'expiresIn': 3600,
          'idToken': 42,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when tokenType has the wrong type', () {
      expect(
        () => Session.fromJson({
          'accessToken': 'access-123',
          'expiresIn': 3600,
          'tokenType': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when scope has the wrong type', () {
      expect(
        () => Session.fromJson({
          'accessToken': 'access-123',
          'expiresIn': 3600,
          'scope': ['openid'],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Session.toJson', () {
    test('round-trips through fromJson', () {
      const original = Session(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        idToken: 'id-789',
        tokenType: 'Bearer',
        scope: 'openid profile',
        expiresIn: 3600,
        userInfo: {'sub': 'user-1'},
      );

      final roundTripped = Session.fromJson(original.toJson());

      expect(roundTripped.accessToken, original.accessToken);
      expect(roundTripped.refreshToken, original.refreshToken);
      expect(roundTripped.idToken, original.idToken);
      expect(roundTripped.tokenType, original.tokenType);
      expect(roundTripped.scope, original.scope);
      expect(roundTripped.expiresIn, original.expiresIn);
      expect(roundTripped.userInfo, original.userInfo);
    });

    test('omits refreshToken when null', () {
      const session = Session(accessToken: 'access-123', expiresIn: 3600);
      expect(session.toJson().containsKey('refreshToken'), isFalse);
    });

    test('omits idToken/tokenType/scope when null', () {
      const session = Session(accessToken: 'access-123', expiresIn: 3600);
      final json = session.toJson();
      expect(json.containsKey('idToken'), isFalse);
      expect(json.containsKey('tokenType'), isFalse);
      expect(json.containsKey('scope'), isFalse);
    });
  });
}
