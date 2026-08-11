/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_journey/ping_journey.dart';

import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/callback_controllers_state.dart';

const _customQuestion = '__custom__';

class KbaCreateCallbackView extends StatefulWidget {
  const KbaCreateCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final KbaCreateCallback callback;
  final VoidCallback onChanged;

  @override
  State<KbaCreateCallbackView> createState() => _KbaCreateCallbackViewState();
}

class _KbaCreateCallbackViewState extends State<KbaCreateCallbackView>
    with CallbackControllersState<KbaCreateCallbackView> {
  late final _answerController = TextEditingController(
    text: widget.callback.selectedAnswer,
  );
  late final _customQuestionController = TextEditingController(
    text:
        widget.callback.predefinedQuestions.contains(
          widget.callback.selectedQuestion,
        )
        ? ''
        : widget.callback.selectedQuestion,
  );

  bool get _isCustomQuestion =>
      widget.callback.allowUserDefinedQuestions &&
      !widget.callback.predefinedQuestions.contains(
        widget.callback.selectedQuestion,
      );

  @override
  List<TextEditingController> get controllers => [
    _answerController,
    _customQuestionController,
  ];

  @override
  Widget build(BuildContext context) {
    final callback = widget.callback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _isCustomQuestion
              ? _customQuestion
              : callback.selectedQuestion,
          decoration: InputDecoration(
            labelText: callback.prompt ?? 'Security Question',
          ),
          items: [
            for (final question in callback.predefinedQuestions)
              DropdownMenuItem(value: question, child: Text(question)),
            if (callback.allowUserDefinedQuestions)
              const DropdownMenuItem(
                value: _customQuestion,
                child: Text('Provide your own'),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              callback.selectedQuestion = value == _customQuestion ? '' : value;
            });
            widget.onChanged();
          },
        ),
        if (_isCustomQuestion) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _customQuestionController,
            decoration: const InputDecoration(
              labelText: 'Your Question',
            ),
            onChanged: (value) {
              callback.selectedQuestion = value;
              widget.onChanged();
            },
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: _answerController,
          decoration: const InputDecoration(
            labelText: 'Answer',
          ),
          onChanged: (value) {
            callback.selectedAnswer = value;
            widget.onChanged();
          },
        ),
      ],
    );
  }
}
