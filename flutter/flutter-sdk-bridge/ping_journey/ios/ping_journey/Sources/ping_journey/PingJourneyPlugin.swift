/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Flutter
import UIKit

/// Registers the generated `PingJourneyHostApi` Pigeon channel.
public class PingJourneyPlugin: NSObject, FlutterPlugin {
    private var api: JourneyHostApiImpl?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = PingJourneyPlugin()
        let api = JourneyHostApiImpl()
        instance.api = api
        PingJourneyHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: api)
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        PingJourneyHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
        api = nil
    }
}
