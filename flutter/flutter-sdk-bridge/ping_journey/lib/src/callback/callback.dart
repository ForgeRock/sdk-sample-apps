/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:ping_core/ping_core.dart';

import '../callback_type.dart';
import '../messages.g.dart';

part 'add_on_callback.dart';
part 'name_callback.dart';
part 'password_callback.dart';
part 'validated_username_callback.dart';
part 'validated_password_callback.dart';
part 'choice_callback.dart';
part 'kba_create_callback.dart';
part 'terms_and_conditions_callback.dart';
part 'text_input_callback.dart';
part 'text_output_callback.dart';
part 'string_attribute_input_callback.dart';
part 'number_attribute_input_callback.dart';
part 'boolean_attribute_input_callback.dart';

/// A single collectible/displayable item within a [ContinueNode]. Dart-side re-inflation of the
/// wire [CallbackMessage] — see `node_mapper.dart`. Declared as a multi-file `sealed` hierarchy
/// (via `part`) so `dart analyze` still enforces exhaustive `switch`es over subtypes across files.
sealed class Callback {
  const Callback({required this.type, required this.index, this.prompt});

  static final Map<String, AddOnCallback Function(CallbackMessage, String)>
  _addOns =
      <String, AddOnCallback Function(CallbackMessage, String)>{};

  /// Registers the Dart type for an add-on package's callback [type] — the server-registered
  /// `"type"` string that arrives as [CallbackMessage.type]. Called once by the add-on Dart
  /// package, before the first node containing that callback is mapped; a later registration for
  /// the same [type] replaces the earlier one.
  ///
  /// The factory receives the [journeyId] of the node being mapped, so the built callback can
  /// address its live native counterpart on a follow-up native call.
  ///
  /// Until it is registered, an unknown callback is rendered as a placeholder [TextOutputCallback].
  /// If [create] throws, the error propagates out of the mapping rather than being hidden behind
  /// the placeholder.
  ///
  /// Throws an [ArgumentError] for a [type] this package already maps.
  static void registerAddOn(
    String type,
    AddOnCallback Function(CallbackMessage message, String journeyId) create,
  ) {
    if (CallbackType.all.contains(type)) {
      throw ArgumentError.value(type, 'type', 'is a core callback type');
    }
    _addOns[type] = create;
  }

  /// The add-on callback registered for [message]'s type, or `null` if there is none. Used by
  /// `NodeMapper`; app code reads callbacks from a `ContinueNode` instead.
  static AddOnCallback? tryFromAddOn(CallbackMessage message, String journeyId) =>
      _addOns[message.type]?.call(message, journeyId);

  /// The native callback class name (e.g. `"NameCallback"`), matched by `node_mapper.dart` when
  /// re-inflating; not a Dart type discriminator by itself.
  final String type;

  /// 0-based position among callbacks of the same [type] in this node — used to address the
  /// value back to native via [CallbackValueMessage].
  final int index;

  /// The text to display to the user alongside this callback's input, if any.
  final String? prompt;

  /// The value to submit via `JourneyClient.next()`, or `null` if this callback contributes no
  /// value (output-only, e.g. [TextOutputCallback]).
  CallbackValueMessage? toValue();
}
