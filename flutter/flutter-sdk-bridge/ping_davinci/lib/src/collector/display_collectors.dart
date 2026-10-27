/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'collector.dart';

/// Text shown on the form (`LABEL`, from a rich-text or translatable rich-text field).
/// Display-only: it submits nothing.
final class LabelCollector extends Collector {
  LabelCollector._(super.message)
    : content = message.content ?? '',
      richContent = message.richContent == null
          ? null
          : RichContent.fromMessage(message.richContent!),
      super._();

  /// The text. For a plain rich-text field this is HTML markup as the form designer wrote it;
  /// for a translatable one it is the flattened text of [richContent].
  final String content;

  /// The text with link placeholders, for a translatable rich-text field.
  final RichContent? richContent;

  @override
  CollectorValueMessage? toValue() => null;
}

/// Read-only text, such as an agreement to read before accepting (`AGREEMENT`; native registry
/// key `READ_ONLY_TEXT`). Display-only: it submits nothing.
final class ReadOnlyTextCollector extends Collector {
  ReadOnlyTextCollector._(super.message)
    : content = message.content ?? '',
      title = message.title ?? '',
      titleEnabled = message.titleEnabled ?? false,
      enabled = message.enabled ?? true,
      agreementId = message.agreementId ?? '',
      useDynamicAgreement = message.useDynamicAgreement ?? false,
      super._();

  /// The text.
  final String content;

  /// The title.
  final String title;

  /// Whether to show [title].
  final bool titleEnabled;

  /// Whether the field is shown at all.
  final bool enabled;

  /// The PingOne agreement this text comes from, or empty.
  final String agreementId;

  /// Whether the agreement's text is chosen at runtime.
  final bool useDynamicAgreement;

  @override
  CollectorValueMessage? toValue() => null;
}

/// An image (`IMAGE`), optionally a link. Display-only: it submits nothing.
final class ImageCollector extends Collector {
  ImageCollector._(super.message)
    : imageUrl = message.imageUrl ?? '',
      imageDescription = message.imageDescription ?? '',
      hyperlinkUrl = message.hyperlinkUrl,
      super._();

  /// The image to load.
  final String imageUrl;

  /// Its description, for accessibility.
  final String imageDescription;

  /// Where tapping the image leads, or `null`.
  final String? hyperlinkUrl;

  @override
  CollectorValueMessage? toValue() => null;
}

/// A QR code to scan (`QR_CODE`). Display-only: it submits nothing. Usually paired with a
/// [PollingCollector] that waits for the scan.
///
/// Render [imageBytes] with `Image.memory`, and fall back to [fallbackText] when they are `null`
/// or the image fails to decode (`Image.memory`'s `errorBuilder`).
final class QRCodeCollector extends Collector {
  QRCodeCollector._(super.message)
    : content = message.content ?? '',
      fallbackText = message.fallbackText ?? '',
      super._();

  /// The image as the server sent it: a data URI, e.g. `data:image/png;base64,…`.
  final String content;

  /// What to show when the image can't be: a code to type in, or another way to continue.
  final String fallbackText;

  /// The image bytes decoded from [content]'s base64 part, or `null` when it isn't a base64 data
  /// URI. Non-null bytes can still fail to decode as an image.
  Uint8List? get imageBytes {
    const marker = 'base64,';
    final start = content.indexOf(marker);
    if (start < 0) return null;
    try {
      return base64.decode(content.substring(start + marker.length).trim());
    } on FormatException {
      return null;
    }
  }

  @override
  CollectorValueMessage? toValue() => null;
}
