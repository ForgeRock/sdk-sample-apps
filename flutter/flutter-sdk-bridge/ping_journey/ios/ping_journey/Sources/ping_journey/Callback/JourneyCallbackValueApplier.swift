/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingJourney
import PingJourneyPlugin
import PingOrchestrate

/// Applies Dart-submitted `CallbackValueMessage`s back onto a cached native `ContinueNode`'s live
/// callbacks, addressed by `{type, index}`. Trimmed to the v1 callback set (no
/// integration-gated/output-only mutation attempts to reject — the Dart side never submits a
/// value for `TextOutputCallback`, and no v1 type requires additional native integration).
enum JourneyCallbackValueApplier {
    static func apply(_ node: ContinueNode, values: [CallbackValueMessage]) throws {
        var callbacksByType: [String: [any Callback]] = [:]
        for callback in node.callbacks {
            let type = String(describing: Swift.type(of: callback))
            callbacksByType[type, default: []].append(callback)
        }

        for value in values {
            let matching = callbacksByType[value.type] ?? []
            guard value.index >= 0, Int(value.index) < matching.count else {
                throw JourneyHostApiError.callbackApply(
                    "No active callback found for type \(value.type) at index \(value.index)"
                )
            }
            try applyValue(matching[Int(value.index)], value)
        }
    }

    private static func applyValue(_ callback: any Callback, _ value: CallbackValueMessage) throws {
        switch callback {
        case let name as NameCallback:
            name.name = try asString(value)
        case let password as PasswordCallback:
            password.password = try asString(value)
        case let username as ValidatedUsernameCallback:
            username.username = try asString(value)
        case let validatedPassword as ValidatedPasswordCallback:
            validatedPassword.password = try asString(value)
        case let textInput as TextInputCallback:
            textInput.text = try asString(value)
        case let stringAttribute as StringAttributeInputCallback:
            stringAttribute.value = try asString(value)
        case let numberAttribute as NumberAttributeInputCallback:
            numberAttribute.value = try asDouble(value)
        case let boolAttribute as BooleanAttributeInputCallback:
            boolAttribute.value = try asBool(value)
        case let choice as ChoiceCallback:
            choice.selectedIndex = try asInt(value)
        case let terms as TermsAndConditionsCallback:
            terms.accepted = try asBool(value)
        case let kba as KbaCreateCallback:
            try applyKba(kba, value)
        default:
            throw JourneyHostApiError.unsupported(
                "Callback type \(value.type) is not supported for value mutation"
            )
        }
    }

    private static func applyKba(_ callback: KbaCreateCallback, _ value: CallbackValueMessage) throws {
        let map = try asMap(value)
        if let selectedQuestion = map["selectedQuestion"] as? String {
            callback.selectedQuestion = selectedQuestion
        }
        if let selectedAnswer = map["selectedAnswer"] as? String {
            callback.selectedAnswer = selectedAnswer
        }
        if let allowUserDefinedQuestions = map["allowUserDefinedQuestions"] as? Bool {
            callback.allowUserDefinedQuestions = allowUserDefinedQuestions
        }
    }

    private static func asString(_ value: CallbackValueMessage) throws -> String {
        guard let stringValue = value.value as? String else {
            throw JourneyHostApiError.callbackApply("\(value.type) expects a String value")
        }
        return stringValue
    }

    private static func asBool(_ value: CallbackValueMessage) throws -> Bool {
        guard let boolValue = value.value as? Bool else {
            throw JourneyHostApiError.callbackApply("\(value.type) expects a Bool value")
        }
        return boolValue
    }

    private static func asInt(_ value: CallbackValueMessage) throws -> Int {
        guard let numberValue = value.value as? NSNumber else {
            throw JourneyHostApiError.callbackApply("\(value.type) expects a numeric value")
        }
        return numberValue.intValue
    }

    private static func asDouble(_ value: CallbackValueMessage) throws -> Double {
        guard let numberValue = value.value as? NSNumber else {
            throw JourneyHostApiError.callbackApply("\(value.type) expects a numeric value")
        }
        return numberValue.doubleValue
    }

    private static func asMap(_ value: CallbackValueMessage) throws -> [String: Any] {
        guard let mapValue = value.value as? [String: Any] else {
            throw JourneyHostApiError.callbackApply("\(value.type) expects an object value")
        }
        return mapValue
    }
}
