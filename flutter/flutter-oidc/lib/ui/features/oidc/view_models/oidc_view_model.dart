/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/foundation.dart';
import 'package:ping_oidc/ping_oidc.dart';

import 'package:flutter_oidc/data/oidc_repository.dart';

/// Drives the whole OIDC flow: browser [authorize], and the post-login [refresh]/
/// [loadUserInfo]/[revoke]/[signOff] surface. Single state holder for both the login and
/// success screens, mirroring `ping_journey`'s one-`ChangeNotifier`-per-flow convention.
class OidcViewModel extends ChangeNotifier {
  OidcViewModel({required this._repository});

  final OidcRepository _repository;

  OidcToken? _token;
  OidcUserInfo? _userInfo;
  bool _loading = false;
  String? _error;

  /// The most recently fetched token, or `null` before a successful login.
  OidcToken? get token => _token;

  /// The most recently fetched userinfo claims, or `null` if never loaded.
  OidcUserInfo? get userInfo => _userInfo;

  /// Whether an async call is in flight.
  bool get loading => _loading;

  /// The message from the most recent failed call, or `null`.
  String? get error => _error;

  /// Whether [authorize] has completed successfully and [signOff] hasn't run since.
  bool get isAuthenticated => _token != null;

  /// Configures a fresh native client, opens the system browser for the user to authenticate,
  /// and fetches the resulting token. Returns `true` on success, `false` if the user cancelled
  /// the browser (not an error) or a [PingException] was thrown.
  Future<bool> authorize() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.configure();
      final result = await _repository.authorize();
      switch (result) {
        case AuthorizeSuccess():
          _token = await _repository.token();
          return true;
        case AuthorizeCancel():
          return false;
      }
    } on PingException catch (error) {
      _error = error.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Forces a token refresh via the stored refresh token.
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _token = await _repository.refresh();
    } on PingException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetches the userinfo claims for the signed-in user.
  Future<void> loadUserInfo() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _userInfo = await _repository.userInfo();
    } on PingException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Revokes the current token. Leaves [token] as-is — native swallows revocation failures
  /// internally, so a completed call here isn't proof the server-side token was invalidated.
  Future<void> revoke() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.revoke();
    } on PingException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Signs the user out and clears local state. Returns `true` unless resolving the session
  /// itself failed — see [OidcRepository.signOff] for why this isn't proof a session existed.
  Future<bool> signOff() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await _repository.signOff();
      if (success) {
        _token = null;
        _userInfo = null;
      }
      return success;
    } on PingException catch (error) {
      _error = error.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
