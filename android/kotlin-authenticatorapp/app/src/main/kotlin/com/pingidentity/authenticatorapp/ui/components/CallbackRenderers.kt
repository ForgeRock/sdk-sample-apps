/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import com.pingidentity.journey.callback.NameCallback
import com.pingidentity.journey.callback.PasswordCallback
import com.pingidentity.journey.callback.TextInputCallback
import com.pingidentity.journey.callback.TextOutputCallback
import com.pingidentity.journey.plugin.callbacks
import com.pingidentity.orchestrate.ContinueNode

/**
 * Composable that renders a ContinueNode with its callbacks
 */
@Composable
fun ContinueNodeRenderer(
    node: ContinueNode,
    onNodeUpdated: () -> Unit,
    onNext: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Render each callback
        node.callbacks.forEach { callback ->
            when (callback) {
                is NameCallback -> {
                    NameCallbackRenderer(
                        callback = callback,
                        onValueChanged = onNodeUpdated
                    )
                }
                is PasswordCallback -> {
                    PasswordCallbackRenderer(
                        callback = callback,
                        onValueChanged = onNodeUpdated
                    )
                }
                is TextInputCallback -> {
                    TextInputCallbackRenderer(
                        callback = callback,
                        onValueChanged = onNodeUpdated
                    )
                }
                is TextOutputCallback -> {
                    TextOutputCallbackRenderer(callback = callback)
                }
                else -> {
                    // For unhandled callbacks, show basic info
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant
                        )
                    ) {
                        Text(
                            text = "Callback: ${callback.javaClass.simpleName}",
                            modifier = Modifier.padding(16.dp),
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }
        }
        
        // Next button
        Button(
            onClick = onNext,
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 16.dp)
        ) {
            Text("Next")
        }
    }
}

/**
 * Renders a NameCallback (username input)
 */
@Composable
private fun NameCallbackRenderer(
    callback: NameCallback,
    onValueChanged: () -> Unit
) {
    var textValue by remember(callback) { mutableStateOf(callback.name) }
    
    OutlinedTextField(
        value = textValue,
        onValueChange = { value ->
            textValue = value
            callback.name = value
            onValueChanged()
        },
        label = { Text(callback.prompt) },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true
    )
}

/**
 * Renders a PasswordCallback (password input)
 */
@Composable
private fun PasswordCallbackRenderer(
    callback: PasswordCallback,
    onValueChanged: () -> Unit
) {
    var passwordVisibility by remember { mutableStateOf(false) }
    var passwordValue by remember(callback) { mutableStateOf(callback.password) }
    
    OutlinedTextField(
        value = passwordValue,
        onValueChange = { value ->
            passwordValue = value
            callback.password = value
            onValueChanged()
        },
        label = { Text(callback.prompt) },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true,
        visualTransformation = if (passwordVisibility) {
            VisualTransformation.None
        } else {
            PasswordVisualTransformation()
        },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
        trailingIcon = {
            IconButton(onClick = { passwordVisibility = !passwordVisibility }) {
                Icon(
                    imageVector = if (passwordVisibility) {
                        Icons.Default.Visibility
                    } else {
                        Icons.Default.VisibilityOff
                    },
                    contentDescription = if (passwordVisibility) {
                        "Hide password"
                    } else {
                        "Show password"
                    }
                )
            }
        }
    )
}

/**
 * Renders a TextInputCallback (generic text input)
 */
@Composable
private fun TextInputCallbackRenderer(
    callback: TextInputCallback,
    onValueChanged: () -> Unit
) {
    var textValue by remember(callback) { mutableStateOf(callback.text) }
    
    OutlinedTextField(
        value = textValue,
        onValueChange = { value ->
            textValue = value
            callback.text = value
            onValueChanged()
        },
        label = { Text(callback.prompt) },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true
    )
}

/**
 * Renders a TextOutputCallback (display text)
 */
@Composable
private fun TextOutputCallbackRenderer(
    callback: TextOutputCallback
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Text(
            text = callback.message,
            modifier = Modifier.padding(16.dp),
            style = MaterialTheme.typography.bodyMedium
        )
    }
}
