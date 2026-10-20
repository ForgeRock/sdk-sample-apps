/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import android.util.Log
import android.view.LayoutInflater
import android.view.ViewTreeObserver
import android.view.autofill.AutofillManager
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.view.doOnAttach
import androidx.core.view.doOnDetach
import androidx.core.widget.doOnTextChanged
import androidx.credentials.pendingGetCredentialRequest
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import com.pingidentity.fido.FidoPendingAuthentication
import com.pingidentity.journey.callback.NameCallback
import com.pingidentity.samples.journeyapp.R

/**
 * Renders the regular username field. When the server marks the field for conditional
 * mediation (autocompleteValues contains "webauthn"), the field is rendered View-backed —
 * the androidx pendingGetCredentialRequest is View-only — and carries the pending passkey
 * request, so suggestions surface inline on this regular field with no separate username view.
 */
@Composable
fun NameCallback(
    field: NameCallback,
    onNodeUpdated: () -> Unit,
    pending: FidoPendingAuthentication? = null,
) {

    var text by remember(field) { mutableStateOf(field.name) }

    // WebAuthn conditional mediation is a View-only androidx API (pendingGetCredentialRequest):
    // when the server marks this field as the passkey target, render it from a View layout
    // inflated through Material's normal XML path (programmatic construction collapses).
    if (field.autocompleteValues.contains("webauthn")) {
        Row(
            modifier =
                Modifier
                    .padding(4.dp)
                    .fillMaxWidth(),
        ) {
            Spacer(modifier = Modifier.weight(1f, true))

            key(field) {
                AndroidView(
                    modifier = Modifier.width(280.dp),
                    factory = { context ->
                        LayoutInflater.from(context)
                            .inflate(R.layout.view_webauthn_username_field, null, false)
                            .also { layout ->
                                layout.findViewById<TextInputEditText>(
                                    R.id.webauthn_username_edit
                                ).apply {
                                    setText(text)
                                    doOnTextChanged { value, _, _, _ ->
                                        text = value?.toString().orEmpty()
                                        field.name = text
                                        onNodeUpdated()
                                    }
                                    // Re-arm passkey autofill when the window regains focus
                                    // while this field is focused. Registered on attach and
                                    // removed on detach: the listener holds the detached
                                    // EditText, so leaving it registered on the window's
                                    // shared ViewTreeObserver (key(field) recreates this view
                                    // for every new node) would leak it and let a stale
                                    // listener postDelayed onto a dead view.
                                    var pendingRunnable: Runnable? = null
                                    val focusListener =
                                        object : ViewTreeObserver.OnWindowFocusChangeListener {
                                            override fun onWindowFocusChanged(
                                                hasFocus: Boolean,
                                            ) {
                                                // Only when the app window gains focus back AND
                                                // this field is (still) the focused view.
                                                if (!hasFocus || !isFocused) return
                                                pendingRunnable = Runnable {
                                                    Log.d(
                                                        "FidoRearm",
                                                        "re-arm: clear+set request, " +
                                                                "requestAutofill",
                                                    )
                                                    context.getSystemService(
                                                        AutofillManager::class.java
                                                    )?.let { afm ->
                                                        afm.cancel()
                                                        afm.requestAutofill(this@apply)
                                                    }
                                                }
                                                postDelayed(pendingRunnable, 300)
                                            }
                                        }
                                    doOnAttach {
                                        it.viewTreeObserver
                                            .addOnWindowFocusChangeListener(focusListener)
                                    }
                                    doOnDetach { view ->
                                        view.viewTreeObserver
                                            .removeOnWindowFocusChangeListener(focusListener)
                                        pendingRunnable?.let(view::removeCallbacks)
                                    }
                                }
                                layout.findViewById<TextInputLayout>(
                                    R.id.webauthn_username_layout
                                ).hint = field.prompt
                            }
                    },
                    update = { layout ->
                        layout.findViewById<TextInputEditText>(R.id.webauthn_username_edit)
                            .pendingGetCredentialRequest = pending?.request
                    },
                )
            }
            Spacer(modifier = Modifier.weight(1f, true))
        }
    } else {
        Row(
            modifier =
                Modifier
                    .padding(4.dp)
                    .fillMaxWidth(),
        ) {
            Spacer(modifier = Modifier.weight(1f, true))

            OutlinedTextField(
                modifier = Modifier.wrapContentWidth(Alignment.CenterHorizontally),
                value = text,
                onValueChange = { value ->
                    text = value
                    field.name = value
                    onNodeUpdated()
                },
                label = { Text(field.prompt) },
            )
            Spacer(modifier = Modifier.weight(1f, true))
        }
    }
}
