/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation

/// Central place to hold process-wide registries used by the core module.
///
/// Keeps native handles alive across calls from the Flutter bridge. Every future native module
/// (oidc, davinci, storage, ...) shares this same type, so it must live in `ping_core` rather
/// than in any single feature plugin.
public enum CoreRuntime {
    /// Registry for Journey client instances.
    public static let journeyRegistry: Registry = SimpleRegistry()
}
