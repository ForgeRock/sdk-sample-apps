/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.pingidentity.samples.pingonesample.R

/**
 * A surface-elevated panel containing a pairing key text field and a Pair button.
 * The Pair button is only enabled once at least 12 characters have been entered.
 *
 * @param modifier Modifier applied to the outer [Surface].
 * @param value Current text field value.
 * @param onValueChange Called when the user edits the text field.
 * @param onPair Called when the Pair button is clicked; receives the trimmed key.
 * @param isPairing When true the Pair button is disabled (pairing already in progress).
 */
@Composable
fun ManualPairingPanel(
    modifier: Modifier = Modifier,
    value: String,
    onValueChange: (String) -> Unit,
    onPair: (String) -> Unit,
    isPairing: Boolean = false,
) {
    val keyboardController = LocalSoftwareKeyboardController.current

    Surface(
        modifier = modifier.fillMaxWidth(),
        tonalElevation = 4.dp,
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
        ) {
            OutlinedTextField(
                value = value,
                onValueChange = onValueChange,
                placeholder = { Text(stringResource(R.string.qr_scanner_pairing_key_label)) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { keyboardController?.hide() }),
                colors = OutlinedTextFieldDefaults.colors(
                    unfocusedContainerColor = androidx.compose.material3.MaterialTheme.colorScheme.surface,
                    focusedContainerColor = androidx.compose.material3.MaterialTheme.colorScheme.surface,
                ),
            )
            Spacer(modifier = Modifier.height(8.dp))
            Button(
                onClick = {
                    keyboardController?.hide()
                    onPair(value.trim())
                },
                enabled = value.trim().length >= 12 && !isPairing,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.qr_scanner_pair_button))
            }
        }
    }
}
