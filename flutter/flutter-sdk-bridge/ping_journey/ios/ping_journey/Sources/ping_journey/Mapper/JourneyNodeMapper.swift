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

/// Maps a native `Node` to the wire-serializable `NodeMessage`, including full per-callback field
/// mapping for the v1 callback set. Exposes `pageHeader`/`pageDescription`/`stage` as real fields
/// (this SDK's `JourneyPlugin` `ContinueNode` extension properties) rather than as an opaque
/// passthrough blob.
enum JourneyNodeMapper {
    static func map(_ node: Node) -> NodeMessage {
        switch node {
        case let continueNode as ContinueNode:
            return NodeMessage(
                type: .continueNode,
                header: continueNode.pageHeader,
                pageDescription: continueNode.pageDescription,
                stage: continueNode.stage,
                callbacks: mapCallbacks(continueNode)
            )
        case is SuccessNode:
            return NodeMessage(type: .successNode)
        case let errorNode as ErrorNode:
            return NodeMessage(
                type: .errorNode,
                message: errorNode.message,
                status: errorNode.status.map { Int64($0) },
                input: errorNode.input as? [String?: Any?]
            )
        case let failureNode as FailureNode:
            return NodeMessage(type: .failureNode, cause: plainErrorMessage(for: failureNode.cause))
        default:
            return NodeMessage(type: .failureNode, cause: "Unknown node type: \(node)")
        }
    }

    private static func mapCallbacks(_ node: ContinueNode) -> [CallbackMessage] {
        var typeCounts: [String: Int64] = [:]
        return node.callbacks.map { callback in
            let type = callbackType(callback)
            let index = typeCounts[type, default: 0]
            typeCounts[type] = index + 1
            return mapCallback(callback, type: type, index: index)
        }
    }

    /// The server-registered `"type"` string from `AbstractCallback.json`, stable across
    /// release-build symbol stripping — unlike `String(describing: type(of:))`, which reflects the
    /// Swift runtime type name and isn't a wire-format guarantee.
    private static func callbackType(_ callback: any Callback) -> String {
        guard let abstractCallback = callback as? AbstractCallback,
              let type = abstractCallback.json[JourneyConstants.type] as? String else {
            fatalError("Callback is missing a \"type\" field: \(callback)")
        }
        return type
    }

    private static func mapCallback(_ callback: any Callback, type: String, index: Int64) -> CallbackMessage {
        var message = CallbackMessage(type: type, index: index)

        if let validated = callback as? AbstractValidatedCallback {
            message.prompt = validated.prompt
            message.validateOnly = validated.validateOnly
            message.policies = validated.policies
            message.failedPolicies = validated.failedPolicies.map {
                ["params": $0.params, "policyRequirement": $0.policyRequirement]
            }
        }
        if let attribute = callback as? AttributeInputCallback {
            message.name = attribute.name
            message.required = attribute.required
        }

        switch callback {
        case let name as NameCallback:
            message.prompt = name.prompt
            message.value = name.name
        case let password as PasswordCallback:
            message.prompt = password.prompt
            message.value = ""
        case let username as ValidatedUsernameCallback:
            message.value = username.username
        case let validatedPassword as ValidatedPasswordCallback:
            message.value = ""
            message.echoOn = validatedPassword.echoOn
        case let textInput as TextInputCallback:
            message.prompt = textInput.prompt
            message.defaultText = textInput.defaultText
            message.value = textInput.text
        case let textOutput as TextOutputCallback:
            message.message = textOutput.message
            message.messageType = String(describing: textOutput.messageType)
        case let choice as ChoiceCallback:
            message.prompt = choice.prompt
            message.choices = choice.choices
            message.defaultChoice = Int64(choice.defaultChoice)
            message.selectedIndex = Int64(choice.selectedIndex)
        case let kba as KbaCreateCallback:
            message.prompt = kba.prompt
            message.predefinedQuestions = kba.predefinedQuestions
            message.selectedQuestion = kba.selectedQuestion
            message.selectedAnswer = kba.selectedAnswer
            message.allowUserDefinedQuestions = kba.allowUserDefinedQuestions
        case let terms as TermsAndConditionsCallback:
            message.version = terms.version
            message.terms = terms.terms
            message.createDate = terms.createDate
            message.accepted = terms.accepted
        case let boolAttribute as BooleanAttributeInputCallback:
            message.value = boolAttribute.value
        case let numberAttribute as NumberAttributeInputCallback:
            message.value = numberAttribute.value
        case let stringAttribute as StringAttributeInputCallback:
            message.value = stringAttribute.value
        default:
            if let abstractCallback = callback as? AbstractCallback {
                message.raw = abstractCallback.json as? [String?: Any?]
            }
        }

        return message
    }
}
