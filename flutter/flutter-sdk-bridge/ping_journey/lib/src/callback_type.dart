/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Native callback class-name wire type strings (`CallbackMessage.type`), shared between
/// [NodeMapper] and [CallbackHelpers] so the two can't drift or typo independently.
abstract final class CallbackType {
  /// Wire type for `NameCallback`.
  static const nameCallback = 'NameCallback';

  /// Wire type for `PasswordCallback`.
  static const passwordCallback = 'PasswordCallback';

  /// Wire type for `ValidatedUsernameCallback`.
  static const validatedUsernameCallback = 'ValidatedUsernameCallback';

  /// Wire type for `ValidatedPasswordCallback`.
  static const validatedPasswordCallback = 'ValidatedPasswordCallback';

  /// Wire type for `ChoiceCallback`.
  static const choiceCallback = 'ChoiceCallback';

  /// Wire type for `KbaCreateCallback`.
  static const kbaCreateCallback = 'KbaCreateCallback';

  /// Wire type for `TermsAndConditionsCallback`.
  static const termsAndConditionsCallback = 'TermsAndConditionsCallback';

  /// Wire type for `TextInputCallback`.
  static const textInputCallback = 'TextInputCallback';

  /// Wire type for `TextOutputCallback`.
  static const textOutputCallback = 'TextOutputCallback';

  /// Wire type for `SuspendedTextOutputCallback`.
  static const suspendedTextOutputCallback = 'SuspendedTextOutputCallback';

  /// Wire type for `StringAttributeInputCallback`.
  static const stringAttributeInputCallback = 'StringAttributeInputCallback';

  /// Wire type for `NumberAttributeInputCallback`.
  static const numberAttributeInputCallback = 'NumberAttributeInputCallback';

  /// Wire type for `BooleanAttributeInputCallback`.
  static const booleanAttributeInputCallback = 'BooleanAttributeInputCallback';
}
