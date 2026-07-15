/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'callback.dart';

/// Collects a knowledge-based-authentication question and answer (self-registration).
final class KbaCreateCallback extends Callback {
  /// Creates a KBA (knowledge-based-authentication) create callback from its
  /// wire-message fields.
  KbaCreateCallback({
    required super.type,
    required super.index,
    super.prompt,
    this.predefinedQuestions = const [],
    this.selectedQuestion = '',
    this.selectedAnswer = '',
    this.allowUserDefinedQuestions = false,
  });

  /// The server-supplied list of security questions the user may pick from.
  final List<String> predefinedQuestions;

  /// The security question chosen (or typed) by the user.
  String selectedQuestion;

  /// The user's answer to [selectedQuestion].
  String selectedAnswer;

  /// Whether the user may type their own question instead of picking one
  /// from [predefinedQuestions].
  bool allowUserDefinedQuestions;

  /// Submitted as an object value
  /// (`{selectedQuestion, selectedAnswer, allowUserDefinedQuestions}`), the one v1 callback
  /// whose value isn't a scalar.
  @override
  CallbackValueMessage toValue() => CallbackValueMessage(
    type: type,
    index: index,
    value: {
      'selectedQuestion': selectedQuestion,
      'selectedAnswer': selectedAnswer,
      'allowUserDefinedQuestions': allowUserDefinedQuestions,
    },
  );
}
