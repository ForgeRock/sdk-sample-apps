/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.device.profile.DeviceProfileCallback
import com.pingidentity.device.profile.DeviceProfileConfig
import com.pingidentity.device.profile.collector.BluetoothCollector
import com.pingidentity.device.profile.collector.BrowserCollector
import com.pingidentity.device.profile.collector.HardwareCollector
import com.pingidentity.device.profile.collector.NetworkCollector
import com.pingidentity.device.profile.collector.PlatformCollector
import com.pingidentity.device.profile.collector.TelephonyCollector
import kotlinx.coroutines.launch

/**
 * A Composable UI component for handling device profile collection during authentication flows.
 *
 * This composable provides a user-friendly interface for the device profile collection process,
 * automatically initiating the collection when the component is displayed and providing visual
 * feedback to inform users that device profiling is in progress.
 *
 * **Key Features:**
 * - **Automatic Collection**: Initiates device profile collection immediately when displayed
 * - **Visual Feedback**: Shows a loading spinner with descriptive text during collection
 * - **Comprehensive Profiling**: Configures multiple collectors for thorough device analysis
 * - **Seamless Integration**: Automatically proceeds to next authentication step upon completion
 * - **Error Handling**: Gracefully handles collection failures and system limitations
 *
 * **Collection Process:**
 * 1. Component renders with loading indicator
 * 2. LaunchedEffect triggers device profile collection
 * 3. Multiple collectors gather device information:
 *    - Platform information (OS, device model, security status)
 *    - Hardware specifications (CPU, memory, display, camera)
 *    - Network connectivity status and capabilities
 *    - Telephony and carrier information
 *    - Bluetooth hardware support
 *    - Browser/WebView user agent data
 * 4. Collection results are submitted to the authentication journey
 * 5. UI automatically transitions to next authentication step
 *
 * **UI Behavior:**
 * - Displays centered loading spinner (48dp size)
 * - Shows "Gathering Device Profile..." message below spinner
 * - Maintains loading state until collection completes
 * - Uses consistent Material Design 3 styling
 * - Responsive padding and spacing for various screen sizes
 *
 * **Privacy Considerations:**
 * - Collects device metadata for security and fraud prevention
 * - Does not include location data unless explicitly configured
 * - User should be informed about data collection through privacy policies
 * - Collection respects system permissions and privacy settings
 *
 * **Usage Example:**
 * ```kotlin
 * DeviceProfileCallback(
 *     deviceProfileCallback = callback,
 *     onNext = {
 *         // Navigate to next authentication step
 *         viewModel.nextStep()
 *     }
 * )
 * ```
 *
 * **Integration Notes:**
 * - Should be used within a Compose navigation or authentication flow
 * - Requires valid DeviceProfileCallback instance from journey
 * - onNext callback should handle navigation to subsequent authentication steps
 * - Component handles all collection logic internally
 *
 * @param deviceProfileCallback The DeviceProfileCallback instance from the authentication journey
 *                             that handles the actual device profile collection process and server
 *                             communication
 * @param onNext Callback function invoked when device profile collection completes successfully.
 *              This is typically used to proceed to the next step in the authentication journey
 *              or navigate to the subsequent screen in the authentication flow.
 *
 * @see com.pingidentity.device.profile.DeviceProfileCallback
 * @see DeviceProfileConfig
 * @see LaunchedEffect
 */
@Composable
fun DeviceProfileCallback(
    deviceProfileCallback: DeviceProfileCallback,
    onNext: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    var isLoading by remember { mutableStateOf(true) } // Start in the loading state

    // This effect runs ONCE when the composable enters the screen
    LaunchedEffect(key1 = true) {
        scope.launch {
            val result = deviceProfileCallback.collect {
                collectors {
                    clear()
                    add(PlatformCollector())
                    add(HardwareCollector())
                    add(NetworkCollector())
                    add(TelephonyCollector)
                    add(BluetoothCollector)
                    add(BrowserCollector)
                }
            }
            println(result.toString())
            isLoading = false
            onNext()
        }
    }

    // The UI will always show the loading indicator until collection is complete.
    if (isLoading) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
                modifier = Modifier.padding(16.dp)
            ) {
                CircularProgressIndicator(modifier = Modifier.size(48.dp))
                Spacer(modifier = Modifier.height(16.dp))
                Text(text = "Gathering Device Profile...")
            }
        }
    }
}