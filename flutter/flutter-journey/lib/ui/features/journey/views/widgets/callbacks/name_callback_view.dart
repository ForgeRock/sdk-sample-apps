/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_journey/ping_journey.dart';

import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/callback_controllers_state.dart';

class NameCallbackView extends StatefulWidget {
  const NameCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final NameCallback callback;
  final VoidCallback onChanged;

  @override
  State<NameCallbackView> createState() => _NameCallbackViewState();
}

class _NameCallbackViewState extends State<NameCallbackView>
    with CallbackControllersState<NameCallbackView> {
  late final _controller = TextEditingController(text: widget.callback.name);

  @override
  List<TextEditingController> get controllers => [_controller];

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.callback.prompt ?? 'Name',
      ),
      onChanged: (value) {
        widget.callback.name = value;
        widget.onChanged();
      },
    );
  }
}
