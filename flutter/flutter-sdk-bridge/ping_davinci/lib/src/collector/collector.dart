/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import 'dart:convert';
import 'dart:typed_data';

import '../messages.g.dart';
import '../polling_status.dart';
import '../validation_error.dart';
import 'collector_values.dart';

part 'boolean_collector.dart';
part 'button_collectors.dart';
part 'device_collectors.dart';
part 'display_collectors.dart';
part 'metadata_collector.dart';
part 'multi_select_collector.dart';
part 'phone_number_collector.dart';
part 'polling_collector.dart';
part 'validated_collectors.dart';

/// The native collector class names [CollectorMessage.kind] carries. Each of the sixteen core
/// kinds — one per class behind the 17 core registry keys, `PASSWORD`/`PASSWORD_VERIFY` sharing
/// one — maps to one Dart [Collector] subtype.
abstract final class CollectorKind {
  /// [TextCollector].
  static const text = 'text';

  /// [PasswordCollector], for both `PASSWORD` and `PASSWORD_VERIFY`.
  static const password = 'password';

  /// [SingleSelectCollector], for `DROPDOWN` and `RADIO`.
  static const singleSelect = 'singleSelect';

  /// [SubmitCollector].
  static const submit = 'submit';

  /// [FlowCollector], for `FLOW_BUTTON` and `FLOW_LINK`.
  static const flow = 'flow';

  /// [MultiSelectCollector], for `CHECKBOX` and `COMBOBOX`.
  static const multiSelect = 'multiSelect';

  /// [BooleanCollector].
  static const boolean = 'boolean';

  /// [PhoneNumberCollector].
  static const phoneNumber = 'phoneNumber';

  /// [LabelCollector].
  static const label = 'label';

  /// [ReadOnlyTextCollector], for `AGREEMENT`.
  static const readOnlyText = 'readOnlyText';

  /// [ImageCollector].
  static const image = 'image';

  /// [PollingCollector].
  static const polling = 'polling';

  /// [QRCodeCollector].
  static const qrCode = 'qrCode';

  /// [DeviceRegistrationCollector].
  static const deviceRegistration = 'deviceRegistration';

  /// [DeviceAuthenticationCollector].
  static const deviceAuthentication = 'deviceAuthentication';

  /// [MetadataCollector].
  static const metadata = 'metadata';
}

/// One field of a DaVinci form, as the native collector factory resolved it. Dart-side
/// re-inflation of the wire [CollectorMessage] — see [Collector.fromMessage].
///
/// Sealed (across `part` files), so a `switch` that builds a form is checked for exhaustiveness
/// by `dart analyze`:
///
/// - [FieldCollector]s hold a typed, mutable `value`: [TextCollector], [PasswordCollector],
///   [SingleSelectCollector], [MultiSelectCollector], [BooleanCollector],
///   [PhoneNumberCollector], the [DeviceCollector]s, [MetadataCollector], and the buttons
///   [SubmitCollector] and [FlowCollector].
/// - Display-only collectors submit nothing: [LabelCollector], [ReadOnlyTextCollector],
///   [ImageCollector], [QRCodeCollector].
/// - [PollingCollector] submits a value the native poll sets (see `DaVinciClient.poll`).
/// - [AddOnCollector] is the one open branch, for collectors contributed by add-on packages
///   (social login, FIDO, Protect, …) through [Collector.registerAddOn].
sealed class Collector {
  Collector._(CollectorMessage message)
    : type = message.type,
      kind = message.kind,
      index = message.index,
      id = message.id ?? '',
      key = message.key ?? '';

  /// Re-inflates [message] into its [Collector] subtype, chosen by [CollectorMessage.kind].
  ///
  /// Throws an [UnsupportedError] naming the `type` and `kind` when the native side mapped a
  /// collector this package has no Dart type for — an add-on linked natively whose Dart package
  /// isn't registered, or a collector a newer SDK added. `DaVinciClient` never lets that throw:
  /// it reports such collectors through `ContinueNode.unsupportedFields` instead, so a flow keeps
  /// rendering. Use [tryFromMessage] for the same non-throwing behaviour.
  factory Collector.fromMessage(CollectorMessage message) =>
      tryFromMessage(message) ??
      (throw UnsupportedError(
        'No Dart collector for type "${message.type}" (native kind "${message.kind}"). '
        'If it comes from an add-on module, register its Dart package with '
        'Collector.registerAddOn.',
      ));

  /// Like [Collector.fromMessage], but returns `null` for an unsupported collector.
  static Collector? tryFromMessage(CollectorMessage message) =>
      switch (message.kind) {
        CollectorKind.text => TextCollector._(message),
        CollectorKind.password => PasswordCollector._(message),
        CollectorKind.singleSelect => SingleSelectCollector._(message),
        CollectorKind.submit => SubmitCollector._(message),
        CollectorKind.flow => FlowCollector._(message),
        CollectorKind.multiSelect => MultiSelectCollector._(message),
        CollectorKind.boolean => BooleanCollector._(message),
        CollectorKind.phoneNumber => PhoneNumberCollector._(message),
        CollectorKind.label => LabelCollector._(message),
        CollectorKind.readOnlyText => ReadOnlyTextCollector._(message),
        CollectorKind.image => ImageCollector._(message),
        CollectorKind.qrCode => QRCodeCollector._(message),
        CollectorKind.polling => PollingCollector._(message),
        CollectorKind.deviceRegistration => DeviceRegistrationCollector._(
          message,
        ),
        CollectorKind.deviceAuthentication => DeviceAuthenticationCollector._(
          message,
        ),
        CollectorKind.metadata => MetadataCollector._(message),
        final kind => _addOns[kind]?.call(message),
      };

  static final Map<String, AddOnCollector Function(CollectorMessage)> _addOns =
      <String, AddOnCollector Function(CollectorMessage)>{};

  static const Set<String> _coreKinds = <String>{
    CollectorKind.text,
    CollectorKind.password,
    CollectorKind.singleSelect,
    CollectorKind.submit,
    CollectorKind.flow,
    CollectorKind.multiSelect,
    CollectorKind.boolean,
    CollectorKind.phoneNumber,
    CollectorKind.label,
    CollectorKind.readOnlyText,
    CollectorKind.image,
    CollectorKind.qrCode,
    CollectorKind.polling,
    CollectorKind.deviceRegistration,
    CollectorKind.deviceAuthentication,
    CollectorKind.metadata,
  };

  /// Registers the Dart type for an add-on module's collector [kind] — the name that module's
  /// native mapper puts in [CollectorMessage.kind]. Called once by the add-on Dart package; a
  /// later registration for the same kind replaces the earlier one.
  ///
  /// Throws an [ArgumentError] for a kind this package already maps.
  static void registerAddOn(
    String kind,
    AddOnCollector Function(CollectorMessage message) create,
  ) {
    if (_coreKinds.contains(kind)) {
      throw ArgumentError.value(kind, 'kind', 'is a core collector kind');
    }
    _addOns[kind] = create;
  }

  /// The server's field type, e.g. `TEXT`, `PASSWORD_VERIFY`, `DROPDOWN`, `FLOW_LINK`. Two types
  /// can share one subtype (`DROPDOWN` and `RADIO` are both [SingleSelectCollector]), so render
  /// by subtype and use [type] to pick the widget within it.
  final String type;

  /// The native collector class this was mapped from — see [CollectorKind].
  final String kind;

  /// Position among the node's collectors. Addresses the collector on submit.
  final int index;

  /// The native collector id, which the submit payload is keyed by. Equal to [key] for every
  /// core collector.
  final String id;

  /// The form field key. Empty for a field the server sent without one (some labels).
  final String key;

  /// The value to submit, or `null` when there is nothing to send.
  CollectorValueMessage? toValue();
}

/// A collector that holds a value the app sets and `DaVinciClient.next` submits.
///
/// Only values the app set are sent: until [value] is assigned, [toValue] is `null` and the
/// native collector keeps the value it arrived with (a `formData` default, or empty).
///
/// A form can render every field's errors in one pass over `ContinueNode.collectors`:
/// [validationErrors] from the last `DaVinciClient.validate`, and [serverError] on the form an
/// `ErrorNode` hands back for a retry.
sealed class FieldCollector<T> extends Collector {
  FieldCollector._(super.message, this._value)
    : label = message.label ?? '',
      required = message.required ?? false,
      super._();

  /// Display label.
  final String label;

  /// Whether the server requires a value.
  final bool required;

  T _value;
  bool _changed = false;

  /// The current value: the server's default until the app sets one.
  T get value => _value;

  set value(T newValue) {
    _value = newValue;
    _changed = true;
  }

  /// Whether the app has set [value] since this collector was received.
  bool get hasChanged => _changed;

  /// Whether [value] counts as present for [required], as the native validators judge it:
  /// non-empty text, a checked box, at least one selection, a chosen device or metadata result.
  /// `ContinueNode.canSubmit` is built on it.
  bool get isFilled => switch (_value) {
    null => false,
    final String text => text.isNotEmpty,
    final bool checked => checked,
    final List<Object?> selection => selection.isNotEmpty,
    _ => true,
  };

  List<ValidationError> _validationErrors = const <ValidationError>[];
  String? _serverError;

  /// The local validation errors the last `DaVinciClient.validate` of this collector's node found
  /// in its value. Empty until then, and after a validate that found none. Not cleared when
  /// [value] changes: validate again.
  List<ValidationError> get validationErrors => _validationErrors;

  /// The server's message for this field, on the collectors of `ErrorNode.continueNode`: its
  /// `ErrorNode.fieldErrors` entry, matched by [key]. `null` elsewhere, and when the server named
  /// no field with this key.
  String? get serverError => _serverError;

  /// [value] in the shape the native applier accepts.
  Object? get _wireValue => _value;

  @override
  CollectorValueMessage? toValue() => _changed
      ? CollectorValueMessage(type: type, index: index, value: _wireValue)
      : null;
}

/// Replaces the [FieldCollector.validationErrors] of every collector in [collectors] with its
/// errors from [errors]. Package-internal: hidden from `package:ping_davinci`'s exports.
void attachValidationErrors(
  List<Collector> collectors,
  List<ValidationError> errors,
) {
  for (final collector in collectors.whereType<FieldCollector<Object?>>()) {
    collector._validationErrors = List<ValidationError>.unmodifiable(
      errors.where((error) => identical(error.collector, collector)),
    );
  }
}

/// Sets each collector's [FieldCollector.serverError] from [fieldErrors], by key.
/// Package-internal: hidden from `package:ping_davinci`'s exports.
void attachServerErrors(
  List<Collector> collectors,
  Map<String, String> fieldErrors,
) {
  for (final collector in collectors.whereType<FieldCollector<Object?>>()) {
    collector._serverError = fieldErrors[collector.key];
  }
}

/// The open branch of [Collector], for collectors an add-on package contributes. Subclass it in
/// the add-on package, and register the subclass with [Collector.registerAddOn] under the kind the
/// add-on's native mapper reports. A `switch` over [Collector] handles every add-on with one
/// `AddOnCollector()` case, then narrows by subtype.
abstract base class AddOnCollector extends Collector {
  /// Creates an add-on collector from its wire message.
  AddOnCollector(super.message) : super._();
}
