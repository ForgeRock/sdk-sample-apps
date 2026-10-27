/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/core/widgets/primary_button.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/boolean_collector_view.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/button_collector_view.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/device_collector_view.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/display_collector_views.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/metadata_collector_view.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/multi_select_collector_view.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/password_collector_view.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/phone_number_collector_view.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/polling_collector_view.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/single_select_collector_view.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/text_collector_view.dart';

/// Renders a form the app has never seen: one widget per collector of [node], in the server's
/// order.
///
/// The `switch` in [_collectorView] is exhaustive over the sealed [Collector] hierarchy, so
/// `dart analyze` fails when a `ping_davinci` update adds a collector this form doesn't draw,
/// instead of the field silently disappearing.
class CollectorForm extends StatelessWidget {
  const CollectorForm({
    super.key,
    required this.node,
    required this.loading,
    required this.onChanged,
    required this.onSubmit,
    required this.onPollingDone,
    required this.poll,
  });

  final ContinueNode node;
  final bool loading;

  /// A collector's value changed.
  final VoidCallback onChanged;

  /// The user pressed [ButtonCollector], or `null` for the form's fallback Next button.
  final ValueChanged<ButtonCollector?> onSubmit;

  /// A polling collector's poll ended; the form should be submitted as it is.
  final VoidCallback onPollingDone;

  final Stream<PollingStatus> Function(PollingCollector collector) poll;

  /// A form with no button of its own (a device choice, a metadata pause) still needs a way to
  /// submit. A polling form submits itself when its poll ends.
  bool get _needsNextButton => !node.collectors.any(
    (collector) =>
        collector is ButtonCollector || collector is PollingCollector,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final collector in node.collectors)
          Padding(
            key: ObjectKey(collector),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _collectorView(collector),
          ),
        if (_needsNextButton) ...[
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Next',
            onPressed: () => onSubmit(null),
            loading: loading,
          ),
        ],
      ],
    );
  }

  Widget _collectorView(Collector collector) => switch (collector) {
    TextCollector() => TextCollectorView(
      collector: collector,
      onChanged: onChanged,
    ),
    PasswordCollector() => PasswordCollectorView(
      collector: collector,
      onChanged: onChanged,
    ),
    SingleSelectCollector() => SingleSelectCollectorView(
      collector: collector,
      onChanged: onChanged,
    ),
    MultiSelectCollector() => MultiSelectCollectorView(
      collector: collector,
      onChanged: onChanged,
    ),
    BooleanCollector() => BooleanCollectorView(
      collector: collector,
      onChanged: onChanged,
    ),
    PhoneNumberCollector() => PhoneNumberCollectorView(
      collector: collector,
      onChanged: onChanged,
    ),
    SubmitCollector() || FlowCollector() => ButtonCollectorView(
      collector: collector as ButtonCollector,
      onPressed: () => onSubmit(collector),
      loading: loading,
    ),
    DeviceRegistrationCollector() ||
    DeviceAuthenticationCollector() => DeviceCollectorView(
      collector: collector as DeviceCollector,
      onChanged: onChanged,
    ),
    MetadataCollector() => MetadataCollectorView(
      collector: collector,
      onChanged: onChanged,
    ),
    LabelCollector() => LabelCollectorView(collector: collector),
    ReadOnlyTextCollector() => ReadOnlyTextCollectorView(collector: collector),
    ImageCollector() => ImageCollectorView(collector: collector),
    QRCodeCollector() => QRCodeCollectorView(collector: collector),
    PollingCollector() => PollingCollectorView(
      collector: collector,
      poll: poll,
      onDone: onPollingDone,
    ),
    // Collectors an add-on package contributes (social login, FIDO, Protect, …). This sample
    // links none, so it only says one arrived.
    AddOnCollector() => Text(
      'This form contains a ${collector.type} field, which this app does not support.',
    ),
  };
}
