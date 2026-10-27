/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingDavinci
import PingDavinciPlugin

/// Closes the iOS collector-registration race.
///
/// `DaVinci.createDaVinci(block:)` registers its core collectors inside a detached `Task {}` and
/// exposes nothing to await, so a `start()` that arrives straight after `configure` — which is
/// exactly what a Flutter channel does — can find an empty `CollectorFactory` and silently drop
/// every field. Android has no race: its `CollectorRegistry` runs eagerly through AndroidX Startup.
///
/// `register()` writes the same closures the SDK does, and is awaited before `configure` returns.
/// A duplicate registration is an idempotent dictionary overwrite, so it doesn't matter which of
/// the two writes lands last.
enum CoreCollectorRegistration {
    /// The SDK's own table, key for key and in order, from `Davinci/Davinci/DaVinci.swift` at
    /// `ping-ios-sdk` 2.2.0: the 17 core keys Android also registers, plus six iOS-only aliases
    /// (`FLOW_BUTTON`, `FLOW_LINK`, `DROPDOWN`, `RADIO`, `COMBOBOX`, `CHECKBOX`). When an SDK bump
    /// adds a core collector, add it here.
    static let registrations: [(type: String, make: @Sendable ([String: Any]) -> (any Collector)?)] = [
        (Constants.TEXT, { TextCollector(with: $0) }),
        (Constants.PASSWORD, { PasswordCollector(with: $0) }),
        (Constants.PASSWORD_VERIFY, { PasswordCollector(with: $0) }),
        (Constants.SUBMIT_BUTTON, { SubmitCollector(with: $0) }),
        (Constants.ACTION, { FlowCollector(with: $0) }),
        (Constants.LABEL, { LabelCollector(with: $0) }),
        (Constants.SINGLE_SELECT, { SingleSelectCollector(with: $0) }),
        (Constants.MULTI_SELECT, { MultiSelectCollector(with: $0) }),
        (Constants.FLOW_BUTTON, { FlowCollector(with: $0) }),
        (Constants.FLOW_LINK, { FlowCollector(with: $0) }),
        (Constants.DROPDOWN, { SingleSelectCollector(with: $0) }),
        (Constants.RADIO, { SingleSelectCollector(with: $0) }),
        (Constants.COMBOBOX, { MultiSelectCollector(with: $0) }),
        (Constants.CHECKBOX, { MultiSelectCollector(with: $0) }),
        (Constants.DEVICE_REGISTRATION, { DeviceRegistrationCollector(with: $0) }),
        (Constants.DEVICE_AUTHENTICATION, { DeviceAuthenticationCollector(with: $0) }),
        (Constants.PHONE_NUMBER, { PhoneNumberCollector(with: $0) }),
        (Constants.POLLING, { PollingCollector(with: $0) }),
        (Constants.QR_CODE, { QRCodeCollector(with: $0) }),
        (Constants.BOOLEAN, { BooleanCollector(with: $0) }),
        (Constants.READ_ONLY_TEXT, { ReadOnlyTextCollector(with: $0) }),
        (Constants.IMAGE, { ImageCollector(with: $0) }),
        (Constants.METADATA, { MetadataCollector(with: $0) }),
    ]

    /// The keys of `registrations`.
    static let types: Set<String> = Set(registrations.map(\.type))

    /// Registers every core collector with `CollectorFactory.shared`, and returns once all are in.
    static func register() async {
        for registration in registrations {
            await CollectorFactory.shared.register(type: registration.type, closure: registration.make)
        }
    }

    /// The core keys `CollectorFactory.shared` resolves right now, sorted.
    ///
    /// The factory exposes no key listing on iOS, so each key is probed by asking the factory to
    /// build a collector from a minimal field. Only the core keys are probed: add-on keys
    /// (`PROTECT`, `FIDO2`, …) are out of scope, and building their collectors could have side
    /// effects.
    static func resolvableTypes(daVinci: DaVinci) async -> [String] {
        var resolved: [String] = []
        for registration in registrations {
            let probe: [[String: Any]] = [[Constants.type: registration.type, Constants.key: "probe"]]
            if !(await CollectorFactory.shared.collector(daVinci: daVinci, from: probe)).isEmpty {
                resolved.append(registration.type)
            }
        }
        return resolved.sorted()
    }
}
