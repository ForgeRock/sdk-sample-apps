/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// One entry of a server error's `details`, as both native SDKs decode it (native `Detail`):
/// the HTTP status of a call the flow made, and what that call answered.
///
/// On PingOne the answer is usually a PingOne API error naming the offending fields, which
/// `ErrorNode.fieldErrors` collects. It doesn't have to be: a sign-on for an unknown user carries
/// the user search's result, so every field of [rawResponse] is `null`.
final class ErrorDetail {
  /// Creates an error detail.
  const ErrorDetail({required this.statusCode, required this.rawResponse});

  /// The HTTP status of the call the flow made.
  final int statusCode;

  /// What the call answered.
  final ErrorRawResponse rawResponse;

  /// Re-inflates `NodeMessage.errorDetails`, casting each nested map elementwise. An entry
  /// without a `statusCode` or `rawResponse` is skipped (native never sends one).
  static List<ErrorDetail> listFromWire(List<Object?>? wire) =>
      List<ErrorDetail>.unmodifiable(
        (wire ?? const <Object?>[]).map(_detail).whereType<ErrorDetail>(),
      );

  /// Flattens [details] into a message per field key, the map a form needs and neither native SDK
  /// provides:
  ///
  /// - Each [ErrorFieldDetail] with a non-empty [ErrorFieldDetail.target] contributes its
  ///   [ErrorFieldDetail.message], then its [ErrorFieldDetail.innerErrors] messages in key order
  ///   (iOS gives no order). With none of those, it contributes [ErrorRawResponse.message], then
  ///   [ErrorFieldDetail.code], so a named field always gets a message.
  /// - Lines are joined with `\n`. When several details name the same target, their lines are
  ///   appended in arrival order and an identical line is kept once.
  /// - Details without a target name no field; read them from the list itself.
  static Map<String, String> fieldErrors(List<ErrorDetail> details) {
    final lines = <String, List<String>>{};
    for (final detail in details) {
      for (final error in detail.rawResponse.details) {
        final target = error.target;
        if (target == null || target.isEmpty) continue;
        final innerKeys = error.innerErrors.keys.toList()..sort();
        var parts = <String>[
          if (error.message case final message? when message.isNotEmpty)
            message,
          for (final key in innerKeys) error.innerErrors[key]!,
        ];
        if (parts.isEmpty) {
          parts = <String>[
            if (detail.rawResponse.message case final message?
                when message.isNotEmpty)
              message
            else
              error.code ?? '',
          ];
        }
        final existing = lines.putIfAbsent(target, () => <String>[]);
        for (final part in parts) {
          if (!existing.contains(part)) existing.add(part);
        }
      }
    }
    return Map<String, String>.unmodifiable(<String, String>{
      for (final entry in lines.entries) entry.key: entry.value.join('\n'),
    });
  }

  @override
  String toString() => 'ErrorDetail($statusCode, $rawResponse)';
}

/// A detail's [ErrorDetail.rawResponse] (native `RawResponse`): a PingOne API error, or `null`
/// fields when the call answered with something else.
final class ErrorRawResponse {
  /// Creates a raw response.
  const ErrorRawResponse({
    this.id,
    this.code,
    this.message,
    this.details = const <ErrorFieldDetail>[],
  });

  /// The PingOne error id.
  final String? id;

  /// The PingOne error code, e.g. `INVALID_DATA`.
  final String? code;

  /// The PingOne error message.
  final String? message;

  /// The per-field errors; empty when there are none.
  final List<ErrorFieldDetail> details;

  @override
  String toString() => 'ErrorRawResponse($code, $message, $details)';
}

/// One error inside an [ErrorRawResponse] (native `ErrorDetail`), usually naming a field.
final class ErrorFieldDetail {
  /// Creates a field error.
  const ErrorFieldDetail({
    this.code,
    this.target,
    this.message,
    this.innerErrors = const <String, String>{},
  });

  /// The error code, e.g. `INVALID_VALUE`.
  final String? code;

  /// The field the error is about, e.g. `password`. PingOne names its own attribute, which is
  /// not always the form's field key.
  final String? target;

  /// The error message.
  final String? message;

  /// The unmet requirements, by requirement name (`length`, `minCharacters`, …), each with the
  /// server's message (native `InnerError.errors`). A requirement the server lists more than once
  /// appears once.
  final Map<String, String> innerErrors;

  @override
  String toString() => 'ErrorFieldDetail($target, $code, $message)';
}

ErrorDetail? _detail(Object? wire) {
  if (wire is! Map<Object?, Object?>) return null;
  final statusCode = wire['statusCode'];
  final raw = wire['rawResponse'];
  if (statusCode is! int || raw is! Map<Object?, Object?>) return null;
  final errors = raw['details'];
  return ErrorDetail(
    statusCode: statusCode,
    rawResponse: ErrorRawResponse(
      id: raw['id'] as String?,
      code: raw['code'] as String?,
      message: raw['message'] as String?,
      details: List<ErrorFieldDetail>.unmodifiable(
        errors is List<Object?>
            ? errors.whereType<Map<Object?, Object?>>().map(_fieldDetail)
            : const <ErrorFieldDetail>[],
      ),
    ),
  );
}

ErrorFieldDetail _fieldDetail(Map<Object?, Object?> wire) {
  final inner = wire['innerError'];
  return ErrorFieldDetail(
    code: wire['code'] as String?,
    target: wire['target'] as String?,
    message: wire['message'] as String?,
    innerErrors: Map<String, String>.unmodifiable(<String, String>{
      if (inner is Map<Object?, Object?>)
        for (final entry in inner.entries)
          if (entry.key case final String key)
            if (entry.value case final String value) key: value,
    }),
  );
}
