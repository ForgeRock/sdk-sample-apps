/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'callback_type.dart';

/// How a callback's value should be rendered/collected.
enum FieldKind {
  /// A free-form text field.
  text,

  /// A masked password field.
  password,

  /// A numeric input field.
  number,

  /// A boolean (toggle/checkbox) field.
  boolean,

  /// A selection from a fixed list of options.
  choice,

  /// A knowledge-based-authentication question/answer pair.
  kba,

  /// A display-only message with no user-editable value.
  output,

  /// A callback type this bridge doesn't classify.
  unknown,
}

/// Whether a callback can be submitted directly, needs no input, or needs handling this bridge
/// doesn't support yet. Trimmed to the v1 callback set (no `autoCapable`/`integrationRequired`
/// callback types are in scope for v1, but the values are kept so future callback types can be
/// classified without changing this enum).
enum ExecutionMode {
  /// The callback requires user-provided input before it can be submitted.
  manual,

  /// The callback can be resolved automatically without user input (not used in v1).
  autoCapable,

  /// The callback requires integration with an external SDK/flow (not used in v1).
  integrationRequired,

  /// The callback only displays information and contributes no value.
  outputOnly,

  /// The callback type isn't handled by this bridge.
  unsupported,
}

/// Pure classification logic for the v1 ~10 callback types, keyed by their native class-name
/// wire `type` string (e.g. `"NameCallback"`).
class CallbackHelpers {
  const CallbackHelpers._();

  static const _outputOnlyTypes = {
    CallbackType.textOutputCallback,
    CallbackType.suspendedTextOutputCallback,
  };

  static const _passwordTypes = {
    CallbackType.passwordCallback,
    CallbackType.validatedPasswordCallback,
  };

  static const _booleanTypes = {
    CallbackType.booleanAttributeInputCallback,
    CallbackType.termsAndConditionsCallback,
  };

  static const _numberTypes = {CallbackType.numberAttributeInputCallback};

  static const _choiceTypes = {CallbackType.choiceCallback};

  static const _kbaTypes = {CallbackType.kbaCreateCallback};

  static const _textTypes = {
    CallbackType.nameCallback,
    CallbackType.textInputCallback,
    CallbackType.stringAttributeInputCallback,
    CallbackType.validatedUsernameCallback,
  };

  static const _manualTypes = {
    CallbackType.nameCallback,
    CallbackType.passwordCallback,
    CallbackType.textInputCallback,
    CallbackType.stringAttributeInputCallback,
    CallbackType.numberAttributeInputCallback,
    CallbackType.booleanAttributeInputCallback,
    CallbackType.choiceCallback,
    CallbackType.kbaCreateCallback,
    CallbackType.termsAndConditionsCallback,
    CallbackType.validatedUsernameCallback,
    CallbackType.validatedPasswordCallback,
  };

  /// Priority-cascade classification — order matters in case future callback types are added to
  /// more than one set.
  static FieldKind resolveFieldKind(String type) {
    if (_outputOnlyTypes.contains(type)) return FieldKind.output;
    if (_passwordTypes.contains(type)) return FieldKind.password;
    if (_booleanTypes.contains(type)) return FieldKind.boolean;
    if (_numberTypes.contains(type)) return FieldKind.number;
    if (_choiceTypes.contains(type)) return FieldKind.choice;
    if (_kbaTypes.contains(type)) return FieldKind.kba;
    if (_textTypes.contains(type)) return FieldKind.text;
    return FieldKind.unknown;
  }

  /// Determines how the callback identified by [type] should be handled — submitted directly,
  /// requiring no input, or unsupported by this bridge.
  static ExecutionMode resolveExecutionMode(String type) {
    if (_outputOnlyTypes.contains(type)) return ExecutionMode.outputOnly;
    if (_manualTypes.contains(type)) return ExecutionMode.manual;
    return ExecutionMode.unsupported;
  }
}
