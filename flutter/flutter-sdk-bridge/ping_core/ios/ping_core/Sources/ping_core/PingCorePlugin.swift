/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Flutter
import UIKit

/// Trivial `FlutterPlugin` registration so the `ping_core` module loads and links
/// `CoreRuntime` into the app binary. Carries no Pigeon/method channel of its own.
public class PingCorePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {}
}
