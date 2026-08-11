/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Helpers for converting values received from the platform channel
/// (StandardMessageCodec-decoded `dynamic`) into plain `Map<String, Object?>`.
///
/// Platform channels decode nested structures as `Map<Object?, Object?>` /
/// `List<Object?>`; these helpers normalize that into JSON-shaped Dart values.
class JsonCodec {
  const JsonCodec._();

  /// Convert a channel-decoded map into a `Map<String, Object?>`, recursively
  /// normalizing nested maps and lists.
  static Map<String, Object?> decodeObject(Map<Object?, Object?> value) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      result[entry.key as String] = decodeElement(entry.value);
    }
    return result;
  }

  /// Normalize a single channel-decoded value.
  static Object? decodeElement(Object? element) {
    if (element == null) return null;
    if (element is Map<Object?, Object?>) return decodeObject(element);
    if (element is List<Object?>) return decodeArray(element);
    return element;
  }

  /// Normalize a channel-decoded list, recursively normalizing elements.
  static List<Object?> decodeArray(List<Object?> value) {
    return value.map(decodeElement).toList();
  }
}
