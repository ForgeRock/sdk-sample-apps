/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ping_davinci/ping_davinci.dart';

/// [collector]'s label, marked when the server requires a value.
String fieldLabel(FieldCollector<Object?> collector) =>
    collector.required ? '${collector.label} *' : collector.label;

/// Every error to show under [collector]: the local ones from the last validate, then the
/// server's message from an `ErrorNode` retry. `null` when there are none.
String? fieldErrorText(FieldCollector<Object?> collector) {
  final lines = [
    for (final error in collector.validationErrors) error.message,
    ?collector.serverError,
  ];
  return lines.isEmpty ? null : lines.join('\n');
}

/// Converts a `LABEL`'s HTML markup to plain text: line breaks kept, tags dropped, the common
/// entities decoded. The sample has no HTML renderer; an app that has one should use it.
String plainTextFromHtml(String html) => html
    .replaceAll(
      RegExp(r'<br\s*/?>|</p>|</div>|</li>', caseSensitive: false),
      '\n',
    )
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

/// Copies [url] to the clipboard and says so. The sample opens no links itself, to keep its
/// dependencies to the bridge plus app plumbing; an app would hand [url] to `url_launcher`.
void copyLink(BuildContext context, String url) {
  Clipboard.setData(ClipboardData(text: url));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Link copied: $url')));
}

/// The error line drawn under a field that has no `InputDecoration` of its own (checkboxes,
/// radio groups, chips, device lists).
class FieldErrorText extends StatelessWidget {
  const FieldErrorText({super.key, required this.collector});

  final FieldCollector<Object?> collector;

  @override
  Widget build(BuildContext context) {
    final text = fieldErrorText(collector);
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

/// Lays out a [RichContent]: its text with each `{{key}}` placeholder replaced by its
/// [RichContentReplacement], links underlined and tappable.
class RichContentText extends StatelessWidget {
  const RichContentText({super.key, required this.richContent, this.style});

  final RichContent richContent;
  final TextStyle? style;

  static final _placeholder = RegExp(r'\{\{\s*([^}\s]+)\s*\}\}');

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final linkStyle = base.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _placeholder.allMatches(richContent.content)) {
      spans.add(
        TextSpan(text: richContent.content.substring(last, match.start)),
      );
      final replacement = richContent.replacements[match.group(1)];
      if (replacement == null) {
        spans.add(TextSpan(text: match.group(0)));
      } else if (replacement.href case final href?) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => copyLink(context, href),
              child: Text(replacement.value, style: linkStyle),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: replacement.value));
      }
      last = match.end;
    }
    spans.add(TextSpan(text: richContent.content.substring(last)));
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

/// Disposes [controllers] automatically, removing the repeated `TextEditingController` +
/// `dispose()` boilerplate shared by the text-entry collector views.
mixin ControllersState<T extends StatefulWidget> on State<T> {
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
