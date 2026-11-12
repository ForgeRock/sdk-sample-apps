/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';

/// Disposes [controllers] automatically, removing the repeated
/// `TextEditingController` + `dispose()` boilerplate shared by the callback views.
mixin CallbackControllersState<T extends StatefulWidget> on State<T> {
  /// The [TextEditingController]s this view owns; disposed automatically in [dispose].
  List<TextEditingController> get controllers;

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
