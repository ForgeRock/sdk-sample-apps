/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/foundation.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/data/davinci_repository.dart';

/// Holds what the success screen shows once a flow completes: the authorization code the flow
/// ended with ([session]), the OIDC tokens the native SDK exchanged it for ([token]), and the
/// userinfo claims ([userInfo]). They come from three separate calls, because a DaVinci session
/// carries a code, not tokens.
class SuccessViewModel extends ChangeNotifier {
  SuccessViewModel({required this._repository});

  final DaVinciRepository _repository;

  DaVinciSession? _session;
  DaVinciToken? _token;
  Map<String, Object?>? _userInfo;
  bool _loading = false;
  String? _error;

  DaVinciSession? get session => _session;
  DaVinciToken? get token => _token;
  Map<String, Object?>? get userInfo => _userInfo;
  bool get loading => _loading;
  String? get error => _error;

  /// Loads the code, then the tokens, then the claims. A failure stops there and is shown in
  /// [error]; what loaded before it stays on screen.
  Future<void> load() async {
    _session = null;
    _token = null;
    _userInfo = null;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _session = await _repository.session();
      _token = await _repository.token();
      _userInfo = await _repository.userInfo();
    } on PingException catch (e) {
      // toString() (not e.message) so the on-screen banner also shows code/type.
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Re-reads the tokens; the native SDK refreshes them if they have expired.
  Future<void> reloadToken() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _token = await _repository.token();
    } on PingException catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
