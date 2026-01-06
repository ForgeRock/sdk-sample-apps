/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.pingidentity.device.binding.journey.DeviceBindingCallback
import com.pingidentity.device.binding.journey.DeviceSigningVerifierCallback
import com.pingidentity.device.profile.DeviceProfileCallback
import com.pingidentity.fido.journey.FidoAuthenticationCallback
import com.pingidentity.fido.journey.FidoRegistrationCallback
import com.pingidentity.idp.journey.IdpCallback
import com.pingidentity.idp.journey.SelectIdpCallback
import com.pingidentity.journey.callback.BooleanAttributeInputCallback
import com.pingidentity.journey.callback.ChoiceCallback
import com.pingidentity.journey.callback.ConfirmationCallback
import com.pingidentity.journey.callback.ConsentMappingCallback
import com.pingidentity.journey.callback.KbaCreateCallback
import com.pingidentity.journey.callback.NameCallback
import com.pingidentity.journey.callback.NumberAttributeInputCallback
import com.pingidentity.journey.callback.PasswordCallback
import com.pingidentity.journey.callback.PollingWaitCallback
import com.pingidentity.journey.callback.StringAttributeInputCallback
import com.pingidentity.journey.callback.SuspendedTextOutputCallback
import com.pingidentity.journey.callback.TermsAndConditionsCallback
import com.pingidentity.journey.callback.TextInputCallback
import com.pingidentity.journey.callback.TextOutputCallback
import com.pingidentity.journey.callback.ValidatedPasswordCallback
import com.pingidentity.journey.callback.ValidatedUsernameCallback
import com.pingidentity.journey.plugin.callbacks
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.protect.journey.PingOneProtectEvaluationCallback
import com.pingidentity.protect.journey.PingOneProtectInitializeCallback
import com.pingidentity.recaptcha.enterprise.ReCaptchaEnterpriseCallback

@Composable
fun ContinueNode(
    continueNode: ContinueNode,
    onNodeUpdated: () -> Unit,
    onNext: () -> Unit,
) {
    Column(
        modifier =
            Modifier
                .padding(4.dp)
                .fillMaxWidth(),
    ) {
        var showNext = true

        continueNode.callbacks.forEach {
            when (it) {
                is BooleanAttributeInputCallback -> BooleanAttributeInputCallback(it, onNodeUpdated)
                is ChoiceCallback -> ChoiceCallback(it, onNodeUpdated)
                is ConfirmationCallback -> {
                    showNext = false
                    ConfirmationCallback(it, onNext)
                }

                is ConsentMappingCallback -> ConsentMappingCallback(it, onNodeUpdated)
                is KbaCreateCallback -> KbaCreateCallback(it, onNodeUpdated)
                is NumberAttributeInputCallback -> NumberAttributeInputCallback(it, onNodeUpdated)
                is PasswordCallback -> PasswordCallback(it, onNodeUpdated)
                is PollingWaitCallback -> PollingWaitCallback(it, onNext)
                is StringAttributeInputCallback -> StringAttributeInputCallback(it, onNodeUpdated)
                is TermsAndConditionsCallback -> {
                    TermsAndConditionsCallback(it, onNodeUpdated)
                }
                is DeviceProfileCallback -> {
                    showNext = false
                    DeviceProfileCallback(it, onNext)
                }
                is ReCaptchaEnterpriseCallback -> {
                    showNext = false
                    ReCaptchaEnterpriseCallback(it, onNext)
                }

                is TextInputCallback -> TextInputCallback(it, onNodeUpdated)
                is TextOutputCallback -> TextOutputCallback(it)
                is SuspendedTextOutputCallback -> {
                    TextOutputCallback(it)
                    showNext = false
                }

                is NameCallback -> NameCallback(it, onNodeUpdated)

                //External IdP
                is SelectIdpCallback -> SelectIdpCallback(it, onNext)
                is IdpCallback -> {
                    showNext = false
                    IdPCallback(it, onNext)
                }

                is ValidatedUsernameCallback -> ValidatedUsernameCallback(it, onNodeUpdated)
                is ValidatedPasswordCallback -> ValidatedPasswordCallback(it, onNodeUpdated)
                is PingOneProtectInitializeCallback -> {
                    PingOneProtectInitialize(it, onNext)
                    showNext = false
                }

                is PingOneProtectEvaluationCallback -> {
                    PingOneProtectEvaluation(it, onNext)
                    showNext = false
                }

                is FidoRegistrationCallback -> {
                    FidoRegistration(it, onNext)
                    showNext = false
                }

                is FidoAuthenticationCallback -> {
                    FidoAuthentication(it, onNext)
                    showNext = false
                }

                is DeviceBindingCallback -> {
                    // Create / reuse a ViewModel bound to this composition & callback instance
                    val vm: DeviceBindingCallbackViewModel =
                        viewModel(factory = DeviceBindingCallbackViewModel.factory(it))
                    DeviceBindingCallback(vm, onNext)
                    showNext = false
                }

                is DeviceSigningVerifierCallback -> {
                    val vm: DeviceSigningVerifierCallbackViewModel =
                        viewModel(factory = DeviceSigningVerifierCallbackViewModel.factory(it))
                    DeviceSigningVerifierCallback(vm, true, onNext)
                    showNext = false
                }
            }
        }
        if (showNext) {
            Button(
                modifier = Modifier.align(Alignment.End),
                onClick = onNext,
            ) {
                Text("Next")
            }
        }
    }
}
