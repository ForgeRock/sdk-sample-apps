/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Flutter
import UIKit

/// Registers the generated `PingDaVinciHostApi` Pigeon channel and the `pollingEvents` event
/// channel.
public class PingDaVinciPlugin: NSObject, FlutterPlugin {
    private var api: DaVinciHostApiImpl?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = PingDaVinciPlugin()
        let api = DaVinciHostApiImpl()
        instance.api = api
        PingDaVinciHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: api)
        PollingEventsStreamHandler.register(with: registrar.messenger(), streamHandler: api.pollingEvents)
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        PingDaVinciHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
        api = nil
    }
}
