/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_journey/data/journey_repository.dart';
import 'package:flutter_journey/ui/features/success/view_models/success_view_model.dart';
import 'package:flutter_journey/ui/features/success/views/success_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';
import 'package:provider/provider.dart';

/// Stubs the network-bound [JourneyRepository] so [SuccessViewModel.loadSession] resolves to a
/// fixed [Session] (or throws a fixed [PingException]) instead of calling the real plugin.
///
/// [sessionFuture] is awaited directly (rather than returned from an `async` function that
/// itself introduces an implicit microtask hop) so tests can hold it pending via a [Completer]
/// to deterministically observe the view's loading state.
class _StubJourneyRepository extends JourneyRepository {
  _StubJourneyRepository({this.sessionFuture, this.error});

  final Future<Session?>? sessionFuture;
  final PingException? error;

  @override
  Future<Session?> user() {
    if (error != null) return Future.error(error!);
    return sessionFuture ?? Future.value(null);
  }
}

Future<SuccessViewModel> _pumpSuccessView(
  WidgetTester tester, {
  Future<Session?>? sessionFuture,
  PingException? error,
  VoidCallback onSignOff = _noop,
}) async {
  final viewModel = SuccessViewModel(
    repository: _StubJourneyRepository(sessionFuture: sessionFuture, error: error),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<SuccessViewModel>.value(
      value: viewModel,
      child: MaterialApp(home: SuccessView(onSignOff: onSignOff)),
    ),
  );
  return viewModel;
}

void _noop() {}

void main() {
  testWidgets('shows a loading indicator while the session is being fetched', (
    tester,
  ) async {
    final completer = Completer<Session?>();

    await _pumpSuccessView(tester, sessionFuture: completer.future);

    // One pump lets the post-frame callback invoke loadSession(), which sets loading = true
    // and calls notifyListeners() — but the stubbed Future is still pending, so the loading
    // state stays visible until we complete it below.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading session…'), findsOneWidget);

    completer.complete(const Session(accessToken: 'token', expiresIn: 3600));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an error banner and Sign Off button when loading fails', (
    tester,
  ) async {
    var signedOff = false;

    await _pumpSuccessView(
      tester,
      error: const PingException(
        'JOURNEY_USER_ERROR',
        'state',
        'Unable to load session',
      ),
      onSignOff: () => signedOff = true,
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load session'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign Off'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Off'));
    await tester.pump();

    expect(signedOff, isTrue);
  });

  testWidgets(
    'renders the access token, refresh token, expiry, and user info on success',
    (tester) async {
      await _pumpSuccessView(
        tester,
        sessionFuture: Future.value(
          const Session(
            accessToken: 'access-123',
            refreshToken: 'refresh-456',
            expiresIn: 3600,
            userInfo: {'sub': 'user-1', 'email': 'jdoe@example.com'},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Journey completed successfully.'), findsOneWidget);
      expect(find.text('Access Token'), findsOneWidget);
      expect(find.text('access-123'), findsOneWidget);
      expect(find.text('Refresh Token'), findsOneWidget);
      expect(find.text('refresh-456'), findsOneWidget);
      expect(find.text('Expires In'), findsOneWidget);
      expect(find.text('3600s'), findsOneWidget);
      expect(find.text('User Info'), findsOneWidget);
      expect(find.text('sub'), findsOneWidget);
      expect(find.text('user-1'), findsOneWidget);
      expect(find.text('email'), findsOneWidget);
      expect(find.text('jdoe@example.com'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign Off'), findsOneWidget);
    },
  );

  testWidgets('omits the Refresh Token and User Info sections when absent', (
    tester,
  ) async {
    await _pumpSuccessView(
      tester,
      sessionFuture: Future.value(
        const Session(accessToken: 'access-only', expiresIn: 60),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Access Token'), findsOneWidget);
    expect(find.text('Refresh Token'), findsNothing);
    expect(find.text('User Info'), findsNothing);
  });

  testWidgets('tapping the copy icon copies the token value to the clipboard', (
    tester,
  ) async {
    final copied = <ClipboardData>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = (call.arguments as Map)['text'] as String;
          copied.add(ClipboardData(text: args));
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await _pumpSuccessView(
      tester,
      sessionFuture: Future.value(
        const Session(accessToken: 'copy-me', expiresIn: 60),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.copy).first);
    await tester.pump();

    expect(copied, isNotEmpty);
    expect(copied.first.text, 'copy-me');
  });
}
