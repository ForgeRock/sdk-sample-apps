/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// The open branch of [Callback], for callbacks an add-on package contributes (device profile,
/// device binding, FIDO, ...). Subclass it in the add-on package and register the subclass with
/// [Callback.registerAddOn] under the callback's server `"type"` string.
///
/// A `switch` over [Callback] handles every add-on with one `AddOnCallback()` case, then narrows
/// by subtype.
///
/// An add-on callback submits nothing from Dart: [toValue] stays `null`. The add-on sets its value
/// natively instead, inside the Journey's active-node `withItem` block, on the live native
/// callback (device profile's `collect()` stores the profile through the native callback's
/// `input(...)`). `JourneyClient.next` then just advances the flow and the native SDK submits that
/// value. Override [toValue] only if an add-on has to send a value from Dart.
abstract base class AddOnCallback extends Callback {
  /// Creates an add-on callback from its wire [message] and the [journeyId] of the node it
  /// belongs to — the id an add-on passes back to native to reach this same live callback.
  AddOnCallback(CallbackMessage message, this.journeyId)
    : raw = Map<String, Object?>.unmodifiable(
        JsonCodec.decodeObject(message.raw ?? const <String?, Object?>{}),
      ),
      super(type: message.type, index: message.index, prompt: message.prompt);

  /// The native `Journey` handle this callback belongs to, as passed to `JourneyClient`. Add-on
  /// APIs use it to address this live callback on a follow-up native call (device profile's
  /// `collect`, device binding, FIDO).
  final String journeyId;

  /// The native callback's full JSON as sent by the server, with nested maps and lists normalized
  /// to plain `Map<String, Object?>` / `List<Object?>`. This is where an add-on reads the fields
  /// the core mapper doesn't know about.
  final Map<String, Object?> raw;

  /// `null`: an add-on sets its value natively inside `withItem` (see [AddOnCallback]), so there is
  /// nothing for `JourneyClient.next` to send from Dart.
  @override
  CallbackValueMessage? toValue() => null;
}
