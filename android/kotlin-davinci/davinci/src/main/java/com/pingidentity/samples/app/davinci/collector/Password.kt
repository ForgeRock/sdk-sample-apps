/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import com.pingidentity.davinci.collector.PasswordCollector

/**
 * The password field.
 *
 * @param field The password collector.
 * @param onNodeUpdated The callback to be called when the current node is updated.
 */
@Composable
fun Password(
    field: PasswordCollector,
    onNodeUpdated: () -> Unit,
) {

    var isValid by remember(field) {
        mutableStateOf(true)
    }
    var verify by remember(field) { mutableStateOf("") }
    var password by remember(field) { mutableStateOf(field.value) }


    LaunchedEffect(field) {
        verify = ""
    }

    Row(
        modifier =
        Modifier
            .padding(4.dp)
            .fillMaxWidth(),
    ) {
        var passwordVisibility by remember { mutableStateOf(false) }

        Spacer(modifier = Modifier.weight(1f, true))

        OutlinedTextField(
            modifier = Modifier.wrapContentWidth(Alignment.CenterHorizontally),
            value = password,
            onValueChange = { value ->
                password = value
                field.value = value
                isValid = field.validate().isEmpty()
            },
            isError = !isValid,
            supportingText = if (!isValid) {
                @Composable {
                    ErrorMessage(field.validate())
                }
            } else null,
            label = {
                androidx.compose.material3.Text(
                    text = if (field.required) "${field.label}*" else field.label
                )
            },
            trailingIcon = {
                IconButton(onClick = { passwordVisibility = !passwordVisibility }) {
                    if (passwordVisibility) {
                        Icon(Icons.Filled.Visibility, contentDescription = null)
                    } else {
                        Icon(Icons.Filled.VisibilityOff, contentDescription = null)
                    }
                }
            },
            keyboardOptions =
            KeyboardOptions(
                keyboardType = KeyboardType.Password,
            ),
            visualTransformation =
            if (passwordVisibility) {
                VisualTransformation.None
            } else {
                PasswordVisualTransformation()
            },
        )

        Spacer(modifier = Modifier.weight(1f, true))
    }

    if (field.type == "PASSWORD_VERIFY") {

        Row(
            modifier =
            Modifier
                .padding(4.dp)
                .fillMaxWidth(),
        ) {
            var passwordVisibility by remember(field) { mutableStateOf(false) }


            Spacer(modifier = Modifier.weight(1f, true))

            OutlinedTextField(
                modifier = Modifier.wrapContentWidth(Alignment.CenterHorizontally),
                value = verify,
                onValueChange = { value ->
                    verify = value
                },
                isError = verify != field.value,
                supportingText = if (verify != field.value) {
                    @Composable {
                        androidx.compose.material3.Text(
                            text = "Password does not match",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                } else null,
                label = {
                    androidx.compose.material3.Text(
                        text = if (field.required) "${field.label}*" else field.label
                    )
                },
                trailingIcon = {
                    IconButton(onClick = { passwordVisibility = !passwordVisibility }) {
                        if (passwordVisibility) {
                            Icon(Icons.Filled.Visibility, contentDescription = null)
                        } else {
                            Icon(Icons.Filled.VisibilityOff, contentDescription = null)
                        }
                    }
                },
                keyboardOptions =
                KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                ),
                visualTransformation =
                if (passwordVisibility) {
                    VisualTransformation.None
                } else {
                    PasswordVisualTransformation()
                },
            )

            Spacer(modifier = Modifier.weight(1f, true))
        }
    }
}