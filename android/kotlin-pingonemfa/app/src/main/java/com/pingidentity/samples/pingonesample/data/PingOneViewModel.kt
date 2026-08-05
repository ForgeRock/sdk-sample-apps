/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.data

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.pingonemfa.commons.PingOneMFA
import com.pingidentity.pingonemfa.commons.PingOneMfaAccount
import com.pingidentity.pingonemfa.otp.OtpCodeInfo
import com.pingidentity.samples.pingonesample.R
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class PingOneViewModel(application: Application) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    /**
     * Fetches registered accounts (devices) from the PingOne MFA SDK and updates [uiState].
     */
    fun loadAccounts() {
        viewModelScope.launch {
            DiagnosticLogger.d("loadAccounts: fetching device info")
            _uiState.update { it.copy(isLoading = true) }
            PingOneMFA.getDeviceInfo().onSuccess { (accounts, errors) ->
                DiagnosticLogger.i("loadAccounts: loaded ${accounts.size} account(s)")
                if (errors?.isNotEmpty() == true) {
                    DiagnosticLogger.w("loadAccounts: SDK returned ${errors.size} diagnostic error(s): $errors")
                }
                _uiState.update {
                    it.copy(
                        accounts = accounts,
                        isLoading = false,
                        error = null
                    )
                }
            }.onFailure { e ->
                DiagnosticLogger.e("loadAccounts: failed — ${e.message}", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load accounts"
                    )
                }
            }
        }
    }

    /**
     * Pairs a new account using the [pairingKey] extracted from a scanned QR code.
     * On success reloads the accounts list and sets successMessage.
     */
    fun pairAccount(pairingKey: String) {
        viewModelScope.launch {
            DiagnosticLogger.d("pairAccount: initiating pairing")
            _uiState.update { it.copy(isPairing = true, error = null) }
            PingOneMFA.pair(pairingKey).onSuccess {
                DiagnosticLogger.i("pairAccount: pairing succeeded")
                _uiState.update {
                    it.copy(
                        isPairing = false,
                        successMessage = getApplication<Application>()
                            .getString(R.string.qr_scanner_account_added),
                        error = null
                    )
                }
                loadAccounts()
            }.onFailure { e ->
                DiagnosticLogger.e("pairAccount: failed — ${e.message}", e)
                _uiState.update {
                    it.copy(
                        isPairing = false,
                        error = e.message ?: "Failed to pair account"
                    )
                }
            }
        }
    }

    /**
     * Generates a one-time passcode for paired accounts.
     *
     * Always bumps [AuthUiState.otpVersion] on both success and failure — the countdown UI
     * keys its restart on that counter, so an incremented version guarantees the countdown
     * restarts (falling back to a 30s retry on failure) rather than freezing at 0s.
     */
    fun generateOtp() {
        // Skip if a refresh is already in flight — prevents overlapping SDK calls.
        if (_uiState.value.isRefreshingOtp) {
            DiagnosticLogger.d("generateOtp: skipped — refresh already in flight")
            return
        }
        viewModelScope.launch {
            DiagnosticLogger.d("generateOtp: requesting OTP")
            _uiState.update { it.copy(isRefreshingOtp = true) }
            PingOneMFA.getOneTimePasscode().onSuccess { otpInfo ->
                // Capture the absolute expiry as an elapsedRealtime deadline. Using
                // elapsedRealtime (monotonic, unaffected by wall-clock adjustments) is safer
                // than currentTimeMillis for a short-lived countdown. Anchoring at receipt
                // time means the countdown continues correctly across composable
                // navigation — leaving and returning to the screen computes remaining time
                // from this deadline, so the counter does not reset to 30s.
                val secondsFromSdk = otpInfo.secondsRemaining.takeIf { it > 0 } ?: DEFAULT_OTP_TTL_SECONDS
                val expiresAtElapsedMs = android.os.SystemClock.elapsedRealtime() + secondsFromSdk * 1_000L
                DiagnosticLogger.i("generateOtp: OTP generated, expires in ${secondsFromSdk}s")
                _uiState.update {
                    it.copy(
                        generatedCode = otpInfo,
                        otpExpiresAtElapsedMs = expiresAtElapsedMs,
                        isRefreshingOtp = false,
                        otpVersion = it.otpVersion + 1,
                    )
                }
            }.onFailure { e ->
                DiagnosticLogger.e("generateOtp: failed — ${e.message}", e)
                _uiState.update {
                    it.copy(
                        isRefreshingOtp = false,
                        error = e.message ?: "Failed to generate OTP",
                        otpVersion = it.otpVersion + 1,
                    )
                }
            }
        }
    }

    fun setError(errorMessage: String) {
        _uiState.update { it.copy(error = errorMessage) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun setMessage(message: String) {
        _uiState.update { it.copy(successMessage = message) }
    }

    fun clearMessage() {
        _uiState.update { it.copy(successMessage = null) }
    }

    companion object {
        /** Fallback OTP validity when the SDK returns 0 or a missing secondsRemaining. */
        const val DEFAULT_OTP_TTL_SECONDS: Int = 30
    }
}

/**
 * Full UI state for the PingOne MFA sample app.
 */
data class AuthUiState(
    val accounts: List<PingOneMfaAccount> = emptyList(),
    val generatedCode: OtpCodeInfo? = null,
    /**
     * Absolute expiry deadline for [generatedCode] expressed as `SystemClock.elapsedRealtime()`
     * milliseconds. Captured at the moment the SDK returned the OTP; using elapsedRealtime
     * (monotonic, unaffected by wall-clock changes) is safer than currentTimeMillis for a
     * short-lived countdown. `null` when there is no active OTP.
     *
     * The countdown UI derives remaining seconds from `expiresAtElapsedMs - elapsedRealtime()`
     * on every tick, which means the counter is correct across screen re-entry — leaving and
     * returning to the accounts screen resumes at the true remaining time, not at 30s.
     */
    val otpExpiresAtElapsedMs: Long? = null,
    val isLoading: Boolean = false,
    val isPairing: Boolean = false,
    /** True while [PingOneViewModel.generateOtp] has an SDK call in flight. */
    val isRefreshingOtp: Boolean = false,
    /**
     * Monotonically increasing token bumped by [PingOneViewModel.generateOtp] on every
     * outcome (success and failure). The OTP countdown UI keys its restart on this so it
     * always relaunches even when the SDK returns an identical [OtpCodeInfo] or fails.
     */
    val otpVersion: Int = 0,
    val error: String? = null,
    val successMessage: String? = null,
)
