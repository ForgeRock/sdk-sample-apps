/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'collector.dart';

/// A button that submits the form: [SubmitCollector] or [FlowCollector].
///
/// Call [select] on the one the user pressed, then `DaVinciClient.next`. Natively, a button with a
/// non-empty value becomes the submission's `actionKey`, and its class decides the `eventType`.
sealed class ButtonCollector extends FieldCollector<String> {
  ButtonCollector._(CollectorMessage message)
    : super._(message, message.value as String? ?? '');

  /// Marks this button as the one pressed: sets [value] to its [key].
  void select() => value = key;
}

/// A submit button (`SUBMIT_BUTTON`): submits the form with `eventType` `submit`.
final class SubmitCollector extends ButtonCollector {
  SubmitCollector._(super.message) : super._();
}

/// A flow button or link (`FLOW_BUTTON`, `FLOW_LINK`; native registry key `ACTION`): takes the
/// flow down another branch, e.g. "Forgot password", with `eventType` `action`.
final class FlowCollector extends ButtonCollector {
  FlowCollector._(super.message) : super._();
}
