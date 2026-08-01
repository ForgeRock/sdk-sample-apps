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

  /// Wire type for the registration-flow variant of [validatedUsernameCallback] — the native
  /// SDKs' `AbstractCallback.json["type"]` is the AM server's own callback class name
  /// (`ValidatedCreateUsernameCallback`), not the SDK's local `ValidatedUsernameCallback` class
  /// name, even though both re-inflate to the same native `ValidatedUsernameCallback` type.
  static const validatedCreateUsernameCallback = 'ValidatedCreateUsernameCallback';

  /// Wire type for the registration-flow variant of [validatedPasswordCallback] — see
  /// [validatedCreateUsernameCallback].
  static const validatedCreatePasswordCallback = 'ValidatedCreatePasswordCallback';

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
