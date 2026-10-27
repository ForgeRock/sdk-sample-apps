/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/foundation.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/data/davinci_repository.dart';

/// Drives a single DaVinci run: the current [node], [loading] state, a top-level [error], and
/// the server [fieldErrors] no field of the form can show. Node-type dispatch happens in the
/// View, collector dispatch in `CollectorForm`.
///
/// A recoverable [ErrorNode] never becomes [node]: its [ErrorNode.continueNode] does, so the
/// form re-renders with the server's message in [error] and each field's message on its
/// collector ([FieldCollector.serverError]).
class DaVinciViewModel extends ChangeNotifier {
  DaVinciViewModel({required this._repository});

  final DaVinciRepository _repository;

  DaVinciNode? _node;
  bool _loading = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  DaVinciNode? get node => _node;
  bool get loading => _loading;
  String? get error => _error;

  /// The [ErrorNode.fieldErrors] whose key matches no collector of the form being retried, so
  /// the View shows them with [error] rather than dropping them.
  Map<String, String> get fieldErrors => _fieldErrors;

  Future<void> start(String acrValues) {
    _node = null;
    return _run(() => _repository.start(acrValues));
  }

  /// Submits the current form, pressing [button] when the user pressed one.
  ///
  /// Runs local validation first, unless [validate] is `false` or [button] is a
  /// [FlowCollector] (which leaves the form, e.g. "Forgot password", so its fields don't
  /// matter). When validation finds errors nothing is sent: each field shows its own.
  Future<void> submit({ButtonCollector? button, bool validate = true}) async {
    final current = _node;
    if (current is! ContinueNode || _loading) return;
    if (button != null) {
      // A button pressed earlier, on a submit that validation blocked, would still be selected.
      for (final other in current.collectors.whereType<ButtonCollector>()) {
        if (!identical(other, button) && other.value.isNotEmpty) {
          other.value = '';
        }
      }
      button.select();
    }
    if (validate && button is! FlowCollector && !await validateLocally()) {
      return;
    }
    await _run(() => _repository.next(current));
  }

  /// Runs the native SDK's local validation over the current form, without a network call, and
  /// attaches the errors to its collectors. Returns whether the form is valid.
  Future<bool> validateLocally() async {
    final current = _node;
    if (current is! ContinueNode) return false;
    try {
      final errors = await _repository.validate(current);
      _error = errors.isEmpty ? null : 'Please correct the fields below.';
      _fieldErrors = const {};
      return errors.isEmpty;
    } on PingException catch (error) {
      // toString() (not error.message) so the on-screen banner also shows code/type.
      _error = error.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Polls [collector], a collector of the current form. See `DaVinciClient.poll`.
  Stream<PollingStatus> poll(PollingCollector collector) =>
      _repository.poll(collector);

  Future<bool> signOff() async {
    try {
      final success = await _repository.signOff();
      _node = null;
      _error = null;
      _fieldErrors = const {};
      notifyListeners();
      return success;
    } on PingException catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  /// Notifies listeners without advancing [node]: a collector widget changed its collector's
  /// value and the view needs to rebuild.
  void refresh() => notifyListeners();

  Future<void> _run(Future<DaVinciNode> Function() action) async {
    _loading = true;
    _error = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      final node = await action();
      if (node case ErrorNode(:final continueNode?)) {
        final keys = continueNode.collectors.map((c) => c.key).toSet();
        _node = continueNode;
        _error = node.message;
        _fieldErrors = {
          for (final MapEntry(:key, :value) in node.fieldErrors.entries)
            if (!keys.contains(key)) key: value,
        };
      } else {
        _node = node;
      }
    } on PingException catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
