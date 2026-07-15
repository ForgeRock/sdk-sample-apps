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

class NumberAttributeInputCallbackView extends StatefulWidget {
  const NumberAttributeInputCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final NumberAttributeInputCallback callback;
  final VoidCallback onChanged;

  @override
  State<NumberAttributeInputCallbackView> createState() =>
      _NumberAttributeInputCallbackViewState();
}

class _NumberAttributeInputCallbackViewState
    extends State<NumberAttributeInputCallbackView>
    with CallbackControllersState<NumberAttributeInputCallbackView> {
  late final _controller = TextEditingController(
    text: widget.callback.value.toString(),
  );
  bool _hasParseError = false;

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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: callback.required ? '$label *' : label,
            errorText: ValidationErrorText.errorTextFor(
              callback.failedPolicies,
              hasLocalError: _hasParseError,
            ),
            helperText: _hasParseError ? 'Enter a valid number' : null,
          ),
          onChanged: (value) {
            final parsed = double.tryParse(value);
            setState(() => _hasParseError = value.isNotEmpty && parsed == null);
            if (parsed != null) callback.value = parsed;
            widget.onChanged();
          },
        ),
        ValidationErrorText(failedPolicies: callback.failedPolicies),
      ],
    );
  }
}
