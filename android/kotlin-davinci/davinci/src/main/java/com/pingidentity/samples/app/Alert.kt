/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.pingidentity.davinci.module.details
import com.pingidentity.orchestrate.ErrorNode

@Composable
fun Alert(throwable: Throwable) {

    var showConfirmation by remember {
        mutableStateOf(true)
    }

    if (showConfirmation) {
        AlertDialog(
            onDismissRequest = { showConfirmation = false },
            confirmButton = {},
            dismissButton = {
                TextButton(onClick = { showConfirmation = false })
                { Text(text = "Ok") }
            },
            text = {
                Text(text = throwable.toString())
            }
        )
    }
}

@Composable
fun Alert(node: ErrorNode, onDismissRequest: () -> Unit) {
    var showConfirmation by remember {
        mutableStateOf(true)
    }

    var error = ""
    node.details().forEach {
        it.rawResponse.let { rawResponse ->
            rawResponse.details?.forEach { detail ->
                error += ("${detail.message}\n\n")
                detail.innerError?.errors?.forEach { (key, value) ->
                    error += ("$key: $value\n\n")
                }
            }
        }
    }

    if (showConfirmation) {
        AlertDialog(
            onDismissRequest = {
                showConfirmation = false
                onDismissRequest()
            },
            confirmButton = {},
            dismissButton = {
                TextButton(onClick = {
                    showConfirmation = false
                    onDismissRequest()
                })
                { Text(text = "Ok") }
            },
            text = {
                Text(text = error)
            }
        )
    }
}