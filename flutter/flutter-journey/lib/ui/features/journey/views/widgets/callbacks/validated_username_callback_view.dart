/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_journey/ping_journey.dart';

import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/callback_controllers_state.dart';
import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/validation_error_text.dart';

class ValidatedUsernameCallbackView extends StatefulWidget {
  const ValidatedUsernameCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final ValidatedUsernameCallback callback;
  final VoidCallback onChanged;

  @override
  State<ValidatedUsernameCallbackView> createState() =>
      _ValidatedUsernameCallbackViewState();
}

class _ValidatedUsernameCallbackViewState
    extends State<ValidatedUsernameCallbackView>
    with CallbackControllersState<ValidatedUsernameCallbackView> {
  late final _controller = TextEditingController(
    text: widget.callback.username,
  );

  @override
  List<TextEditingController> get controllers => [_controller];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.callback.prompt ?? 'Username',
            errorText: ValidationErrorText.errorTextFor(
              widget.callback.failedPolicies,
            ),
          ),
          onChanged: (value) {
            widget.callback.username = value;
            widget.onChanged();
          },
        ),
        ValidationErrorText(failedPolicies: widget.callback.failedPolicies),
      ],
    );
  }
}
