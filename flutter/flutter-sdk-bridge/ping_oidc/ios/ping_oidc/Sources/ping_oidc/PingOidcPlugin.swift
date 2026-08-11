/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Flutter
import UIKit

/// Registers the generated `PingOidcHostApi` Pigeon channel.
public class PingOidcPlugin: NSObject, FlutterPlugin {
    private var api: OidcHostApiImpl?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = PingOidcPlugin()
        let api = OidcHostApiImpl()
        instance.api = api
        PingOidcHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: api)
        registrar.publish(instance)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        PingOidcHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
        api = nil
    }
}
