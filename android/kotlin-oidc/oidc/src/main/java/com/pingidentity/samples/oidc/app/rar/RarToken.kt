/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.rar

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.pingidentity.oidc.AuthorizationDetail
import com.pingidentity.oidc.Token
import com.pingidentity.samples.oidc.app.json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive

/**
 * The RAR Access Token screen: shows the token the RAR client holds plus a "Granted
 * Authorization Details" card listing the `authorization_details` the server granted for it
 * (RFC 9396 §7), with a button that revokes the RAR token only.
 */
@Composable
fun RarToken(rarTokenViewModel: RarTokenViewModel = viewModel<RarTokenViewModel>()) {
    val state by rarTokenViewModel.state.collectAsState()

    LaunchedEffect(true) {
        // Not relaunched on recomposition.
        rarTokenViewModel.accessToken()
    }

    Column(
        modifier =
            Modifier
                .fillMaxWidth()
                .padding(8.dp)
                .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Card(
            elevation = CardDefaults.cardElevation(defaultElevation = 10.dp),
            modifier = Modifier.fillMaxWidth(),
            border = BorderStroke(2.dp, Color.Black),
            shape = MaterialTheme.shapes.medium,
        ) {
            Text(
                modifier = Modifier.padding(4.dp),
                text =
                    state.token?.let {
                        json.encodeToString(Token.serializer(), it)
                    }
                        ?: state.error?.toString()
                        ?: state.message
                        ?: "",
            )
        }

        state.token?.let { token ->
            GrantedDetailsCard(token)
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End,
        ) {
            Button(
                modifier = Modifier.padding(4.dp),
                onClick = { rarTokenViewModel.accessToken() },
            ) {
                Text(text = "AccessToken")
            }
            Button(
                modifier = Modifier.padding(4.dp),
                onClick = { rarTokenViewModel.revoke() },
            ) {
                Text(text = "Revoke RAR Token")
            }
            Button(
                modifier = Modifier.padding(4.dp),
                onClick = { rarTokenViewModel.reset() },
            ) {
                Text(text = "Clear")
            }
        }
    }
}

/**
 * A card that lists the RFC 9396 `authorization_details` objects the server granted for the
 * token. Renders one block per object: the standard members first, then the type-specific
 * members sorted by name, with nested JSON values pretty-printed.
 */
@Composable
private fun GrantedDetailsCard(token: Token) {
    val details = token.authorizationDetails
    Card(
        elevation = CardDefaults.cardElevation(defaultElevation = 10.dp),
        modifier = Modifier.fillMaxWidth(),
        border = BorderStroke(2.dp, Color.Black),
        shape = MaterialTheme.shapes.medium,
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text("Granted Authorization Details", style = MaterialTheme.typography.titleMedium)
            HorizontalDivider()
            when {
                // No `authorization_details` member: the server did not process the request
                // as a Rich Authorization Request.
                details == null -> Text(
                    "The token response carried no authorization_details: the server did not " +
                        "process the request as a Rich Authorization Request.",
                    style = MaterialTheme.typography.bodySmall,
                )
                // An empty array: RAR ran, but consent granted nothing.
                details.isEmpty() -> Text(
                    "The server returned an empty authorization_details array (no details " +
                        "granted).",
                    style = MaterialTheme.typography.bodySmall,
                )
                else -> details.forEachIndexed { index, detail ->
                    if (index > 0) HorizontalDivider()
                    DetailBlock(detail)
                }
            }
        }
    }
}

@Composable
private fun DetailBlock(detail: AuthorizationDetail) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        DetailRow("Type", detail.type)
        detail.locations?.takeIf { it.isNotEmpty() }?.let {
            DetailRow("Locations", it.joinToString(", "))
        }
        detail.actions?.takeIf { it.isNotEmpty() }?.let {
            DetailRow("Actions", it.joinToString(", "))
        }
        detail.datatypes?.takeIf { it.isNotEmpty() }?.let {
            DetailRow("Datatypes", it.joinToString(", "))
        }
        detail.privileges?.takeIf { it.isNotEmpty() }?.let {
            DetailRow("Privileges", it.joinToString(", "))
        }
        detail.additionalFields.toSortedMap().forEach { (key, value) ->
            DetailRow(key, displayValue(value))
        }
    }
}

@Composable
private fun DetailRow(label: String, value: String) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(label, style = MaterialTheme.typography.labelSmall)
        Text(
            value,
            style = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace),
        )
    }
}

/**
 * The text shown for a type-specific member: strings as-is, and every other value (including
 * nested objects and arrays) as pretty-printed JSON.
 */
private fun displayValue(value: JsonElement): String =
    if (value is JsonPrimitive && value.isString) value.content
    else json.encodeToString(JsonElement.serializer(), value)
