/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lastJourneyNameKey = 'lastJourneyName';

/// Persists the last-entered Journey name across launches — mirrors the native samples'
/// `PreferenceViewModel`/`UserDefaults` "journeyName" convention.
class JourneyNameViewModel extends ChangeNotifier {
  String _lastJourneyName = '';

  String get lastJourneyName => _lastJourneyName;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lastJourneyName = prefs.getString(_lastJourneyNameKey) ?? '';
    notifyListeners();
  }

  Future<void> save(String journeyName) async {
    _lastJourneyName = journeyName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastJourneyNameKey, journeyName);
  }
}
