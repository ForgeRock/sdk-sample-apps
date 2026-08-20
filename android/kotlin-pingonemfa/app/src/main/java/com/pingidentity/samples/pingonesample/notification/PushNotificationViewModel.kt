/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.notification

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.pingonemfa.push.PushNotification
import com.pingidentity.samples.pingonesample.R
import com.pingidentity.samples.pingonesample.data.DiagnosticLogger
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * ViewModel backing [com.pingidentity.samples.pingonesample.ui.PushNotificationScreen].
 *
 * Owns the approve/deny SDK calls and the resulting dialog state. Using [viewModelScope] instead
 * of `rememberCoroutineScope()` ensures that an in-flight SDK call survives configuration changes
 * (e.g. rotation) — the scope is only cancelled when the Activity is genuinely finished, not merely
 * recreated.
 */
class PushNotificationViewModel(application: Application) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(PushNotificationUiState())
    /** Observable UI state for the push notification approval screen. */
    val uiState: StateFlow<PushNotificationUiState> = _uiState.asStateFlow()

    /**
     * Approves the authentication request.
     *
     * @param notification The push notification to approve.
     * @param numberChallenge Optional number challenge value required for [PushType.CHALLENGE] pushes.
     */
    fun approve(notification: PushNotification, numberChallenge: Int? = null) {
        if (_uiState.value.isLoading) return
        val context: Context = getApplication()
        val approvedTitle = context.getString(R.string.text_pingone_mfa_approved_title)
        val approvedMessage = context.getString(R.string.text_pingone_mfa_approved_message)
        val approvalFailedMessage = context.getString(R.string.text_pingone_mfa_approval_failed)

        viewModelScope.launch {
            DiagnosticLogger.d("PushNotificationViewModel: approving notification ${notification.id}")
            _uiState.update { it.copy(isLoading = true) }
            try {
                notification.approveNotification(
                    context = context,
                    authenticationMethod = "app",
                    numberChallenge = numberChallenge
                ).onSuccess {
                    DiagnosticLogger.i("PushNotificationViewModel: notification approved successfully")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            dialogState = PushDialogState.Success(approvedTitle, approvedMessage),
                        )
                    }
                }.onFailure { e ->
                    DiagnosticLogger.e("PushNotificationViewModel: approve failed — ${e.message}", e)
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            dialogState = PushDialogState.Error(e.message ?: approvalFailedMessage),
                        )
                    }
                }
            } catch (e: Exception) {
                DiagnosticLogger.e("PushNotificationViewModel: approve threw — ${e.message}", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        dialogState = PushDialogState.Error(e.message ?: approvalFailedMessage),
                    )
                }
            }
        }
    }

    /**
     * Resets UI state to the idle baseline.
     *
     * Called from [PushNotificationActivity.onNewIntent] when a second push arrives while the
     * Activity is already showing a previous notification. Because ViewModels survive
     * configuration changes (and therefore survive the old `recreate()` path), any stale
     * [PushDialogState.Success] or [PushDialogState.Error] from the completed previous request
     * must be cleared before the new notification is displayed — otherwise the user would see
     * "Approved" for a request they haven't yet acted on.
     */
    fun resetState() {
        _uiState.update { PushNotificationUiState() }
    }

    /**
     * Denies the authentication request.
     *
     * @param notification The push notification to deny.
     */
    fun deny(notification: PushNotification) {
        if (_uiState.value.isLoading) return
        val context: Context = getApplication()
        val deniedTitle = context.getString(R.string.text_pingone_mfa_denied_title)
        val deniedMessage = context.getString(R.string.text_pingone_mfa_denied_message)
        val denyFailedMessage = context.getString(R.string.text_pingone_mfa_deny_failed)

        viewModelScope.launch {
            DiagnosticLogger.d("PushNotificationViewModel: denying notification ${notification.id}")
            _uiState.update { it.copy(isLoading = true) }
            try {
                notification.denyNotification(context)
                    .onSuccess {
                        DiagnosticLogger.i("PushNotificationViewModel: notification denied successfully")
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                dialogState = PushDialogState.Success(deniedTitle, deniedMessage),
                            )
                        }
                    }.onFailure { e ->
                        DiagnosticLogger.e("PushNotificationViewModel: deny failed — ${e.message}", e)
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                dialogState = PushDialogState.Error(e.message ?: denyFailedMessage),
                            )
                        }
                    }
            } catch (e: Exception) {
                DiagnosticLogger.e("PushNotificationViewModel: deny threw — ${e.message}", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        dialogState = PushDialogState.Error(e.message ?: denyFailedMessage),
                    )
                }
            }
        }
    }
}

/** Full UI state for the push notification approval screen. */
data class PushNotificationUiState(
    /** True while an approve or deny SDK call is in flight. */
    val isLoading: Boolean = false,
    /** Current dialog state — [PushDialogState.None] while idle, updated on SDK outcome. */
    val dialogState: PushDialogState = PushDialogState.None,
)

/** Models the three dialog states the push notification screen can be in. */
sealed interface PushDialogState {
    /** No result dialog is showing — the screen is idle or waiting for the user to act. */
    data object None : PushDialogState

    /**
     * The approve or deny call succeeded. Displayed as a confirmation dialog.
     *
     * @param title Dialog title (e.g. "Approved" or "Denied").
     * @param message Dialog body text.
     */
    data class Success(val title: String, val message: String) : PushDialogState

    /**
     * The approve or deny call failed. Displayed as an error dialog.
     *
     * @param message Human-readable error description.
     */
    data class Error(val message: String) : PushDialogState
}
