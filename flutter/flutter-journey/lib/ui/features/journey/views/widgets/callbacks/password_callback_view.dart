/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_journey/ping_journey.dart';

import 'package:flutter_journey/ui/features/journey/views/widgets/callbacks/callback_controllers_state.dart';

class PasswordCallbackView extends StatefulWidget {
  const PasswordCallbackView({
    super.key,
    required this.callback,
    required this.onChanged,
  });

  final PasswordCallback callback;
  final VoidCallback onChanged;

  @override
  State<PasswordCallbackView> createState() => _PasswordCallbackViewState();
}

class _PasswordCallbackViewState extends State<PasswordCallbackView>
    with CallbackControllersState<PasswordCallbackView> {
  late final _controller = TextEditingController(
    text: widget.callback.password,
  );
  bool _obscure = true;

  @override
  List<TextEditingController> get controllers => [_controller];

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.callback.prompt ?? 'Password',
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      onChanged: (value) {
        widget.callback.password = value;
        widget.onChanged();
      },
    );
  }
}
