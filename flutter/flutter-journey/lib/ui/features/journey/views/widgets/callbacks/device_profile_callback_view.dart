/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ping_device_profile/ping_device_profile.dart';

/// Renders a [DeviceProfileCallback] as an automatic "Gathering device profile…" step.
///
/// There is nothing for the user to fill in: when the view appears it runs [collect] — the
/// journey view model's collect-and-advance action — once, shows a progress indicator while it
/// runs, and shows the callback's server `message` while waiting. Collecting through the view
/// model (rather than inside the widget) keeps [PingException] flowing through the same
/// `_run`/error-banner path every other callback's submit takes.
///
/// Analog of the native samples' `DeviceProfileCallback` composable/view (Kotlin
/// `DeviceProfileCallback.kt`, SwiftUI `DeviceProfileCallbackView.swift`), which also collect on
/// appearance and advance when done.
class DeviceProfileCallbackView extends StatefulWidget {
  /// Creates a device profile view for [callback].
  const DeviceProfileCallbackView({
    super.key,
    required this.callback,
    required this.collect,
  });

  /// The callback whose `message` may be displayed while collecting.
  final DeviceProfileCallback callback;

  /// Runs the native collection and advances the journey. Called once when the view appears.
  final Future<void> Function() collect;

  @override
  State<DeviceProfileCallbackView> createState() => _DeviceProfileCallbackViewState();
}

class _DeviceProfileCallbackViewState extends State<DeviceProfileCallbackView> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: the collection's progress is this view's spinner, and its outcome (success
    // advances the journey; a PingException lands in the view model's error banner) is rendered
    // elsewhere, so the future itself needs no await here.
    unawaited(widget.collect());
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.callback.message.isEmpty
        ? 'Gathering device profile...'
        : widget.callback.message;
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
