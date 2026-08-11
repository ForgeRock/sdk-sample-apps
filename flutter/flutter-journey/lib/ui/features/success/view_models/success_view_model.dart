/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/foundation.dart';
import 'package:ping_journey/ping_journey.dart';

import 'package:flutter_journey/data/journey_repository.dart';

/// Holds the session state shown on the success screen.
class SuccessViewModel extends ChangeNotifier {
  SuccessViewModel({required this._repository});

  final JourneyRepository _repository;

  Session? _session;
  bool _loading = false;
  String? _error;

  Session? get session => _session;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadSession() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _session = await _repository.user();
    } on PingException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
