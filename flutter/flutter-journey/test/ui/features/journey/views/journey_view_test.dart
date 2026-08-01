/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_journey/data/journey_repository.dart';
import 'package:flutter_journey/ui/features/journey/view_models/journey_view_model.dart';
import 'package:flutter_journey/ui/features/journey/views/journey_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ping_journey/ping_journey.dart';
import 'package:provider/provider.dart';

/// Stubs the network-bound [JourneyRepository] so [JourneyViewModel.startJourney] resolves to a
/// fixed [JourneyNode] instead of calling the real plugin.
class _StubJourneyRepository extends JourneyRepository {
  _StubJourneyRepository(this.node, {this.nextError});

  final JourneyNode node;

  /// When set, [next] throws this instead of returning a node.
  final PingException? nextError;

  @override
  Future<JourneyNode> startJourney(String journeyName) async => node;

  @override
  Future<JourneyNode> next(ContinueNode node) async {
    final error = nextError;
    if (error != null) throw error;
    return node;
  }
}

NameCallback _nameCallback() =>
    NameCallback(type: 'NameCallback', index: 0, prompt: 'User Name');

PasswordCallback _passwordCallback() =>
    PasswordCallback(type: 'PasswordCallback', index: 0, prompt: 'Password');

Future<JourneyViewModel> _pumpJourneyView(
  WidgetTester tester,
  JourneyNode node, {
  VoidCallback onRestart = _noop,
  VoidCallback onSuccess = _noop,
  PingException? nextError,
}) async {
  final viewModel = JourneyViewModel(
    repository: _StubJourneyRepository(node, nextError: nextError),
  );
  await viewModel.startJourney('Login');

  await tester.pumpWidget(
    ChangeNotifierProvider<JourneyViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        home: JourneyView(onSuccess: onSuccess, onRestart: onRestart),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return viewModel;
}

void _noop() {}

void main() {
  testWidgets(
    'renders Name + Password fields and a Next button for a Name+Password ContinueNode',
    (tester) async {
      final node = ContinueNode(
        journeyId: 'journey-1',
        callbacks: [_nameCallback(), _passwordCallback()],
      );

      await _pumpJourneyView(tester, node);

      expect(find.widgetWithText(TextField, 'User Name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
    },
  );

  testWidgets(
    'next() throwing a PingException renders the error above the same ContinueNode form',
    (tester) async {
      final node = ContinueNode(
        journeyId: 'journey-1',
        callbacks: [_nameCallback(), _passwordCallback()],
      );

      await _pumpJourneyView(
        tester,
        node,
        nextError: const PingException(
          'JOURNEY_NEXT_ERROR',
          'network',
          'The request timed out.',
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('The request timed out.'), findsOneWidget);
      // The form itself is still rendered — the user isn't stuck on a blank screen.
      expect(find.widgetWithText(TextField, 'User Name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    },
  );

  testWidgets(
    'entering text updates the NameCallback and PasswordCallback values',
    (tester) async {
      final nameCallback = _nameCallback();
      final passwordCallback = _passwordCallback();
      final node = ContinueNode(
        journeyId: 'journey-1',
        callbacks: [nameCallback, passwordCallback],
      );

      await _pumpJourneyView(tester, node);

      await tester.enterText(
        find.widgetWithText(TextField, 'User Name'),
        'jdoe',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        's3cr3t',
      );
      await tester.pump();

      expect(nameCallback.name, 'jdoe');
      expect(passwordCallback.password, 's3cr3t');
    },
  );

  testWidgets(
    'an ErrorNode renders a Try Again button that invokes onRestart',
    (tester) async {
      var restarted = false;

      await _pumpJourneyView(
        tester,
        const ErrorNode(message: 'Invalid username or password'),
        onRestart: () => restarted = true,
      );

      expect(find.text('Invalid username or password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Try Again'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Try Again'));
      await tester.pump();

      expect(restarted, isTrue);
    },
  );

  testWidgets(
    'a FailureNode renders a Try Again button that invokes onRestart',
    (tester) async {
      var restarted = false;

      await _pumpJourneyView(
        tester,
        const FailureNode(cause: 'Network error'),
        onRestart: () => restarted = true,
      );

      expect(find.text('Network error'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Try Again'));
      await tester.pump();

      expect(restarted, isTrue);
    },
  );

  testWidgets(
    'onSuccess is invoked exactly once across multiple rebuilds while the node stays a '
    'SuccessNode',
    (tester) async {
      var successCount = 0;

      final viewModel = await _pumpJourneyView(
        tester,
        const SuccessNode(),
        onSuccess: () => successCount++,
      );

      expect(successCount, 1);

      // Force additional rebuilds while the node is still a SuccessNode — onSuccess must not
      // fire again.
      viewModel.refresh();
      await tester.pumpAndSettle();
      viewModel.refresh();
      await tester.pumpAndSettle();

      expect(successCount, 1);
    },
  );
}
