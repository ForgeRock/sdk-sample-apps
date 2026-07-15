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

class StringAttributeInputCallbackView extends StatefulWidget {
  const StringAttributeInputCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final StringAttributeInputCallback callback;
  final VoidCallback onChanged;

  @override
  State<StringAttributeInputCallbackView> createState() =>
      _StringAttributeInputCallbackViewState();
}

class _StringAttributeInputCallbackViewState
    extends State<StringAttributeInputCallbackView>
    with CallbackControllersState<StringAttributeInputCallbackView> {
  late final _controller = TextEditingController(text: widget.callback.value);

  @override
  List<TextEditingController> get controllers => [_controller];

  @override
  Widget build(BuildContext context) {
    final callback = widget.callback;
    final label = callback.prompt ?? callback.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: callback.required ? '$label *' : label,
            errorText: ValidationErrorText.errorTextFor(
              callback.failedPolicies,
            ),
          ),
          onChanged: (value) {
            callback.value = value;
            widget.onChanged();
          },
        ),
        ValidationErrorText(failedPolicies: callback.failedPolicies),
      ],
    );
  }
}
