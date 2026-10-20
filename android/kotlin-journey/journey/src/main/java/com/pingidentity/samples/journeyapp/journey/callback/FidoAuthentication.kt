/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import android.util.Log
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.fido.FidoPendingAuthentication
import com.pingidentity.fido.FidoPendingAuthenticationCancelledException
import com.pingidentity.fido.isConditionalMediationSupported
import com.pingidentity.fido.journey.FidoAuthenticationCallback
import kotlinx.coroutines.launch

/**
 * Renders the FIDO conditional-mediation passkey support for a Journey node: creates the
 * pending request (published via [onPending] so the regular username field can attach it)
 * and provides the modal fallback button. This composable renders **no** username field of
 * its own — the passkey suggestions surface inline on the regular field marked with
 * autocompleteValues ["username","webauthn"] by the server.
 *
 * @param hasConditionalTarget Whether a sibling NameCallback on this node is marked as the
 *   passkey target ("webauthn" in autocompleteValues). When false there is no field to attach
 *   the pending request to, so it is not created.
 */
@Composable
fun FidoAuthentication(
    callback: FidoAuthenticationCallback,
    onNext: () -> Unit,
    onPending: (FidoPendingAuthentication?) -> Unit,
    pending: FidoPendingAuthentication?,
    hasConditionalTarget: Boolean,
) {
    val currentOnCompleted by rememberUpdatedState(onNext)
    val coroutineScope = rememberCoroutineScope()

    // One modal ceremony at a time: repeated taps while a ceremony runs would start
    // overlapping ceremonies that can both publish pending requests and both submit the
    // node. The button is disabled for the duration.
    var modalInProgress by remember { mutableStateOf(false) }

    // Modal ceremony (Credential Manager routing — see the routing note at the button) with
    // post-failure recovery: on failure the user stays on the page and, when a conditional
    // target exists, a fresh pending request replaces the one the modal superseded, so
    // passkey autofill on the username field keeps working after a failed attempt.
    val performModalAuthentication: suspend () -> Unit = {
        modalInProgress = true
        try {
            callback.authenticate { useFido2ApiClient = false }
                .onSuccess { currentOnCompleted() }
                .onFailure {
                    Log.e(
                        "Fido2Authentication",
                        "Failed to Authenticate",
                        it
                    )
                    if (hasConditionalTarget) {
                        callback.pendingAuthenticate { useFido2ApiClient = false }
                            .onSuccess { onPending(it) }
                            .onFailure { retryError ->
                                Log.e(
                                    "Fido2Authentication",
                                    "Failed to re-create pending request",
                                    retryError
                                )
                                onPending(null)
                                // With the button disabled there is nothing left on the node
                                // (no button, Next hidden, no autofill) — submit the error
                                // outcome handleError already wrote, like the unsupported-OS
                                // branch does.
                                if (!callback.manualButtonEnabled) currentOnCompleted()
                            }
                    }
                }
        } finally {
            modalInProgress = false
        }
    }

    if (isConditionalMediationSupported && (hasConditionalTarget || callback.manualButtonEnabled)) {
        if (hasConditionalTarget) {
            // Build the pending request up front; the username field's composable attaches it
            // to the regular field, so suggestions appear when the user focuses it. If setup
            // fails, fall back to the modal flow below (createPending nulls `pending` via
            // onPending(null)) — otherwise a node without manualButtonEnabled would have no
            // authentication action at all, since ContinueNode hides Next for this callback.
            LaunchedEffect(callback) {
                callback.pendingAuthenticate { useFido2ApiClient = false }
                    .onSuccess { onPending(it) }
                    .onFailure {
                        Log.e(
                            "Fido2Authentication",
                            "Failed to create pending request",
                            it
                        )
                        onPending(null)
                        if (!callback.manualButtonEnabled) {
                            performModalAuthentication()
                        }
                    }
            }

            // Deliver the outcome when the user picks a suggestion. A dismissed suggestion
            // sheet never completes the await, and lifecycle cancellations (dispose,
            // supersede) leave the node as-is — the modal fallback below stays visible for
            // the dismissed case. Any *other* failure means the SDK has already recorded the
            // error outcome but nothing would advance the node (Next is hidden for this
            // callback), so submit to keep the journey moving.
            LaunchedEffect(pending) {
                val result = pending?.await() ?: return@LaunchedEffect
                result.onSuccess {
                    currentOnCompleted()
                }.onFailure {
                    Log.e(
                        "Fido2Authentication",
                        "Pending authentication failed",
                        it
                    )
                    if (it !is FidoPendingAuthenticationCancelledException) {
                        currentOnCompleted()
                    }
                }
            }
        }

        // Modal fallback: covers dismissed suggestions and failed/pending-setup-failed
        // conditional starts. Shown only when the server's WebAuthn node has
        // "Authentication Button" enabled (manualButtonEnabled). A failed modal attempt (e.g.
        // a transient Google Play services disconnection) keeps the user on the page — but
        // authenticate() superseded the attached pending request (the SDK cancels it before
        // the modal ceremony), so a fresh pending request is published on failure: without
        // it the EditText would hold a cancelled request whose ceremony response is dropped,
        // and passkey autofill on the field would silently stop working.
        //
        // Routing: this journey is the conditional-UI one — the payload carries no rpId
        // (_relyingPartyId is empty) and no allowCredentials, which the Google Play Services
        // FIDO2 API requires (its process crashes on the empty rpId, surfacing as a GMS
        // connection suspension / ApiException 20). The modal button therefore forces the
        // Credential Manager path, which handles the empty rpId correctly.
        if (callback.manualButtonEnabled) {
            Button(
                modifier = Modifier.padding(4.dp),
                enabled = !modalInProgress,
                onClick = {
                    coroutineScope.launch {
                        performModalAuthentication()
                    }
                }
            ) {
                Text("Use a passkey")
            }
        }
    } else {
        // No conditional surface usable on this node (unsupported OS, or neither a marked
        // username field nor the manual button): launch the modal ceremony directly so the
        // node stays reachable.
        Box(
            modifier = Modifier
                .fillMaxSize()
                .wrapContentSize(Alignment.Center)
        ) {
            CircularProgressIndicator()
            LaunchedEffect(true) {
                launch {
                    callback.authenticate().onSuccess {
                        currentOnCompleted()
                    }.onFailure {
                        Log.e(
                            "Fido2Authentication",
                            "Failed to Authenticate",
                            it
                        )
                        currentOnCompleted()
                    }
                }
            }
        }
    }
}
