/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'collector.dart';

/// A pause for the app itself (`METADATA`, native 2.2.0): the flow reached a DaVinci SDK
/// Integrator connector, which hands the app [metadata] and waits for a result.
///
/// Do the work the connector asks for, call [setResult] or [setError], then
/// `DaVinciClient.next`. Until one is set, [value] is `null`, `DaVinciClient.validate` reports a
/// [RequiredError], and `ContinueNode.canSubmit` is `false` — whatever the field's `required`
/// flag says, as in both native SDKs. The native collector builds the payload and `actionKey`.
final class MetadataCollector extends FieldCollector<MetadataResult?> {
  MetadataCollector._(CollectorMessage message)
    : metadata = Map<String, Object?>.unmodifiable(<String, Object?>{
        for (final MapEntry(:key, :value)
            in (message.metadata ?? const <String?, Object?>{}).entries)
          ?key: value,
      }),
      super._(message, null);

  /// The connector's payload, as JSON.
  final Map<String, Object?> metadata;

  /// Always `true`: the native collector requires a result regardless of the field's flag.
  @override
  bool get required => true;

  /// Resumes the connector's success branch with [result], which must be JSON. An empty map
  /// satisfies validation but sends nothing: both SDKs leave an empty result out of the request.
  void setResult(Map<String, Object?> result) =>
      value = MetadataSuccess(Map<String, Object?>.unmodifiable(result));

  /// Resumes the connector's client-error branch with [code] (e.g. `USER_CANCELLED`) and
  /// [message].
  void setError(String code, String message) =>
      value = MetadataFailure(code: code, message: message);

  @override
  Object? get _wireValue => switch (_value) {
    MetadataSuccess(:final result) => <String, Object?>{'result': result},
    MetadataFailure(:final code, :final message) => <String, Object?>{
      'error': <String, Object?>{'code': code, 'message': message},
    },
    null => null,
  };
}
