/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingBrowser
import PingOidc
import ping_core

/// Wraps a live native `OidcWebClient` so it can be stored in
/// `CoreRuntime.oidcWebClientRegistry`. Unlike `OidcClientHandle`, this handle doesn't conform to
/// `ping_core`'s `OidcConfigHandle` — the config-handle contract is served by the client handle
/// that `create` resolves from, not by the web client itself.
final class OidcWebClientHandle: NativeHandle, @unchecked Sendable {
    let webClient: OidcWebClient

    init(webClient: OidcWebClient) {
        self.webClient = webClient
    }
}

/// Builds a native `OidcWebClient` from the flat payload of an already-registered
/// `OidcClientHandle` and registers it in `CoreRuntime.oidcWebClientRegistry`.
///
/// The web client is built fresh from `OidcClientHandle.payload` rather than reusing
/// `OidcClientHandle.client` — neither native SDK's web-client config supports wrapping/cloning a
/// live client (confirmed by reading `OidcWebClient.swift`/`OidcWebClientConfig`: it's a bare
/// `WorkflowConfig` unrelated to `OidcClientConfig`, populated only via a second
/// `config.module(OidcModule.config) { }` call inside `createOidcWebClient`'s block).
enum OidcWebClientFactory {
    static func create(clientHandleId: String, options: BrowserOptionsMessage?) async throws -> String {
        guard
            let handle = await CoreRuntime.oidcClientRegistry.resolve(clientHandleId) as? OidcClientHandle
        else {
            throw OidcHostApiError.stateError(
                "OIDC client instance not found for id=\(clientHandleId)"
            )
        }

        var applyError: Error?
        let webClient = OidcWebClient.createOidcWebClient { config in
            if let browserType = options?.browserType {
                switch browserType {
                case "authSession": config.browserType = .authSession
                case "ephemeralAuthSession": config.browserType = .ephemeralAuthSession
                default:
                    // `.nativeBrowserApp`/`.sfViewController` are declared but not implemented at
                    // 2.1.0 (`Browser/README.md`) — reject rather than silently no-op.
                    applyError = OidcHostApiError.argumentError(
                        "Unsupported browserType on iOS: \(browserType)"
                    )
                    return
                }
            }
            if let browserMode = options?.browserMode {
                switch browserMode {
                case "login": config.browserMode = .login
                case "logout": config.browserMode = .logout
                case "custom": config.browserMode = .custom
                default:
                    applyError = OidcHostApiError.argumentError(
                        "Unsupported browserMode on iOS: \(browserMode)"
                    )
                    return
                }
            }
            config.module(OidcModule.config) { oidcConfig in
                OidcConfigParser.apply(oidcConfig, from: handle.payload)
            }
        }
        if let applyError { throw applyError }

        return await CoreRuntime.oidcWebClientRegistry.register(OidcWebClientHandle(webClient: webClient))
    }
}
