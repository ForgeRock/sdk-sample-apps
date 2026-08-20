/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:ping_core/ping_core.dart';

void main() {
  group('OidcConfig construction', () {
    test('exposes all fields when fully constructed, incl. nested openId', () {
      const config = OidcConfig(
        clientId: 'client-1',
        discoveryEndpoint: 'https://example.com/.well-known/openid-configuration',
        openId: OidcOpenIdConfig(
          authorizationEndpoint: 'https://example.com/authorize',
          tokenEndpoint: 'https://example.com/token',
          userinfoEndpoint: 'https://example.com/userinfo',
        ),
        redirectUri: 'com.example.app://callback',
        scopes: ['openid', 'profile'],
        acrValues: 'acr1',
        signOutRedirectUri: 'com.example.app://signout',
        state: 'state-1',
        nonce: 'nonce-1',
        uiLocales: 'en',
        refreshThreshold: 30,
        loginHint: 'user@example.com',
        display: 'page',
        prompt: 'login',
        additionalParameters: {'foo': 'bar'},
        par: true,
      );

      expect(config.clientId, 'client-1');
      expect(
        config.discoveryEndpoint,
        'https://example.com/.well-known/openid-configuration',
      );
      expect(config.openId?.authorizationEndpoint, 'https://example.com/authorize');
      expect(config.redirectUri, 'com.example.app://callback');
      expect(config.scopes, ['openid', 'profile']);
      expect(config.acrValues, 'acr1');
      expect(config.signOutRedirectUri, 'com.example.app://signout');
      expect(config.state, 'state-1');
      expect(config.nonce, 'nonce-1');
      expect(config.uiLocales, 'en');
      expect(config.refreshThreshold, 30);
      expect(config.loginHint, 'user@example.com');
      expect(config.display, 'page');
      expect(config.prompt, 'login');
      expect(config.additionalParameters, {'foo': 'bar'});
      expect(config.par, isTrue);
    });

    test('defaults scopes, additionalParameters, and par when only clientId is given', () {
      const config = OidcConfig(clientId: 'client-1');

      expect(config.scopes, isEmpty);
      expect(config.additionalParameters, isEmpty);
      expect(config.par, isFalse);
      expect(config.discoveryEndpoint, isNull);
      expect(config.openId, isNull);
    });
  });

  group('OidcConfig.fromJson', () {
    test('parses a full, well-formed payload', () {
      final config = OidcConfig.fromJson({
        'clientId': 'client-1',
        'openId': {
          'authorizationEndpoint': 'https://example.com/authorize',
          'tokenEndpoint': 'https://example.com/token',
          'userinfoEndpoint': 'https://example.com/userinfo',
        },
        'scopes': ['openid', 'profile'],
        'refreshThreshold': 30,
        'additionalParameters': {'foo': 'bar'},
        'par': true,
      });

      expect(config.clientId, 'client-1');
      expect(config.openId?.authorizationEndpoint, 'https://example.com/authorize');
      expect(config.scopes, ['openid', 'profile']);
      expect(config.refreshThreshold, 30);
      expect(config.additionalParameters, {'foo': 'bar'});
      expect(config.par, isTrue);
    });

    test('throws FormatException when clientId is missing', () {
      expect(
        () => OidcConfig.fromJson({'discoveryEndpoint': 'https://example.com'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when clientId is empty', () {
      expect(
        () => OidcConfig.fromJson({'clientId': ''}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when refreshThreshold has the wrong type', () {
      expect(
        () => OidcConfig.fromJson({
          'clientId': 'client-1',
          'refreshThreshold': '30',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when par has the wrong type', () {
      expect(
        () => OidcConfig.fromJson({'clientId': 'client-1', 'par': 'true'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('OidcConfig.toJson', () {
    test('round-trips through fromJson', () {
      const original = OidcConfig(
        clientId: 'client-1',
        openId: OidcOpenIdConfig(
          authorizationEndpoint: 'https://example.com/authorize',
          tokenEndpoint: 'https://example.com/token',
          userinfoEndpoint: 'https://example.com/userinfo',
        ),
        scopes: ['openid', 'profile'],
        refreshThreshold: 30,
        additionalParameters: {'foo': 'bar'},
        par: true,
      );

      final roundTripped = OidcConfig.fromJson(original.toJson());

      expect(roundTripped.clientId, original.clientId);
      expect(
        roundTripped.openId?.authorizationEndpoint,
        original.openId?.authorizationEndpoint,
      );
      expect(roundTripped.scopes, original.scopes);
      expect(roundTripped.refreshThreshold, original.refreshThreshold);
      expect(roundTripped.additionalParameters, original.additionalParameters);
      expect(roundTripped.par, original.par);
    });

    test('omits optional fields when null', () {
      const config = OidcConfig(clientId: 'client-1');

      final json = config.toJson();
      expect(json.containsKey('discoveryEndpoint'), isFalse);
      expect(json.containsKey('openId'), isFalse);
      expect(json.containsKey('redirectUri'), isFalse);
      expect(json.containsKey('refreshThreshold'), isFalse);
    });
  });
}
