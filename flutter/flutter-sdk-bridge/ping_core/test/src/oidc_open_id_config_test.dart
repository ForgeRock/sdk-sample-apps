/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_core/ping_core.dart';

void main() {
  group('OidcOpenIdConfig construction', () {
    test('exposes all fields when fully constructed', () {
      const config = OidcOpenIdConfig(
        authorizationEndpoint: 'https://example.com/authorize',
        tokenEndpoint: 'https://example.com/token',
        userinfoEndpoint: 'https://example.com/userinfo',
        endSessionEndpoint: 'https://example.com/endSession',
        pingEndIdpSessionEndpoint: 'https://example.com/pingEndSession',
        revocationEndpoint: 'https://example.com/revoke',
      );

      expect(config.authorizationEndpoint, 'https://example.com/authorize');
      expect(config.tokenEndpoint, 'https://example.com/token');
      expect(config.userinfoEndpoint, 'https://example.com/userinfo');
      expect(config.endSessionEndpoint, 'https://example.com/endSession');
      expect(
        config.pingEndIdpSessionEndpoint,
        'https://example.com/pingEndSession',
      );
      expect(config.revocationEndpoint, 'https://example.com/revoke');
    });

    test('leaves optional endpoints null when omitted', () {
      const config = OidcOpenIdConfig(
        authorizationEndpoint: 'https://example.com/authorize',
        tokenEndpoint: 'https://example.com/token',
        userinfoEndpoint: 'https://example.com/userinfo',
      );

      expect(config.endSessionEndpoint, isNull);
      expect(config.pingEndIdpSessionEndpoint, isNull);
      expect(config.revocationEndpoint, isNull);
    });
  });

  group('OidcOpenIdConfig.fromJson', () {
    test('parses a full, well-formed payload', () {
      final config = OidcOpenIdConfig.fromJson({
        'authorizationEndpoint': 'https://example.com/authorize',
        'tokenEndpoint': 'https://example.com/token',
        'userinfoEndpoint': 'https://example.com/userinfo',
        'endSessionEndpoint': 'https://example.com/endSession',
      });

      expect(config.authorizationEndpoint, 'https://example.com/authorize');
      expect(config.endSessionEndpoint, 'https://example.com/endSession');
    });

    test('throws FormatException when authorizationEndpoint is missing', () {
      expect(
        () => OidcOpenIdConfig.fromJson({
          'tokenEndpoint': 'https://example.com/token',
          'userinfoEndpoint': 'https://example.com/userinfo',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when an optional endpoint has the wrong type', () {
      expect(
        () => OidcOpenIdConfig.fromJson({
          'authorizationEndpoint': 'https://example.com/authorize',
          'tokenEndpoint': 'https://example.com/token',
          'userinfoEndpoint': 'https://example.com/userinfo',
          'revocationEndpoint': 42,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('OidcOpenIdConfig.toJson', () {
    test('round-trips through fromJson', () {
      const original = OidcOpenIdConfig(
        authorizationEndpoint: 'https://example.com/authorize',
        tokenEndpoint: 'https://example.com/token',
        userinfoEndpoint: 'https://example.com/userinfo',
        endSessionEndpoint: 'https://example.com/endSession',
        pingEndIdpSessionEndpoint: 'https://example.com/pingEndSession',
        revocationEndpoint: 'https://example.com/revoke',
      );

      final roundTripped = OidcOpenIdConfig.fromJson(original.toJson());

      expect(roundTripped.authorizationEndpoint, original.authorizationEndpoint);
      expect(roundTripped.tokenEndpoint, original.tokenEndpoint);
      expect(roundTripped.userinfoEndpoint, original.userinfoEndpoint);
      expect(roundTripped.endSessionEndpoint, original.endSessionEndpoint);
      expect(
        roundTripped.pingEndIdpSessionEndpoint,
        original.pingEndIdpSessionEndpoint,
      );
      expect(roundTripped.revocationEndpoint, original.revocationEndpoint);
    });

    test('omits optional endpoints when null', () {
      const config = OidcOpenIdConfig(
        authorizationEndpoint: 'https://example.com/authorize',
        tokenEndpoint: 'https://example.com/token',
        userinfoEndpoint: 'https://example.com/userinfo',
      );

      final json = config.toJson();
      expect(json.containsKey('endSessionEndpoint'), isFalse);
      expect(json.containsKey('pingEndIdpSessionEndpoint'), isFalse);
      expect(json.containsKey('revocationEndpoint'), isFalse);
    });
  });
}
