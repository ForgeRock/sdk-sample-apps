/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_journey/ping_journey.dart';

import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/callback_controllers_state.dart';

class TextInputCallbackView extends StatefulWidget {
  const TextInputCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final TextInputCallback callback;
  final VoidCallback onChanged;

  @override
  State<TextInputCallbackView> createState() => _TextInputCallbackViewState();
}

class _TextInputCallbackViewState extends State<TextInputCallbackView>
    with CallbackControllersState<TextInputCallbackView> {
  late final _controller = TextEditingController(text: widget.callback.text);

  @override
  List<TextEditingController> get controllers => [_controller];

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.callback.prompt ?? 'Text',
      ),
      onChanged: (value) {
        widget.callback.text = value;
        widget.onChanged();
      },
    );
  }
}
