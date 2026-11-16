/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/collector_support.dart';

/// A `TEXT` field.
class TextCollectorView extends StatefulWidget {
  const TextCollectorView({
    super.key,
    required this.collector,
    required this.onChanged,
  });

  final TextCollector collector;
  final VoidCallback onChanged;

  @override
  State<TextCollectorView> createState() => _TextCollectorViewState();
}

class _TextCollectorViewState extends State<TextCollectorView>
    with ControllersState<TextCollectorView> {
  late final _controller = TextEditingController(text: widget.collector.value);

  @override
  List<TextEditingController> get controllers => [_controller];

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: fieldLabel(widget.collector),
        errorText: fieldErrorText(widget.collector),
        errorMaxLines: 5,
      ),
      onChanged: (value) {
        widget.collector.value = value;
        widget.onChanged();
      },
    );
  }
}
