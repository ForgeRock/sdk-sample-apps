/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.rar

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import com.pingidentity.oidc.AuthorizationDetail
import com.pingidentity.oidc.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * How the `authorization_details` reach the authorization server for a login.
 * - [PER_TRANSACTION]: sent for the current login only, through
 *   `Parameters.authorizationDetails(...)`.
 * - [CLIENT_CONFIG]: fixed when the client is built, through
 *   `OidcClientConfig.authorizationDetails`. A per-transaction value takes precedence over a
 *   config-level one.
 */
enum class Delivery(val displayName: String) {
    PER_TRANSACTION("Per transaction"),
    CLIENT_CONFIG("Client config"),
}

/** The outcome of one RAR login attempt. */
sealed interface RarLoginState {
    /** The login completed; [user] holds the authenticated RAR user. */
    data class Success(val user: User) : RarLoginState

    /** The login failed; [error] carries the cause, displayed through `displayMessage()`. */
    data class Failure(val error: Throwable) : RarLoginState
}

/**
 * A view model that manages the OIDC login flow with RFC 9396 `authorization_details`.
 * - Responsible for:
 *   - Validating the edited `authorization_details` JSON
 *   - Applying the PAR flag and the delivery choice to [RarClientStore] before a login
 *   - Running the authorization with the dedicated RAR client
 *   - Managing authentication state (success/failure) and the loading state
 */
class RarLoginViewModel : ViewModel() {

    /** The preset currently selected as the editor's starting point. */
    val preset = MutableStateFlow(RarPreset.PAYMENT_INITIATION)

    /** The `authorization_details` JSON the user is editing. */
    val jsonText = MutableStateFlow(RarPreset.PAYMENT_INITIATION.json)

    /** Live validation message for the editor text (`null` when the text is valid or empty). */
    val validationError = MutableStateFlow<String?>(null)

    /**
     * The number of `authorization_details` objects the editor text currently decodes to, or
     * `null` when the text is empty or invalid. Updated once per text change so composition
     * never parses the editor text.
     */
    val validDetailsCount = MutableStateFlow<Int?>(null)

    /** Whether the authorization parameters are pushed to the server first (RFC 9126). */
    val parEnabled = MutableStateFlow(false)

    /** Whether the edited details are sent per transaction or fixed on the client config. */
    val delivery = MutableStateFlow(Delivery.PER_TRANSACTION)

    /** Sets the PAR flag, applied to the RAR client when the next login starts. */
    fun setPar(enabled: Boolean) {
        parEnabled.value = enabled
    }

    /** Sets the delivery path for the `authorization_details`. */
    fun setDelivery(value: Delivery) {
        delivery.value = value
    }

    /** The outcome of the last login attempt, or `null` when the editor is shown. */
    private val _state = MutableStateFlow<RarLoginState?>(null)
    val state = _state.asStateFlow()

    /** Whether an authorization is currently running. */
    val isLoading = MutableStateFlow(false)

    init {
        // The editor opens with a valid preset; compute its count so the login button is
        // enabled and the "Valid" hint shows before the first keystroke.
        validDetailsCount.value = runCatching {
            RarJson.decode(RarPreset.PAYMENT_INITIATION.json)
        }.getOrNull()?.size
    }

    /** Loads the selected preset's JSON into the editor and revalidates it. */
    fun selectPreset(preset: RarPreset) {
        this.preset.value = preset
        updateJsonText(preset.json)
    }

    /** Replaces the editor text and revalidates it. */
    fun updateJsonText(text: String) {
        jsonText.value = text
        if (text.trim().isEmpty()) {
            validationError.value = null
            validDetailsCount.value = null
            return
        }
        // Decode once per text change: both the validation message and the count derive
        // from this single parse.
        val result = runCatching { RarJson.decode(text) }
        validDetailsCount.value = result.getOrNull()?.size
        validationError.value =
            result.exceptionOrNull()?.let { it.message ?: it.toString() }
    }

    /** Clears the last login outcome so the screen shows the editor again.
     * The edited JSON, the PAR flag and the delivery choice are kept. */
    fun resetState() {
        _state.value = null
    }

    /**
     * Starts the OIDC login with the edited `authorization_details`.
     *
     * Applies the current PAR flag and delivery choice to [RarClientStore] first, which
     * rebuilds the client when they changed, then runs the authorization. With
     * [Delivery.CLIENT_CONFIG] the details are set on the client configuration; with
     * [Delivery.PER_TRANSACTION] they are passed through the `authorize` parameters block.
     */
    fun login() {
        // Re-entrancy guard: a double-tap can land before recomposition disables the button,
        // and two concurrent authorizations would race over the same token storage.
        if (isLoading.value) return

        val details = validate() ?: return

        isLoading.value = true
        viewModelScope.launch {
            try {
                // Only flags and `type` values are logged, never the payload or the editor text.
                Logger.STANDARD.i(
                    "RAR login: PAR ${parEnabled.value}, " +
                        "delivery ${delivery.value.displayName}, " +
                        "authorization_details types: ${details.joinToString(", ") { it.type }}"
                )

                RarClientStore.apply(
                    RarClientOptions(
                        par = parEnabled.value,
                        authorizationDetails =
                            if (delivery.value == Delivery.CLIENT_CONFIG) details else null,
                    )
                )
                val perTransaction =
                    if (delivery.value == Delivery.PER_TRANSACTION) details else null

                val result = RarClientStore.client.authorize {
                    perTransaction?.let { authorizationDetails(it) }
                }
                result.fold(
                    onSuccess = { user ->
                        _state.update { RarLoginState.Success(user) }
                    },
                    onFailure = { throwable ->
                        _state.update { RarLoginState.Failure(throwable) }
                    },
                )
            } finally {
                isLoading.value = false
            }
        }
    }

    /**
     * Validates the editor text and records the outcome in [validationError] for display.
     *
     * @return The decoded details, or `null` when the text is empty or invalid.
     */
    private fun validate(): List<AuthorizationDetail>? {
        val trimmed = jsonText.value.trim()
        if (trimmed.isEmpty()) {
            validationError.value = null
            return null
        }
        return try {
            val details = RarJson.decode(trimmed)
            validationError.value = null
            details
        } catch (e: RarDecodeException) {
            validationError.value = e.message
            null
        }
    }
}
