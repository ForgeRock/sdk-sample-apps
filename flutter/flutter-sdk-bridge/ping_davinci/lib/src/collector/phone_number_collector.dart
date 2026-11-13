/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

part of 'collector.dart';

/// A phone number (`PHONE_NUMBER`), entered as three parts: see [PhoneNumberValue].
///
/// Natively the number is only submitted once both the country code and the number are
/// non-empty.
final class PhoneNumberCollector extends FieldCollector<PhoneNumberValue> {
  PhoneNumberCollector._(CollectorMessage message)
    : defaultCountryCode = message.defaultCountryCode ?? '',
      validatePhoneNumber = message.validatePhoneNumber ?? false,
      showExtension = message.showExtension ?? false,
      extensionLabel = message.extensionLabel ?? '',
      super._(
        message,
        PhoneNumberValue(
          countryCode: message.countryCode ?? '',
          phoneNumber: message.phoneNumber ?? '',
          phoneExtension: message.phoneExtension ?? '',
        ),
      );

  /// The country to preselect when [value] has none.
  final String defaultCountryCode;

  /// Whether the server asks for the number to be validated.
  final bool validatePhoneNumber;

  /// Whether to show an extension input.
  final bool showExtension;

  /// The extension input's label.
  final String extensionLabel;

  /// Natively a phone number is present once both its country code and number are.
  @override
  bool get isFilled =>
      value.countryCode.isNotEmpty && value.phoneNumber.isNotEmpty;

  @override
  Object? get _wireValue => <String, String>{
    'countryCode': value.countryCode,
    'phoneNumber': value.phoneNumber,
    'phoneExtension': value.phoneExtension,
  };
}
