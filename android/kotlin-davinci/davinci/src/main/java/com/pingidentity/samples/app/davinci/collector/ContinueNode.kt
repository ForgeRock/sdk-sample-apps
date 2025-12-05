/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.DeviceAuthenticationCollector
import com.pingidentity.davinci.collector.DeviceRegistrationCollector
import com.pingidentity.davinci.collector.FlowCollector
import com.pingidentity.davinci.collector.LabelCollector
import com.pingidentity.davinci.collector.MultiSelectCollector
import com.pingidentity.davinci.collector.PasswordCollector
import com.pingidentity.davinci.collector.PhoneNumberCollector
import com.pingidentity.davinci.collector.SingleSelectCollector
import com.pingidentity.davinci.collector.SubmitCollector
import com.pingidentity.davinci.collector.TextCollector
import com.pingidentity.davinci.module.description
import com.pingidentity.davinci.module.name
import com.pingidentity.davinci.plugin.Submittable
import com.pingidentity.davinci.plugin.collectors
import com.pingidentity.idp.davinci.IdpCollector
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.protect.davinci.ProtectCollector

/**
 * The continue node.
 *
 * @param continueNode The continue node to render.
 * @param onNodeUpdated The callback to be called when the current node is updated.
 * @param onNext The callback to be called when the next node is triggered.
 */
@Composable
fun ContinueNode(
    continueNode: ContinueNode,
    onNodeUpdated: () -> Unit,
    onStart: () -> Unit,
    onNext: () -> Unit,
) {
    Row(
        modifier =
            Modifier
                .padding(4.dp)
                .fillMaxWidth()
    ) {
        Spacer(Modifier.width(8.dp))
        Text(
            text = continueNode.name,
            Modifier
                .wrapContentWidth(Alignment.CenterHorizontally)
                .weight(1f),
            fontWeight = FontWeight.Bold,
            style = MaterialTheme.typography.titleLarge,
        )
    }
    Row(
        modifier =
            Modifier
                .padding(4.dp)
                .fillMaxWidth(),
    ) {
        Spacer(Modifier.width(8.dp))
        Text(
            text = continueNode.description,
            Modifier
                .wrapContentWidth(Alignment.CenterHorizontally)
                .weight(1f),
            style = MaterialTheme.typography.titleSmall,
        )
    }

    Column(
        modifier =
            Modifier
                .padding(4.dp)
                .fillMaxWidth(),
    ) {
        var hasAction = false

        continueNode.collectors.forEach {
            when (it) {
                is FlowCollector -> FlowButton(it, onNext)
                is PasswordCollector -> Password(it, onNodeUpdated)
                is SubmitCollector -> SubmitButton(it, onNext)
                is TextCollector -> Text(it, onNodeUpdated)
                is LabelCollector -> Label(it)
                is MultiSelectCollector -> {
                    if (it.type == "COMBOBOX") {
                        ComboBox(it, onNodeUpdated)
                    } else {
                        CheckBox(it, onNodeUpdated)
                    }
                }

                is SingleSelectCollector -> {
                    if (it.type == "DROPDOWN") {
                        Dropdown(it, onNodeUpdated)
                    } else {
                        Radio(it, onNodeUpdated)
                    }
                }

                is IdpCollector -> SocialLoginButton(it, onStart, onNext)
                is DeviceRegistrationCollector -> DeviceRegistration(it, onNext)
                is DeviceAuthenticationCollector -> DeviceAuthentication(it, onNext)
                is PhoneNumberCollector -> PhoneNumber(it, onNodeUpdated)
                is ProtectCollector -> Protect(it, onNodeUpdated)

            }
            if (it is Submittable) {
                hasAction = true
            }
        }

        if (!hasAction) {
            Button(
                modifier = Modifier.align(Alignment.End),
                onClick = onNext,
            ) {
                Text("Next")
            }
        }
    }
}

