/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/foundation.dart';
import 'package:ping_journey/ping_journey.dart';

import 'package:flutter_journey/data/journey_repository.dart';

/// Drives a single Journey run: current [node], [loading] state, and any top-level [error].
/// Analog of the native samples' `JourneyViewModel` (Kotlin `JourneyViewModel.kt` /
/// SwiftUI `JourneyViewModel.swift`) — dumb state holder; node-type dispatch happens in the View.
class JourneyViewModel extends ChangeNotifier {
  JourneyViewModel({required this._repository});

  final JourneyRepository _repository;

  JourneyNode? _node;
  bool _loading = false;
  String? _error;

  JourneyNode? get node => _node;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> startJourney(String name) =>
      _run(() => _repository.startJourney(name));

  Future<void> next() {
    final current = _node;
    if (current is! ContinueNode) return Future.value();
    return _run(() => _repository.next(current));
  }

  Future<bool> signOff() async {
    try {
      return await _repository.signOff();
    } on PingException catch (error) {
      _error = error.message;
      notifyListeners();
      return false;
    }
  }

  /// Notifies listeners without advancing [node] — a callback widget mutated its own field
  /// (e.g. a text field keystroke) and the view needs to rebuild, mirroring the native samples'
  /// `onNodeUpdated()`/`refresh()` convention.
  void refresh() => notifyListeners();

  Future<void> _run(Future<JourneyNode> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _node = await action();
    } on PingException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
