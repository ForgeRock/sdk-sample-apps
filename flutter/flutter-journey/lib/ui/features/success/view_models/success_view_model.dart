/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/foundation.dart';
import 'package:ping_journey/ping_journey.dart';

import 'package:flutter_journey/data/journey_repository.dart';

/// Holds the session state shown on the success screen — mirroring
/// `flutter-oidc`'s [OidcViewModel]: the token set ([session]) and the userinfo
/// claims ([userInfo]) are separate pieces of state, because `refresh()`
/// deliberately returns no userinfo (so previously loaded claims survive a
/// refresh) and `revoke()` mutates nothing.
class SuccessViewModel extends ChangeNotifier {
  SuccessViewModel({required this._repository});

  final JourneyRepository _repository;

  Session? _session;
  Map<String, Object?>? _userInfo;
  bool _loading = false;
  String? _error;

  Session? get session => _session;

  /// The userinfo claims, tracked separately from [session] so a refresh
  /// (which returns no claims) doesn't blank the User Info card.
  Map<String, Object?>? get userInfo => _userInfo;

  /// The AM session token established by the Journey, if any — displayed even
  /// when [session] is null (a Journey without OIDC still has a session).
  String? get sessionToken => _repository.sessionToken;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadSession() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _session = await _repository.user();
      _userInfo = _session?.userInfo;
    } on PingException catch (e) {
      // toString() (not e.message) so the on-screen banner also shows code/type — the
      // developer-facing detail a sample app should surface, not just the bare message.
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Re-fetches the OIDC token set, replacing [session] only — claims in
  /// [userInfo] are deliberately left untouched.
  Future<void> refresh() => _run(() async {
    _session = await _repository.refresh();
  });

  /// Re-fetches the OIDC userinfo claims, replacing [userInfo] only.
  Future<void> loadUserInfo() => _run(() async {
    _userInfo = await _repository.userInfo();
  });

  /// Revokes the OIDC token. Mutates no state on success — the native call
  /// swallows server-side revocation errors, so token rows are left as-is.
  Future<void> revoke() => _run(() async {
    await _repository.revoke();
  });

  Future<void> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on PingException catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
