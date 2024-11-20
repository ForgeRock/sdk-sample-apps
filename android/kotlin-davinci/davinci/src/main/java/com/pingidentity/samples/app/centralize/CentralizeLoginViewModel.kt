/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.centralize

import androidx.browser.customtabs.CustomTabsIntent
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.utils.Result
import com.pingidentity.oidc.OidcClient
import com.pingidentity.oidc.agent.browser
import com.pingidentity.samples.app.Mode
import com.pingidentity.samples.app.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import net.openid.appauth.browser.BrowserDenyList
import net.openid.appauth.browser.VersionedBrowserMatcher

val ping =
    OidcClient {

        updateAgent(browser) {
            customTab = {
                setColorScheme(CustomTabsIntent.COLOR_SCHEME_LIGHT)
                setShowTitle(false)
                setShareState(CustomTabsIntent.SHARE_STATE_OFF)
                setUrlBarHidingEnabled(true)
            }
            appAuthConfiguration = {
                setBrowserMatcher(
                    BrowserDenyList(
                        VersionedBrowserMatcher.FIREFOX_CUSTOM_TAB,
                        //VersionedBrowserMatcher.CHROME_CUSTOM_TAB,
                        //VersionedBrowserMatcher.CHROME_BROWSER
                    )
                )
            }
        }

        clientId = "c12743f9-08e8-4420-a624-71bbb08e9fe1"
        discoveryEndpoint =
            "https://auth.pingone.ca/02fb4743-189a-4bc7-9d6c-a919edfe6447/as/.well-known/openid-configuration"
        scopes = mutableSetOf("openid", "email", "address")
        // Make sure adding the redirectUri to the Signoff URLs console
        redirectUri = "com.pingidentity.demo://oauth2redirect"
        //signOutRedirectUri = "com.pingidentity.demo://oauth2redirect"
    }

val pingTest =
    OidcClient {

        updateAgent(browser)
        clientId = "3172d977-8fdc-4e8b-b3c5-4f3a34cb7262"
        discoveryEndpoint =
            "https://auth.test-one-pingone.com/0c6851ed-0f12-4c9a-a174-9b1bf8b438ae/as/.well-known/openid-configuration"
        scopes = mutableSetOf("openid", "email", "address")
        // Make sure adding the redirectUri to the Signoff URLs console
        redirectUri = "com.pingidentity.demo://oauth2redirect"
        //signOutRedirectUri = "com.pingidentity.demo://oauth2redirect"
    }


val forgerock =
    OidcClient {

        updateAgent(browser) {
            customTab = {
                setColorScheme(CustomTabsIntent.COLOR_SCHEME_LIGHT)
                setShowTitle(false)
                setUrlBarHidingEnabled(true)
            }
        }

        discoveryEndpoint =
            "https://openam-sdks.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"
        clientId = "AndroidTest"
        redirectUri = "org.forgerock.demo:/oauth2redirect"
        scopes = mutableSetOf("openid", "email", "address", "profile", "phone")

    }

val oidcClient = ping

class CentralizeLoginViewModel : ViewModel() {
    var state = MutableStateFlow(CentralizeState())
        private set

    fun login() {
        viewModelScope.launch {
            User.current(Mode.CENTRALIZE)
            when (val result = oidcClient.token()) {
                is Result.Failure -> {
                    state.update {
                        it.copy(token = null, error = result.value)
                    }
                }

                is Result.Success -> {
                    state.update {
                        it.copy(token = result.value, error = null)
                    }
                }
            }
        }
    }

    fun reset() {
        state.update {
            it.copy(null, null)
        }
    }
}
