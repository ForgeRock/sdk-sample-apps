/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ping_example/features/davinci/config/davinci_env.dart';

const _lastAcrValuesKey = 'lastAcrValues';

/// Persists the last `acr_values` the user started a flow with, so switching between the
/// environment's flows doesn't mean editing [DaVinciEnv] and rebuilding. Starts at [DaVinciEnv.acrValues].
class FlowSettingsViewModel extends ChangeNotifier {
  String _acrValues = DaVinciEnv.acrValues;

  String get acrValues => _acrValues;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _acrValues = prefs.getString(_lastAcrValuesKey) ?? DaVinciEnv.acrValues;
    notifyListeners();
  }

  Future<void> save(String acrValues) async {
    _acrValues = acrValues;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAcrValuesKey, acrValues);
  }
}
