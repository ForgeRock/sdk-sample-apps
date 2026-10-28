/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import XCTest
import PingDavinci
import PingDavinciPlugin
import PingOrchestrate
@testable import ping_davinci

private let upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
private let lower = "abcdefghijklmnopqrstuvwxyz"
private let digits = "0123456789"
private let special = "~!@#$%^&*()-_=+[]{}|;:,.<>/?"

/// `(username, email, password)` to the expected errors, as `describe` renders them. Verbatim the
/// cases of Android's `DaVinciValidationMapperTest.sharedCases`, so both platforms are checked
/// against the same expected errors.
private let sharedCases: [((String, String, String), [String])] = [
    (("", "", ""), [
        "1:REQUIRED",
        "1:REGEX:Must be alphanumeric",
        "2:REQUIRED",
        "2:REGEX:Not a valid email",
        "3:REQUIRED",
        "3:INVALID_LENGTH:min=8:max=255",
        "3:UNIQUE_CHARACTER:min=5",
        "3:MIN_CHARACTERS:min=1:\(upper)",
        "3:MIN_CHARACTERS:min=1:\(lower)",
        "3:MIN_CHARACTERS:min=1:\(digits)",
        "3:MIN_CHARACTERS:min=1:\(special)",
    ]),
    (("flutter user", "flutter@example.com", "Abcdef1!"), ["1:REGEX:Must be alphanumeric"]),
    (("flutter", "flutter@example.com", "aaa"), [
        "3:INVALID_LENGTH:min=8:max=255",
        "3:UNIQUE_CHARACTER:min=5",
        "3:MAX_REPEAT:max=2",
        "3:MIN_CHARACTERS:min=1:\(upper)",
        "3:MIN_CHARACTERS:min=1:\(digits)",
        "3:MIN_CHARACTERS:min=1:\(special)",
    ]),
    (("flutter", "flutter@example.com", "Passw0rd!"), []),
]

/// `index:KIND[:min=..][:max=..][:character or message]`, with Android's enum names.
private func describe(_ error: ValidationErrorMessage) -> String {
    let kind: String
    switch error.kind {
    case .required: kind = "REQUIRED"
    case .regex: kind = "REGEX"
    case .invalidLength: kind = "INVALID_LENGTH"
    case .uniqueCharacter: kind = "UNIQUE_CHARACTER"
    case .maxRepeat: kind = "MAX_REPEAT"
    case .minCharacters: kind = "MIN_CHARACTERS"
    }
    var text = "\(error.index):\(kind)"
    if let min = error.min { text += ":min=\(min)" }
    if let max = error.max { text += ":max=\(max)" }
    if let character = error.character { text += ":\(character)" }
    if error.kind == .regex { text += ":\(error.message ?? "")" }
    return text
}

/// Local validation over the captured Form Validation node: two regex-validated, required `TEXT`
/// fields and a `PASSWORD_VERIFY` whose policy is the node's, not the field's. Mirrors Android's
/// `DaVinciValidationMapperTest`. Errors are compared sorted: `minCharacters` errors come in
/// dictionary order here, which is unspecified.
final class DaVinciValidationMapperTests: XCTestCase {
    private func validate(_ username: String, _ email: String, _ password: String) async throws -> [String] {
        let collectors = try await continueNode("formValidationForm").collectors
        try XCTUnwrap(collectors[1] as? TextCollector).value = username
        try XCTUnwrap(collectors[2] as? TextCollector).value = email
        try XCTUnwrap(collectors[3] as? PasswordCollector).value = password
        return DaVinciValidationMapper.validate(collectors).map(describe).sorted()
    }

    func testTheSharedCasesProduceTheExpectedErrors() async throws {
        for ((username, email, password), expected) in sharedCases {
            let errors = try await validate(username, email, password)
            XCTAssertEqual(errors, expected.sorted(), "for \((username, email, password))")
        }
    }

    func testLabelsAndButtonsContributeNothing() async throws {
        let errors = DaVinciValidationMapper.validate(try await continueNode("formValidationForm").collectors)
        XCTAssertEqual(Set(errors.map(\.index)), [1, 2, 3])
    }

    func testAnUnboundedMaximumCrossesAsNil() {
        let length = DaVinciValidationMapper.map(.invalidLength(min: 8, max: Int.max), type: "PASSWORD", index: 0)
        XCTAssertEqual(length.min, 8)
        XCTAssertNil(length.max)
        XCTAssertNil(DaVinciValidationMapper.map(.maxRepeat(max: Int.max), type: "PASSWORD", index: 0).max)
    }

    // Pinned divergences: each asserts iOS's behaviour, and the Android test asserts Android's.
    // When one fails after an SDK bump, the platforms have aligned; update the docs and the
    // assertion.

    // TODO(SDKS-5537): drop the pin once the platforms agree on full vs partial regex matching.
    func testIosMatchesARegexAnywhereInTheValue() {
        let collector = TextCollector(with: [
            "type": "TEXT", "key": "code", "label": "Code",
            "validation": ["regex": "[0-9]+", "errorMessage": "Digits only"],
        ])
        collector.value = "abc1"
        // Android needs the whole value to match, so it reports "0:REGEX:Digits only".
        XCTAssertEqual(DaVinciValidationMapper.validate([collector]).map(describe), [])
    }

    // TODO(SDKS-5538): drop the pin once the platforms report the same error for this box.
    func testIosReportsARequiredUncheckedBoxAsItsErrorMessage() async throws {
        let agreement = try await continueNode("agreementForm").collectors
        let index = try XCTUnwrap(agreement.firstIndex { $0 is BooleanCollector })
        // Android reports this captured box as "REQUIRED".
        XCTAssertEqual(
            DaVinciValidationMapper.validate(agreement).map(describe),
            ["\(index):REGEX:You must agree to the terms to continue."]
        )
    }

    // TODO(SDKS-5539): drop the pin once the platforms count password characters the same way.
    func testIosMeasuresAPasswordInCharacters() async throws {
        // "Ab1!" plus two emoji is 6 characters here (min 8), but 8 UTF-16 code units on Android,
        // which reports nothing.
        let errors = try await validate("flutter", "flutter@example.com", "Ab1!\u{1F600}\u{1F600}")
        XCTAssertEqual(errors, ["3:INVALID_LENGTH:min=8:max=255"])
    }
}
