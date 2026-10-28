/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Why an [UnsupportedField] has no collector.
enum UnsupportedFieldReason {
  /// A server-side UI element with no client role, e.g. `ERROR_DISPLAY` (a placeholder where the
  /// server's own web UI prints errors). Safe to ignore.
  knownIgnorable,

  /// A field an add-on module registers (`PROTECT`, `FIDO2`, `SOCIAL_LOGIN_BUTTON`,
  /// `MOBILE_PAIRING`), which isn't linked into this app natively.
  addOnRequired,

  /// The native SDK built a collector, but this Dart package has no type for it yet — a
  /// collector this bridge doesn't map, or an add-on linked natively whose Dart package hasn't
  /// called `Collector.registerAddOn`.
  notBridged,

  /// A field no native collector is registered for.
  unknown,
}

/// A form field the app received no collector for. Every entry is reported; [reason] says
/// whether it matters, so an app can ignore the [UnsupportedFieldReason.knownIgnorable] ones and
/// surface the rest.
final class UnsupportedField {
  /// Creates an unsupported-field entry.
  const UnsupportedField({
    required this.type,
    required this.reason,
    this.key,
    this.kind,
  });

  /// Classifies a field the native collector factory dropped, by [type] — the key the factory
  /// looked up (`inputType`, falling back to `type`).
  factory UnsupportedField.dropped({required String type, String? key}) =>
      UnsupportedField(
        type: type,
        key: key,
        reason: _knownIgnorable.contains(type)
            ? UnsupportedFieldReason.knownIgnorable
            : _addOnTypes.contains(type)
            ? UnsupportedFieldReason.addOnRequired
            : UnsupportedFieldReason.unknown,
      );

  /// Server-UI-only field types: dropped by both native factories on purpose.
  static const Set<String> _knownIgnorable = <String>{'ERROR_DISPLAY'};

  /// Field types an add-on module's native collector registers.
  static const Set<String> _addOnTypes = <String>{
    'PROTECT',
    'FIDO2',
    'SOCIAL_LOGIN_BUTTON',
    'MOBILE_PAIRING',
  };

  /// The field type: the factory's lookup key for a dropped field, or the collector's server type
  /// for a [UnsupportedFieldReason.notBridged] one.
  final String type;

  /// The field key, or `null` for a key-less field such as `ERROR_DISPLAY`.
  final String? key;

  /// The native collector class, for a [UnsupportedFieldReason.notBridged] field.
  final String? kind;

  /// Why there is no collector.
  final UnsupportedFieldReason reason;

  @override
  String toString() =>
      'UnsupportedField($type, key: $key, ${reason.name}'
      '${kind == null ? '' : ', kind: $kind'})';
}
