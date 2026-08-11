/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'callback/callback.dart';
import 'callback_type.dart';
import 'journey_node.dart';
import 'messages.g.dart';

/// Re-inflates wire messages (Pigeon-generated) into the Dart sealed [JourneyNode]/[Callback]
/// hierarchies.
class NodeMapper {
  const NodeMapper._();

  /// Maps a [NodeMessage] to the matching [JourneyNode] subtype. [journeyId] is injected (it's
  /// not carried on the wire node itself) so [ContinueNode] can address a later `next()` call.
  static JourneyNode map(NodeMessage message, String journeyId) =>
      switch (message.type) {
        NodeType.continueNode => ContinueNode(
          journeyId: journeyId,
          header: message.header,
          description: message.pageDescription,
          stage: message.stage,
          callbacks:
              message.callbacks
                  ?.whereType<CallbackMessage>()
                  .map(mapCallback)
                  .toList() ??
              const [],
        ),
        NodeType.successNode => const SuccessNode(),
        NodeType.errorNode => ErrorNode(
          message: message.message ?? '',
          status: message.status,
        ),
        NodeType.failureNode => FailureNode(
          cause: message.cause ?? 'Unknown failure',
        ),
      };

  /// Maps a [CallbackMessage] to the matching [Callback] subtype, keyed by its native class-name
  /// [CallbackMessage.type]. Unrecognized types are not representable in the v1 sealed hierarchy,
  /// so the `_` case below renders them as a generic [TextOutputCallback] with a placeholder
  /// message instead of dropping them. [CallbackMessage.raw] (the native callback's full JSON) is
  /// still populated on the wire for these types, for debugging/diagnostic purposes.
  static Callback mapCallback(
    CallbackMessage message,
  ) => switch (message.type) {
    CallbackType.nameCallback => NameCallback(
      type: message.type,
      index: message.index,
      prompt: message.prompt,
      name: message.value as String? ?? '',
    ),
    CallbackType.passwordCallback => PasswordCallback(
      type: message.type,
      index: message.index,
      prompt: message.prompt,
    ),
    CallbackType.validatedUsernameCallback ||
    CallbackType.validatedCreateUsernameCallback => ValidatedUsernameCallback(
      type: message.type,
      index: message.index,
      prompt: message.prompt,
      username: message.value as String? ?? '',
      validateOnly: message.validateOnly ?? false,
      policies: message.policies?.cast<String, Object?>(),
      failedPolicies: _castFailedPolicies(message.failedPolicies),
    ),
    CallbackType.validatedPasswordCallback ||
    CallbackType.validatedCreatePasswordCallback => ValidatedPasswordCallback(
      type: message.type,
      index: message.index,
      prompt: message.prompt,
      echoOn: message.echoOn ?? false,
      validateOnly: message.validateOnly ?? false,
      policies: message.policies?.cast<String, Object?>(),
      failedPolicies: _castFailedPolicies(message.failedPolicies),
    ),
    CallbackType.choiceCallback => ChoiceCallback(
      type: message.type,
      index: message.index,
      prompt: message.prompt,
      choices: message.choices?.whereType<String>().toList() ?? const [],
      defaultChoice: message.defaultChoice ?? 0,
      selectedIndex: message.selectedIndex,
    ),
    CallbackType.kbaCreateCallback => KbaCreateCallback(
      type: message.type,
      index: message.index,
      prompt: message.prompt,
      predefinedQuestions:
          message.predefinedQuestions?.whereType<String>().toList() ?? const [],
      selectedQuestion: message.selectedQuestion ?? '',
      selectedAnswer: message.selectedAnswer ?? '',
      allowUserDefinedQuestions: message.allowUserDefinedQuestions ?? false,
    ),
    CallbackType.termsAndConditionsCallback => TermsAndConditionsCallback(
      type: message.type,
      index: message.index,
      version: message.version ?? '',
      terms: message.terms ?? '',
      createDate: message.createDate ?? '',
      accepted: message.accepted ?? false,
    ),
    CallbackType.textInputCallback => TextInputCallback(
      type: message.type,
      index: message.index,
      prompt: message.prompt,
      defaultText: message.defaultText ?? '',
      text: message.value as String?,
    ),
    CallbackType.textOutputCallback ||
    CallbackType.suspendedTextOutputCallback => TextOutputCallback(
      type: message.type,
      index: message.index,
      message: message.message ?? '',
      messageType: message.messageType,
    ),
    CallbackType.stringAttributeInputCallback => StringAttributeInputCallback(
      type: message.type,
      index: message.index,
      prompt: message.prompt,
      name: message.name ?? '',
      required: message.required ?? false,
      value: message.value as String? ?? '',
      validateOnly: message.validateOnly ?? false,
      policies: message.policies?.cast<String, Object?>(),
      failedPolicies: _castFailedPolicies(message.failedPolicies),
    ),
    CallbackType.numberAttributeInputCallback => NumberAttributeInputCallback(
      type: message.type,
      index: message.index,
      prompt: message.prompt,
      name: message.name ?? '',
      required: message.required ?? false,
      value: (message.value as num?)?.toDouble() ?? 0,
      validateOnly: message.validateOnly ?? false,
      policies: message.policies?.cast<String, Object?>(),
      failedPolicies: _castFailedPolicies(message.failedPolicies),
    ),
    CallbackType.booleanAttributeInputCallback =>
      BooleanAttributeInputCallback(
        type: message.type,
        index: message.index,
        prompt: message.prompt,
        name: message.name ?? '',
        required: message.required ?? false,
        value: message.value as bool? ?? false,
        validateOnly: message.validateOnly ?? false,
        policies: message.policies?.cast<String, Object?>(),
        failedPolicies: _castFailedPolicies(message.failedPolicies),
      ),
    _ => TextOutputCallback(
      type: message.type,
      index: message.index,
      message:
          message.message ??
          message.prompt ??
          'Unsupported callback: ${message.type}',
    ),
  };

  static List<Map<String, Object?>> _castFailedPolicies(
    List<Object?>? raw,
  ) =>
      raw
          ?.whereType<Map<Object?, Object?>>()
          .map((m) => m.cast<String, Object?>())
          .toList() ??
      const [];
}
