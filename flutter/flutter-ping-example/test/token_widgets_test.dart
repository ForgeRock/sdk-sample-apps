/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_example/core/util/jwt.dart';
import 'package:ping_example/core/widgets/token_widgets.dart';

String _jwt(Map<String, Object?> claims) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part(claims)}.signature';
}

int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  group('decodeJwtClaims', () {
    test('decodes an unpadded payload', () {
      final claims = decodeJwtClaims(_jwt({'sub': 'user-1', 'n': 2}));
      expect(claims, {'sub': 'user-1', 'n': 2});
    });

    test('returns null for an opaque token', () {
      expect(decodeJwtClaims('opaque-access-token'), isNull);
    });

    test('returns null when the payload is not base64 or not a JSON object', () {
      expect(decodeJwtClaims('a.!!!.c'), isNull);
      expect(decodeJwtClaims('a.${base64Url.encode(utf8.encode('[1]'))}.c'), isNull);
      expect(decodeJwtClaims('a.${base64Url.encode(utf8.encode('nope'))}.c'), isNull);
    });
  });

  group('ExpiryRow', () {
    testWidgets('counts down to the JWT exp claim', (tester) async {
      final token = _jwt({'exp': _nowSeconds() + 5400});
      await _pump(tester, ExpiryRow(accessToken: token, expiresIn: 5400));

      expect(find.textContaining('1h 29m'), findsOneWidget);
      expect(find.textContaining("from the token's exp claim"), findsOneWidget);
    });

    testWidgets('reports an expired JWT', (tester) async {
      final token = _jwt({'exp': _nowSeconds() - 120});
      await _pump(tester, ExpiryRow(accessToken: token, expiresIn: 3600));

      expect(find.textContaining('Expired'), findsOneWidget);
    });

    testWidgets('estimates from first sight for an opaque token', (tester) async {
      await _pump(
        tester,
        const ExpiryRow(accessToken: 'opaque-token-a', expiresIn: 3600),
      );

      expect(find.textContaining('59m'), findsOneWidget);
      expect(find.textContaining('estimated'), findsOneWidget);
    });
  });

  group('IdTokenClaimsCard', () {
    testWidgets('lists claims and formats time claims', (tester) async {
      final token = _jwt({'sub': 'user-1', 'exp': 1700000000});
      await _pump(tester, IdTokenClaimsCard(idToken: token));

      expect(find.text('ID Token Claims (not verified)'), findsOneWidget);
      expect(find.text('sub'), findsOneWidget);
      expect(find.text('user-1'), findsOneWidget);
      expect(find.textContaining('(1700000000)'), findsOneWidget);
    });

    testWidgets('shows nothing for a token that is not a JWT', (tester) async {
      await _pump(tester, const IdTokenClaimsCard(idToken: 'not-a-jwt'));

      expect(find.text('ID Token Claims (not verified)'), findsNothing);
    });
  });
}
