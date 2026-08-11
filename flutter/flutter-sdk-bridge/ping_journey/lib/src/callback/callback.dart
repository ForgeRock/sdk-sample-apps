/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import '../messages.g.dart';

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
