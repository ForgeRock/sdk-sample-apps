/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingDavinci
import PingDavinciPlugin

/// Applies Dart-submitted `CollectorValueMessage`s onto the cached `ContinueNode`'s collectors.
///
/// Each message is addressed by `{type, index}`: `index` into the node's collectors, with `type`
/// checked against `DaVinciCollectorMapper.collectorType(_:)` so a stale or mis-addressed message
/// fails instead of writing into the wrong field. Values are type-checked strictly — a wrong type
/// throws `DaVinciHostApiError.argument`, never a silent no-op or a coercion. Every message is
/// resolved and checked before any collector is written, so a bad value leaves the node untouched.
/// Mirrors the Android applier.
enum DaVinciCollectorValueApplier {
    static func apply(_ collectors: [any Collector], values: [CollectorValueMessage]) throws {
        let assignments = try values.map { message in
            try assignment(for: resolve(collectors, message), message)
        }
        assignments.forEach { $0() }
    }

    private static func resolve(_ collectors: [any Collector], _ message: CollectorValueMessage) throws -> any Collector {
        let index = Int(message.index)
        guard collectors.indices.contains(index) else {
            throw DaVinciHostApiError.argument(
                "No collector at index=\(message.index) (the node has \(collectors.count))"
            )
        }
        let collector = collectors[index]
        let actual = DaVinciCollectorMapper.collectorType(collector)
        guard actual == message.type else {
            throw DaVinciHostApiError.argument("Collector at index=\(message.index) is \(actual), not \(message.type)")
        }
        return collector
    }

    /// Checks `message`'s value for `collector` and returns the write, without performing it.
    private static func assignment(for collector: any Collector, _ message: CollectorValueMessage) throws -> () -> Void {
        let value = message.value
        let location = "\(message.type) at index=\(message.index)"
        switch collector {
        // Before SingleValueCollector, which PollingCollector extends.
        case is PollingCollector:
            throw DaVinciHostApiError.argument("\(location) takes no value from the app: polling sets it")
        case let metadata as MetadataCollector:
            return try self.metadata(metadata, location, value)
        case is LabelCollector, is ReadOnlyTextCollector, is ImageCollector, is QRCodeCollector:
            throw DaVinciHostApiError.argument("\(location) is display-only and takes no value")
        case let single as SingleValueCollector:
            guard let text = value as? String else { throw wrongType(location, "a String", value) }
            return { single.value = text }
        case let boolean as BooleanCollector:
            guard let flag = strictBool(value) else { throw wrongType(location, "a bool", value) }
            return { boolean.value = flag }
        case let multi as MultiSelectCollector:
            guard let list = value as? [Any?] else { throw wrongType(location, "a List<String>", value) }
            let strings = try list.map { element -> String in
                guard let string = element as? String else { throw wrongType(location, "a List<String>", value) }
                return string
            }
            return { multi.value = strings }
        case let phone as PhoneNumberCollector:
            return try phoneNumber(phone, location, value)
        case let registration as DeviceRegistrationCollector:
            let device = try device(registration.devices, location, value)
            return { registration.value = device }
        case let authentication as DeviceAuthenticationCollector:
            let device = try device(authentication.devices, location, value)
            return { authentication.value = device }
        default:
            throw DaVinciHostApiError.unsupported(
                "\(location) (\(type(of: collector))) is not supported by the bridge"
            )
        }
    }

    /// `{countryCode, phoneNumber, phoneExtension}`, all optional Strings — the message's field names.
    private static func phoneNumber(_ collector: PhoneNumberCollector, _ location: String, _ value: Any?) throws -> () -> Void {
        guard let map = stringKeyedMap(value) else { throw wrongType(location, "a phone-number map", value) }
        let unknown = Set(map.keys).subtracting(phoneKeys)
        guard unknown.isEmpty else {
            throw DaVinciHostApiError.argument("\(location) has unknown phone-number keys \(unknown.sorted())")
        }
        var parts: [String: String] = [:]
        for (key, part) in map where !(part is NSNull) {
            guard let string = part as? String else { throw wrongType("\(location).\(key)", "a String", part) }
            parts[key] = string
        }
        return {
            if let countryCode = parts["countryCode"] { collector.countryCode = countryCode }
            if let phoneNumber = parts["phoneNumber"] { collector.phoneNumber = phoneNumber }
            if let phoneExtension = parts["phoneExtension"] { collector.extension = phoneExtension }
        }
    }

    /// `{result: Map}` for `setResult`, or `{error: {code, message}}` for `setError`: exactly one
    /// key. The collector builds its own payload and `actionKey` from either.
    private static func metadata(_ collector: MetadataCollector, _ location: String, _ value: Any?) throws -> () -> Void {
        guard let map = stringKeyedMap(value) else { throw wrongType(location, "a metadata result map", value) }
        guard map.count == 1, let key = map.keys.first, key == "result" || key == "error" else {
            throw DaVinciHostApiError.argument(
                "\(location) expects exactly one of {result} or {error}, got keys \(map.keys.sorted())"
            )
        }
        if key == "result" {
            guard let result = try jsonValue(map["result"], "\(location).result") as? [String: Any] else {
                throw wrongType("\(location).result", "a Map", map["result"])
            }
            return { collector.setResult(result) }
        }
        guard let error = stringKeyedMap(map["error"]) else {
            throw wrongType("\(location).error", "a Map", map["error"])
        }
        guard Set(error.keys) == ["code", "message"] else {
            throw DaVinciHostApiError.argument("\(location).error expects keys {code, message}, got \(error.keys.sorted())")
        }
        guard let code = error["code"] as? String else { throw wrongType("\(location).error.code", "a String", error["code"]) }
        guard let message = error["message"] as? String else {
            throw wrongType("\(location).error.message", "a String", error["message"])
        }
        return { collector.setError(code: code, message: message) }
    }

    /// A Pigeon-decoded value as `JSONSerialization` would build it: maps need String keys, and
    /// nothing but JSON types passes. `nil` becomes `NSNull`, which the SDK posts as `null`.
    private static func jsonValue(_ value: Any?, _ location: String) throws -> Any {
        switch value {
        case nil, is NSNull:
            return NSNull()
        case let string as String:
            return string
        case let number as NSNumber:
            return number
        case let list as [Any?]:
            return try list.enumerated().map { try jsonValue($1, "\(location)[\($0)]") }
        case let map as [AnyHashable: Any]:
            var result: [String: Any] = [:]
            for (key, element) in map {
                guard let name = key as? String else { throw wrongType("\(location) key", "a String", key) }
                result[name] = try jsonValue(element, "\(location).\(name)")
            }
            return result
        default:
            throw wrongType(location, "a JSON value", value)
        }
    }

    /// A `{id?, type}` map selecting one of the collector's own devices — by id when given.
    private static func device(_ devices: [Device], _ location: String, _ value: Any?) throws -> Device {
        guard let map = stringKeyedMap(value) else { throw wrongType(location, "a device map", value) }
        let id = map["id"] as? String
        let type = map["type"] as? String
        guard id != nil || type != nil else {
            throw DaVinciHostApiError.argument("\(location) needs a device id or type")
        }
        let match = devices.first { id != nil ? $0.id == id : $0.type == type }
        guard let match else {
            let wanted = id.map { "id=\($0)" } ?? "type=\(type ?? "")"
            throw DaVinciHostApiError.argument("\(location) has no device with \(wanted)")
        }
        return match
    }

    /// Pigeon decodes bools and ints both as `NSNumber`, and `as? Bool` accepts `NSNumber(1)`.
    private static func strictBool(_ value: Any?) -> Bool? {
        guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { return nil }
        return number.boolValue
    }

    private static func stringKeyedMap(_ value: Any?) -> [String: Any]? {
        guard let map = value as? [AnyHashable: Any] else { return nil }
        var result: [String: Any] = [:]
        for (key, element) in map {
            guard let key = key as? String else { return nil }
            result[key] = element
        }
        return result
    }

    private static func wrongType(_ location: String, _ expected: String, _ value: Any?) -> DaVinciHostApiError {
        let actual = value.map { String(describing: type(of: $0)) } ?? "null"
        return .argument("\(location) expects \(expected), got \(actual)")
    }

    private static let phoneKeys: Set<String> = ["countryCode", "phoneNumber", "phoneExtension"]
}
