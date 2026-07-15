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

class ValidatedPasswordCallbackView extends StatefulWidget {
  const ValidatedPasswordCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final ValidatedPasswordCallback callback;
  final VoidCallback onChanged;

  @override
  State<ValidatedPasswordCallbackView> createState() =>
      _ValidatedPasswordCallbackViewState();
}

class _ValidatedPasswordCallbackViewState
    extends State<ValidatedPasswordCallbackView>
    with CallbackControllersState<ValidatedPasswordCallbackView> {
  late final _controller = TextEditingController(
    text: widget.callback.password,
  );
  bool _obscure = true;

  @override
  List<TextEditingController> get controllers => [_controller];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          obscureText: _obscure && widget.callback.echoOn == false,
          decoration: InputDecoration(
            labelText: widget.callback.prompt ?? 'Password',
            errorText: ValidationErrorText.errorTextFor(
              widget.callback.failedPolicies,
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onChanged: (value) {
            widget.callback.password = value;
            widget.onChanged();
          },
        ),
        ValidationErrorText(failedPolicies: widget.callback.failedPolicies),
      ],
    );
  }
}
