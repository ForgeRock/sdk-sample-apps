/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingDavinci
import PingDavinciPlugin
import PingOrchestrate

/// Maps a native `Node` to the wire-serializable `NodeMessage`. Exposes the DaVinci `ContinueNode`
/// extension properties (`id`, `name`, `description`, `category`) as real fields.
///
/// An `ErrorNode` carries its decoded `details` and, when it is retryable, the page fields and
/// collectors of the `ContinueNode` it can be retried from. Session and user data are added by
/// later phases; a `SuccessNode` carries only its type for now. Mirrors the Android mapper.
enum DaVinciNodeMapper {
    /// Maps `node`, asking `daVinci`'s collector factory which of the form fields it dropped (see
    /// `unsupportedFields(input:isRegistered:)`): a `ContinueNode`'s own, or an `ErrorNode`'s
    /// retry node's.
    static func map(_ node: Node, daVinci: DaVinci) async -> NodeMessage {
        guard let page = node as? ContinueNode ?? (node as? ErrorNode)?.continueNode else { return map(node) }
        let unsupported = await unsupportedFields(input: page.input) { type, field in
            await isRegistered(type: type, field: field, daVinci: daVinci)
        }
        return map(node, unsupportedFields: unsupported)
    }

    /// `unsupportedFields` are those of the `ContinueNode`, or of an `ErrorNode`'s retry node.
    static func map(_ node: Node, unsupportedFields: [Any?] = []) -> NodeMessage {
        switch node {
        case let continueNode as ContinueNode:
            return NodeMessage(
                type: .continueNode,
                id: continueNode.id,
                name: continueNode.name,
                pageDescription: continueNode.description,
                category: continueNode.category,
                collectors: DaVinciCollectorMapper.map(continueNode.collectors),
                unsupportedFields: unsupportedFields.isEmpty ? nil : unsupportedFields
            )
        case is SuccessNode:
            return NodeMessage(type: .successNode)
        case let errorNode as ErrorNode:
            let details = errorDetails(errorNode.details)
            var message = NodeMessage(
                type: .errorNode,
                message: errorNode.message,
                status: errorNode.status.map { Int64($0) },
                input: errorNode.input as? [String?: Any?],
                errorDetails: details.isEmpty ? nil : details
            )
            // The retry node is the one just submitted, which the SDK keeps in the flow context.
            // The SDK closed it on submit, so its password collectors are empty again, while every
            // other collector keeps the value that was sent.
            if let retry = errorNode.continueNode {
                let page = map(retry, unsupportedFields: unsupportedFields)
                message.id = page.id
                message.name = page.name
                message.pageDescription = page.pageDescription
                message.category = page.category
                message.collectors = page.collectors
                message.unsupportedFields = page.unsupportedFields
            }
            return message
        case let failureNode as FailureNode:
            return NodeMessage(type: .failureNode, cause: plainErrorMessage(for: failureNode.cause))
        default:
            // iOS-only `EmptyNode`, which the DaVinci flow never returns.
            return NodeMessage(type: .failureNode, cause: "Unexpected node type: \(type(of: node))")
        }
    }

    /// `ErrorNode.details` as wire maps (see `NodeMessage.errorDetails`). The SDK has already
    /// dropped any element it couldn't decode, and reads absent keys as `nil`; the Android mapper
    /// decodes per element and with absent nullable keys as null to match (SDKS-5536).
    static func errorDetails(_ details: [Detail]) -> [Any?] {
        details.map { detail -> Any? in
            let raw = detail.rawResponse
            let errors: [Any?]? = raw.details?.map { error -> Any? in
                [
                    "code": error.code,
                    "target": error.target,
                    "message": error.message,
                    "innerError": error.innerError?.errors,
                ] as [String?: Any?]
            }
            return [
                "statusCode": Int64(detail.statusCode),
                "rawResponse": [
                    "id": raw.id,
                    "code": raw.code,
                    "message": raw.message,
                    "details": errors,
                ] as [String?: Any?],
            ] as [String?: Any?]
        }
    }

    /// The form fields the collector factory dropped, as `{key, type}` maps: those whose lookup key
    /// — `inputType`, falling back to `type`, exactly as `CollectorFactory.collector(daVinci:from:)`
    /// resolves it — `isRegistered` says has no collector. Unlike RN v1.1.0's key-based diff,
    /// key-less fields (`ERROR_DISPLAY`) are reported too, with a `nil` key. Mirrors Android's
    /// `unsupportedFields`.
    static func unsupportedFields(
        input: [String: Any],
        isRegistered: (String, [String: Any]) async -> Bool
    ) async -> [Any?] {
        guard let form = input["form"] as? [String: Any],
              let components = form["components"] as? [String: Any],
              let fields = components["fields"] as? [[String: Any]] else { return [] }
        var unsupported: [Any?] = []
        for field in fields {
            guard let type = field["inputType"] as? String ?? field["type"] as? String else { continue }
            if await !isRegistered(type, field) {
                unsupported.append(["key": field["key"] as? String, "type": type] as [String?: Any?])
            }
        }
        return unsupported
    }

    /// iOS's factory has no key listing. The core keys are registered by `DaVinciFactory` before
    /// any node exists, so they need no check; any other key (an add-on's, or one nothing
    /// registers) is probed by asking the factory to build `field` — exactly the call that built
    /// the node, so a key it resolves here it resolved there. With no add-on linked the probe never
    /// constructs a collector.
    private static func isRegistered(type: String, field: [String: Any], daVinci: DaVinci) async -> Bool {
        if CoreCollectorRegistration.types.contains(type) { return true }
        return !(await CollectorFactory.shared.collector(daVinci: daVinci, from: [field])).isEmpty
    }
}
