/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingDavinci
import PingDavinciPlugin

/// Runs the SDK's own local validation and maps each `ValidationError` structurally: the kind and
/// its parameters, never the SDK's hardcoded English `errorMessage`, so Dart can localize it. An
/// unbounded `max` (`Int.max`, the SDK's password-policy default) becomes `nil`, as in
/// `DaVinciCollectorMapper`. Mirrors the Android mapper.
///
/// Where the two SDKs' validators disagree (ping-ios-sdk / ping-android-sdk 2.2.0), the
/// disagreement is passed through, not corrected, and pinned by the native tests:
/// - A regex is matched with `firstMatch` here, so an unanchored pattern passes when any part of
///   the value matches; Android's `Regex.matches` needs the whole value to match (SDKS-5537).
/// - A required `BooleanCollector` left unchecked reports `regexError(errorMessage)` when the
///   server sent an `errorMessage`, where Android always reports `required` (SDKS-5538).
/// - Password length and character counts are in characters (grapheme clusters) here, in UTF-16
///   code units on Android, so they differ for emoji and other non-BMP text (SDKS-5539).
/// - `minCharacters` errors come in dictionary order, which is unspecified.
enum DaVinciValidationMapper {
    /// `validate()` on every `Validator` among `collectors`, in collector order, each error
    /// addressed by the collector's `{type, index}`. Collectors that don't validate (labels,
    /// images) contribute nothing.
    static func validate(_ collectors: [any Collector]) -> [ValidationErrorMessage] {
        collectors.enumerated().flatMap { index, collector -> [ValidationErrorMessage] in
            guard let validator = collector as? any Validator else { return [] }
            let type = DaVinciCollectorMapper.collectorType(collector)
            return validator.validate().map { map($0, type: type, index: index) }
        }
    }

    static func map(_ error: ValidationError, type: String, index: Int) -> ValidationErrorMessage {
        var message = ValidationErrorMessage(collectorType: type, index: Int64(index), kind: .required)
        switch error {
        case .required:
            break
        case .regexError(let text):
            message.kind = .regex
            message.message = text
        case .invalidLength(let min, let max):
            message.kind = .invalidLength
            message.min = Int64(min)
            message.max = bounded(max)
        case .uniqueCharacter(let min):
            message.kind = .uniqueCharacter
            message.min = Int64(min)
        case .maxRepeat(let max):
            message.kind = .maxRepeat
            message.max = bounded(max)
        case .minCharacters(let character, let min):
            message.kind = .minCharacters
            message.min = Int64(min)
            message.character = character
        }
        return message
    }

    private static func bounded(_ value: Int) -> Int64? {
        value == Int.max ? nil : Int64(value)
    }
}
