/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'collector/collector.dart';
import 'error_detail.dart';
import 'unsupported_field.dart';

/// A step in a DaVinci flow. Dart-side re-inflation of the wire `NodeMessage`/`NodeType` pair —
/// see `node_mapper.dart`. Sealed, so a `switch` over it is exhaustively checked.
sealed class DaVinciNode {
  const DaVinciNode();
}

/// The flow is waiting on user input: render [collectors], set their values, and submit with
/// `DaVinciClient.next`.
final class ContinueNode extends DaVinciNode {
  /// Creates a continue node from its wire-message fields.
  const ContinueNode({
    required this.collectors,
    this.unsupportedFields = const <UnsupportedField>[],
    this.id,
    this.name,
    this.pageDescription,
    this.category,
  });

  /// The form's fields, in display order.
  final List<Collector> collectors;

  /// The form's fields that arrived without a collector: dropped by the native factory, or not
  /// mapped by this package. Most real forms list at least an `ERROR_DISPLAY`
  /// ([UnsupportedFieldReason.knownIgnorable]); the rest of the form maps and submits normally.
  final List<UnsupportedField> unsupportedFields;

  /// The DaVinci node id.
  final String? id;

  /// The form's name, e.g. its page title.
  final String? name;

  /// The form's description.
  final String? pageDescription;

  /// The form's category.
  final String? category;

  /// Whether every required field has a value ([FieldCollector.isFilled]); buttons are exempt.
  /// A cheap Dart-side check for enabling a submit button; `DaVinciClient.validate` runs the full
  /// rules natively.
  bool get canSubmit => collectors.whereType<FieldCollector<Object?>>().every(
    (collector) =>
        collector is ButtonCollector ||
        !collector.required ||
        collector.isFilled,
  );
}

/// The flow completed and the server issued an authorization code.
final class SuccessNode extends DaVinciNode {
  /// Creates a success node.
  const SuccessNode();
}

/// A recoverable error reported by the server (a `4xx`), e.g. a wrong password or a password the
/// policy rejects.
///
/// When [continueNode] is non-null the flow can be retried: render it (each collector carries
/// its [FieldCollector.serverError]), let the user correct it, and submit it with
/// `DaVinciClient.next`. Natively it is the node just submitted, so collectors keep the values
/// that were sent, except passwords, which are empty again.
///
/// **Platform difference (native 2.2.0):** a DaVinci polling timeout (`code: "timedOut"`) is an
/// `ErrorNode` on Android but a [FailureNode] on iOS. The bridge passes the native node type
/// through unchanged.
final class ErrorNode extends DaVinciNode {
  /// Creates an error node from its wire-message fields.
  const ErrorNode({
    required this.message,
    this.status,
    this.input = const <String, Object?>{},
    this.errorDetails = const <ErrorDetail>[],
    this.fieldErrors = const <String, String>{},
    this.continueNode,
  });

  /// The server's error message.
  final String message;

  /// HTTP status of the server's error response, when present.
  final int? status;

  /// The server's error response, as JSON. Its `code` names the error (`invalidValue`,
  /// `invalidPhoneNumber`, …), which matters when [errorDetails] is empty.
  final Map<String, Object?> input;

  /// The response's `details`, decoded. Empty for errors that carry none.
  final List<ErrorDetail> errorDetails;

  /// A message per field key, flattened from [errorDetails] by [ErrorDetail.fieldErrors]. The
  /// keys are the server's targets: PingOne names its own attributes (`password`), which match
  /// a form's field keys only when the form uses the same names. Entries matching a collector's
  /// key also appear as that collector's [FieldCollector.serverError].
  final Map<String, String> fieldErrors;

  /// The form to retry from, or `null` when the error can't be retried.
  final ContinueNode? continueNode;
}

/// An unrecoverable failure: network, native SDK exception, or an unexpected server response.
///
/// **Platform difference (native 2.2.0):** a DaVinci polling timeout (`code: "timedOut"`) is a
/// `FailureNode` on iOS but a recoverable [ErrorNode] on Android.
final class FailureNode extends DaVinciNode {
  /// Creates a failure node describing why the flow could not continue.
  const FailureNode({required this.cause});

  /// A description of the underlying failure.
  final String cause;
}
