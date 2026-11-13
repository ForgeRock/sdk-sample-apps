/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:ping_davinci/ping_davinci.dart';

import 'package:flutter_davinci/ui/core/theme/app_theme.dart';
import 'package:flutter_davinci/ui/features/davinci/widgets/collectors/collector_support.dart';

/// Text on the form (`LABEL`): its rich content when it has some, else its markup as plain text.
class LabelCollectorView extends StatelessWidget {
  const LabelCollectorView({super.key, required this.collector});

  final LabelCollector collector;

  @override
  Widget build(BuildContext context) {
    if (collector.richContent case final richContent?) {
      return RichContentText(richContent: richContent);
    }
    final text = plainTextFromHtml(collector.content);
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(text);
  }
}

/// Read-only text to read before going on, such as an agreement (`AGREEMENT`).
class ReadOnlyTextCollectorView extends StatelessWidget {
  const ReadOnlyTextCollectorView({super.key, required this.collector});

  final ReadOnlyTextCollector collector;

  @override
  Widget build(BuildContext context) {
    if (!collector.enabled) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (collector.titleEnabled && collector.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              collector.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outline),
            borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
          ),
          child: SingleChildScrollView(
            child: Text(plainTextFromHtml(collector.content)),
          ),
        ),
      ],
    );
  }
}

/// An image (`IMAGE`). When it carries a link, tapping it hands the link on (see [copyLink]).
class ImageCollectorView extends StatelessWidget {
  const ImageCollectorView({super.key, required this.collector});

  final ImageCollector collector;

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      collector.imageUrl,
      semanticLabel: collector.imageDescription,
      height: 160,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Text(
        collector.imageDescription.isEmpty
            ? 'Image unavailable'
            : collector.imageDescription,
        textAlign: TextAlign.center,
      ),
    );
    return switch (collector.hyperlinkUrl) {
      final String url when url.isNotEmpty => InkWell(
        onTap: () => copyLink(context, url),
        child: image,
      ),
      _ => image,
    };
  }
}

/// A QR code to scan (`QR_CODE`), or its fallback text when the image can't be shown.
class QRCodeCollectorView extends StatelessWidget {
  const QRCodeCollectorView({super.key, required this.collector});

  final QRCodeCollector collector;

  @override
  Widget build(BuildContext context) {
    final fallback = Padding(
      padding: const EdgeInsets.all(8),
      child: SelectableText(
        collector.fallbackText.isEmpty
            ? 'QR code unavailable'
            : collector.fallbackText,
        textAlign: TextAlign.center,
      ),
    );
    final bytes = collector.imageBytes;
    return Center(
      child: bytes == null
          ? fallback
          : Image.memory(
              bytes,
              width: 220,
              height: 220,
              semanticLabel: 'QR code',
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
    );
  }
}
