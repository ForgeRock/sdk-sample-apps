/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'collector/collector.dart';
import 'davinci_node.dart';
import 'error_detail.dart';
import 'messages.g.dart';
import 'unsupported_field.dart';

/// Re-inflates Pigeon-generated wire messages into the Dart sealed [DaVinciNode] hierarchy.
class NodeMapper {
  const NodeMapper._();

  /// Maps a [NodeMessage] to the matching [DaVinciNode] subtype.
  static DaVinciNode map(NodeMessage message) => switch (message.type) {
    NodeType.continueNode => _continueNode(message),
    NodeType.successNode => const SuccessNode(),
    NodeType.errorNode => _errorNode(message),
    NodeType.failureNode => FailureNode(
      cause: message.cause ?? 'Unknown failure',
    ),
  };

  /// A non-null `collectors` marks a retryable error; the page fields and collectors are the
  /// retry node's, and its collectors get their server errors attached.
  static ErrorNode _errorNode(NodeMessage message) {
    final details = ErrorDetail.listFromWire(message.errorDetails);
    final fieldErrors = ErrorDetail.fieldErrors(details);
    final retry = message.collectors == null ? null : _continueNode(message);
    if (retry != null) attachServerErrors(retry.collectors, fieldErrors);
    return ErrorNode(
      message: message.message ?? '',
      status: message.status,
      input: Map<String, Object?>.unmodifiable(<String, Object?>{
        for (final entry
            in (message.input ?? const <String?, Object?>{}).entries)
          if (entry.key case final String key) key: entry.value,
      }),
      errorDetails: details,
      fieldErrors: fieldErrors,
      continueNode: retry,
    );
  }

  /// Collectors this package can't type become [UnsupportedFieldReason.notBridged] entries rather
  /// than failing the node; their `index` stays reserved, so the others still address correctly.
  static ContinueNode _continueNode(NodeMessage message) {
    final collectors = <Collector>[];
    final unsupported = <UnsupportedField>[];
    for (final collector
        in message.collectors?.whereType<CollectorMessage>() ??
            const <CollectorMessage>[]) {
      final mapped = Collector.tryFromMessage(collector);
      if (mapped != null) {
        collectors.add(mapped);
      } else {
        unsupported.add(
          UnsupportedField(
            type: collector.type,
            key: collector.key,
            kind: collector.kind,
            reason: UnsupportedFieldReason.notBridged,
          ),
        );
      }
    }
    for (final field
        in message.unsupportedFields?.whereType<Map<Object?, Object?>>() ??
            const <Map<Object?, Object?>>[]) {
      final type = field['type'];
      if (type is String) {
        unsupported.add(
          UnsupportedField.dropped(type: type, key: field['key'] as String?),
        );
      }
    }
    return ContinueNode(
      id: message.id,
      name: message.name,
      pageDescription: message.pageDescription,
      category: message.category,
      collectors: List<Collector>.unmodifiable(collectors),
      unsupportedFields: List<UnsupportedField>.unmodifiable(unsupported),
    );
  }
}
