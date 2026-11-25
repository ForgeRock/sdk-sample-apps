/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Flutter
import UIKit

/// Registers the generated `PingDeviceProfileHostApi` Pigeon channel.
public class PingDeviceProfilePlugin: NSObject, FlutterPlugin {
    private var api: DeviceProfileHostApiImpl?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = PingDeviceProfilePlugin()
        let api = DeviceProfileHostApiImpl()
        instance.api = api
        PingDeviceProfileHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: api)
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        PingDeviceProfileHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
        api = nil
    }
}
