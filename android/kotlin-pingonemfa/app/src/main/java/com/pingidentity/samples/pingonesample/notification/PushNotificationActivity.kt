/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.notification

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import com.pingidentity.pingonemfa.push.PushNotification
import com.pingidentity.samples.pingonesample.theme.AppTheme
import com.pingidentity.samples.pingonesample.ui.PushNotificationScreen
import kotlinx.coroutines.launch

/**
 * Activity displayed when a PingOne MFA push notification arrives, either while the app is in the
 * foreground (launched directly by [com.pingidentity.samples.pingonesample.service.PushNotificationService])
 * or when the user taps the system-tray banner posted by
 * [com.pingidentity.samples.pingonesample.notification.NotificationHelper].
 *
 * The [PushNotification] is passed as a Parcelable Intent extra. Because Android re-delivers Intent
 * extras to the recreated component after process death, this Activity survives the process being
 * killed while the banner is showing — the user can tap the banner cold, and we'll still have the
 * full notification object.
 *
 * ## Multiple notifications
 * Because the activity is `singleTop`, a second push arriving while this screen is open is
 * delivered via [onNewIntent] rather than starting a new instance. We update the
 * [currentNotification] Compose state directly (no `recreate()` call), which causes the screen to
 * recompose atomically with [PushNotificationViewModel.resetState] clearing any stale dialog from
 * the previous request. This prevents the user from seeing a "Approved" dialog for a notification
 * they haven't acted on yet.
 *
 * ## Cancellation
 * If the server cancels the authentication request while this activity is open (e.g. because the
 * user approved on another device), the FCM cancel push causes [PushNotificationService] to emit
 * on [NotificationCancelBus]. This activity collects that flow and calls [finish] immediately if
 * the canceled ID matches the notification it is currently showing.
 */
class PushNotificationActivity : ComponentActivity() {

    private val viewModel: PushNotificationViewModel by viewModels()

    // Hoisted as Compose state so onNewIntent can swap in a new notification without recreate().
    private var currentNotification by mutableStateOf<PushNotification?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val notification = getNotification()
        if (notification == null) {
            // Intent extra was missing/malformed — nothing safe to show, bail out.
            finish()
            return
        }

        currentNotification = notification

        // Observe cancellation signals from the service. Keyed on the current notification id so
        // we only dismiss when the cancel matches what is currently on screen.
        lifecycleScope.launch {
            NotificationCancelBus.cancellations.collect { cancelledId ->
                if (cancelledId == currentNotification?.id) {
                    finish()
                }
            }
        }

        setContent {
            AppTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    // currentNotification is Compose state: recompose happens automatically when
                    // onNewIntent updates it. The null branch is transient — it only occurs for
                    // the single frame between resetState() and the state write, and the previous
                    // screen remains visible until recomposition commits.
                    currentNotification?.let { notification ->
                        PushNotificationScreen(
                            notification = notification,
                            viewModel = viewModel,
                            onFinish = {
                                PushNotificationStore.remove()
                                finish()
                            }
                        )
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // A second push arrived while this Activity is already on top (FLAG_ACTIVITY_SINGLE_TOP).
        // 1. Clear stale approve/deny result from the previous notification so the new screen
        //    does not briefly show "Approved" before the user has acted.
        // 2. Swap the displayed notification atomically — Compose recomposes in the same frame.
        // No recreate() call needed: updating Compose state is sufficient and cheaper.
        val newNotification = extractNotification(intent) ?: return
        viewModel.resetState()
        setIntent(intent)
        currentNotification = newNotification
    }

    private fun getNotification(): PushNotification? = extractNotification(intent)

    private fun extractNotification(src: Intent?): PushNotification? {
        src ?: return null
        @Suppress("DEPRECATION")
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            src.getParcelableExtra(EXTRA_PINGONE_NOTIFICATION, PushNotification::class.java)
        } else {
            src.getParcelableExtra<PushNotification>(EXTRA_PINGONE_NOTIFICATION)
        }
    }

    companion object {
        /** Parcelable [PushNotification] extra carried by both the direct-launch Intent and the tray tap PendingIntent. */
        const val EXTRA_PINGONE_NOTIFICATION = "pingone_notification"
    }
}
