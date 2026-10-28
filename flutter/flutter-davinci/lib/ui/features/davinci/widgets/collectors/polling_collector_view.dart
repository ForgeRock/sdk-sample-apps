/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

/// A pause while the user acts somewhere else (`POLLING`): approving a push, opening a magic
/// link, scanning the QR code beside it.
///
/// Polls as soon as it is shown, and calls [onDone] once the poll ends, whatever the outcome:
/// the native collector keeps that outcome (`approved`, `continue`, `timedOut`, …) and the
/// server decides what comes next. Leaving the form (another button, or a new node) cancels the
/// poll with the subscription.
class PollingCollectorView extends StatefulWidget {
  const PollingCollectorView({
    super.key,
    required this.collector,
    required this.poll,
    required this.onDone,
  });

  final PollingCollector collector;
  final Stream<PollingStatus> Function(PollingCollector collector) poll;
  final VoidCallback onDone;

  @override
  State<PollingCollectorView> createState() => _PollingCollectorViewState();
}

class _PollingCollectorViewState extends State<PollingCollectorView> {
  StreamSubscription<PollingStatus>? _subscription;
  PollingStatus? _status;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _subscription = widget.poll(widget.collector).listen((status) {
      setState(() => _status = status);
      if (status.isTerminal) widget.onDone();
    }, onError: (Object error) => setState(() => _error = error));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_error case final error?) {
      return Text(
        'Polling could not start: $error',
        style: TextStyle(color: scheme.error),
      );
    }
    final text = switch (_status) {
      PollingContinue(:final retryCount, :final maxRetries) =>
        'Still waiting… (attempt $retryCount of $maxRetries)',
      PollingComplete(:final status) => 'Done ($status). Continuing…',
      PollingTimedOut() => 'Timed out. Continuing…',
      PollingExpired() => 'Expired. Continuing…',
      PollingError(:final message) => 'Polling failed: $message',
      null => 'Waiting…',
    };
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
