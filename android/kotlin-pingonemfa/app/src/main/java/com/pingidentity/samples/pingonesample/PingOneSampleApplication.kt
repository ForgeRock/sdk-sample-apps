/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample

import android.app.Application
import com.google.firebase.messaging.FirebaseMessaging
import com.pingidentity.logger.Logger
import com.pingidentity.pingonemfa.commons.Geo
import com.pingidentity.pingonemfa.commons.PingOneMFA
import com.pingidentity.samples.pingonesample.data.DiagnosticLogger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * Application subclass that performs one-time, process-scoped initialisation.
 *
 * Keeping SDK init and FCM token registration here instead of in [MainActivity.onCreate] avoids
 * two separate problems:
 *
 *  1. **Rotation double-fire** — `Activity.onCreate` is called on every configuration change, so
 *     any work placed there runs redundantly on each rotate. `Application.onCreate` runs exactly
 *     once per OS process, regardless of how many Activities are created or recreated.
 *
 *  2. **Scope cancellation mid-rotation** — `lifecycleScope` is cancelled when the Activity is
 *     destroyed during a rotation, so an in-flight `setDeviceToken` coroutine started in
 *     `MainActivity.onCreate` may be torn down before the SDK call completes. The
 *     [applicationScope] below is backed by a [SupervisorJob] that lives for the full process
 *     lifetime, so SDK calls here are never cancelled by Activity lifecycle events.
 */
class PingOneSampleApplication : Application() {

    /**
     * Process-lifetime coroutine scope. [SupervisorJob] means individual child failures do not
     * cancel sibling coroutines. [Dispatchers.Default] is the right home for CPU/IO SDK calls
     * that do not need the main thread.
     */
    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    /** Wires up the diagnostic logger and kicks off SDK init + FCM token registration. */
    override fun onCreate() {
        super.onCreate()

        // Route all SDK logs through DiagnosticLogger so they appear in the in-app logs screen.
        Logger.logger = DiagnosticLogger
        DiagnosticLogger.i("PingOneSampleApplication: process started — diagnostic logging enabled")

        initializeSdkThenRegisterToken()
    }

    /**
     * Initialises the PingOne MFA SDK, then — only on success — fetches the current FCM
     * registration token and registers it with the SDK.
     *
     * The two steps run sequentially in [applicationScope] to close the ordering race that exists
     * when they are launched in parallel: Firebase typically delivers a cached token
     * synchronously, so a parallel launch causes [PingOneMFA.setDeviceToken] to execute before
     * [PingOneMFA.initialize] has completed, resulting in a silent failure on first install or
     * after a data-clear.
     *
     * [com.google.firebase.messaging.FirebaseMessagingService.onNewToken] only fires when the
     * token *changes*, so relying on it alone leaves a registration gap. Proactively fetching
     * the current token here and calling [PingOneMFA.setDeviceToken] closes that gap —
     * FCM returns the cached token if it hasn't changed, and the SDK call is idempotent.
     *
     * Runs in [applicationScope] (backed by [SupervisorJob]) so neither step is ever cancelled
     * by an Activity lifecycle event such as rotation.
     */
    private fun initializeSdkThenRegisterToken() {
        applicationScope.launch {
            DiagnosticLogger.d("initialize: starting PingOneMFA SDK (NORTH_AMERICA)")
            PingOneMFA.initialize(Geo.NORTH_AMERICA)
                .onSuccess {
                    DiagnosticLogger.i("initialize: PingOneMFA SDK ready")
                    registerFcmTokenWithPingOne()
                }
                .onFailure {
                    DiagnosticLogger.e("initialize: PingOneMFA SDK failed — ${it.message}", it)
                    // FCM token registration is skipped: the SDK is not ready to accept it.
                }
        }
    }

    /**
     * Fetches the current FCM token via a [suspendCancellableCoroutine] bridge (avoids the
     * `kotlinx-coroutines-play-services` dependency) and registers it with the PingOne MFA SDK.
     * Must only be called after [PingOneMFA.initialize] has succeeded.
     */
    private suspend fun registerFcmTokenWithPingOne() {
        val token = suspendCancellableCoroutine<String?> { cont ->
            FirebaseMessaging.getInstance().token
                .addOnSuccessListener { token -> cont.resume(token) }
                .addOnFailureListener { e ->
                    DiagnosticLogger.e("fcm: failed to fetch FCM token — ${e.message}", e)
                    cont.resume(null)
                }
        } ?: return

        DiagnosticLogger.d("fcm: fetched current token, registering with PingOneMFA")
        PingOneMFA.setDeviceToken(token)
            .onSuccess { DiagnosticLogger.i("fcm: token registered with PingOneMFA") }
            .onFailure { DiagnosticLogger.e("fcm: setDeviceToken failed — ${it.message}", it) }
    }
}
