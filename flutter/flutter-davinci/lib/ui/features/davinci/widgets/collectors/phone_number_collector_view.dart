/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/collector_support.dart';

/// A `PHONE_NUMBER` field: country code, number, and (when the server asks for one) extension.
/// The country code is the server's ISO code (e.g. `US`), preset to its default.
class PhoneNumberCollectorView extends StatefulWidget {
  const PhoneNumberCollectorView({
    super.key,
    required this.collector,
    required this.onChanged,
  });

  final PhoneNumberCollector collector;
  final VoidCallback onChanged;

  @override
  State<PhoneNumberCollectorView> createState() =>
      _PhoneNumberCollectorViewState();
}

class _PhoneNumberCollectorViewState extends State<PhoneNumberCollectorView>
    with ControllersState<PhoneNumberCollectorView> {
  late final PhoneNumberValue _initial = widget.collector.value;
  late final _country = TextEditingController(
    text: _initial.countryCode.isNotEmpty
        ? _initial.countryCode
        : widget.collector.defaultCountryCode,
  );
  late final _number = TextEditingController(text: _initial.phoneNumber);
  late final _extension = TextEditingController(text: _initial.phoneExtension);

  @override
  List<TextEditingController> get controllers => [
    _country,
    _number,
    _extension,
  ];

  void _changed(String _) {
    widget.collector.value = PhoneNumberValue(
      countryCode: _country.text.trim().toUpperCase(),
      phoneNumber: _number.text.trim(),
      phoneExtension: _extension.text.trim(),
    );
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final collector = widget.collector;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: TextField(
                controller: _country,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Country'),
                onChanged: _changed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _number,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: fieldLabel(collector),
                  errorText: fieldErrorText(collector),
                  errorMaxLines: 5,
                ),
                onChanged: _changed,
              ),
            ),
          ],
        ),
        if (collector.showExtension) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _extension,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: collector.extensionLabel.isEmpty
                  ? 'Extension'
                  : collector.extensionLabel,
            ),
            onChanged: _changed,
          ),
        ],
      ],
    );
  }
}
