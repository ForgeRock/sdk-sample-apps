/*
 * Copyright (c) 2025-2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.drawable.Drawable
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.AlarmOn
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.DesktopMac
import androidx.compose.material.icons.filled.Laptop
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.PhoneAndroid
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Pin
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Fingerprint
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DividerDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.data.LocationAddress
import com.pingidentity.authenticatorapp.data.NotificationStatus
import com.pingidentity.authenticatorapp.data.PushNotificationItem
import com.pingidentity.authenticatorapp.service.LocationService
import com.pingidentity.authenticatorapp.ui.components.AccountAvatar
import com.pingidentity.authenticatorapp.ui.components.StatusIndicator
import com.pingidentity.mfa.commons.policy.BiometricAvailablePolicy
import com.pingidentity.mfa.commons.policy.DeviceTamperingPolicy
import com.pingidentity.mfa.push.PushType
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker

/**
 * Unified screen for displaying push notification details.
 * Handles both standard authentication and challenge-based notifications.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationResponseScreen(
    notificationItem: PushNotificationItem,
    onDismiss: () -> Unit,
    onApprove: (() -> Unit)? = null,
    onBiometricApprove: (() -> Unit)? = null,
    onDeny: (() -> Unit)? = null,
    onChallengeSolution: ((String) -> Unit)? = null
) {
    val context = LocalContext.current
    // State for location address
    var locationAddress by remember { mutableStateOf<LocationAddress?>(null) }
    var isLoadingAddress by remember { mutableStateOf(false) }
    var addressError by remember { mutableStateOf<String?>(null) }

    // Location service
    val locationService = remember { LocationService() }

    // Clean up LocationService when the composable is disposed
    DisposableEffect(Unit) {
        onDispose {
            locationService.close()
        }
    }

    // Load address when screen opens if location is available
    LaunchedEffect(notificationItem.latitude, notificationItem.longitude) {
        if (notificationItem.hasLocationInfo && 
            notificationItem.latitude != null && 
            notificationItem.longitude != null) {
            
            isLoadingAddress = true
            addressError = null
            
            try {
                val address = locationService.reverseGeocode(
                    notificationItem.latitude,
                    notificationItem.longitude
                )
                locationAddress = address
                if (address == null) {
                    addressError = context.getString(R.string.notification_response_location_error)
                }
            } catch (_: Exception) {
                addressError = context.getString(R.string.notification_response_location_failed)
            } finally {
                isLoadingAddress = false
            }
        }
    }

    val isChallenge = notificationItem.notification.pushType == PushType.CHALLENGE
    val challengeNumbers = if (isChallenge) notificationItem.notification.getNumbersChallenge() else emptyList()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.notification_response_screen_title)) },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(id = R.string.back)
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = if (isChallenge) Alignment.CenterHorizontally else Alignment.Start
        ) {
            // Header with issuer, account, and location map
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    // Status indicator and account header
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        AccountAvatar(
                            issuer = notificationItem.credential?.issuer ?: stringResource(id = R.string.notification_response_unknown_issuer),
                            accountName = notificationItem.credential?.accountName ?: stringResource(id = R.string.notification_response_unknown_account),
                            imageUrl = notificationItem.credential?.imageURL,
                            size = 36.dp
                        )

                        Spacer(modifier = Modifier.width(16.dp))

                        // Issuer and account name
                        Column(modifier = Modifier.weight(1f)) {
                            val issuer = notificationItem.credential?.issuer ?: stringResource(id = R.string.notification_response_unknown_issuer)
                            val accountName = notificationItem.credential?.accountName ?: stringResource(id = R.string.notification_response_unknown_account)

                            Text(
                                text = issuer,
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = accountName,
                                style = MaterialTheme.typography.bodyLarge
                            )
                        }

                        // Status indicator
                        StatusIndicator(status = notificationItem.status)
                    }

                    // Divider
                    HorizontalDivider(
                        modifier = Modifier.padding(vertical = 16.dp),
                        thickness = DividerDefaults.Thickness,
                        color = DividerDefaults.color
                    )

                    // Message
                    Text(
                        text = notificationItem.notification.messageText ?: 
                            if (isChallenge) stringResource(id = R.string.notification_response_message_verify) else stringResource(id = R.string.notification_response_message_default),
                        style = MaterialTheme.typography.bodyLarge,
                    )

                    // Time sent
                    notificationItem.notification.sentAt?.let { sentAt ->
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Default.Alarm,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = sentAt.toString(),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    // Response time
                    notificationItem.notification.respondedAt?.let { respondedAt ->
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Default.AlarmOn,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = respondedAt.toString(),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Authentication method
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        val (icon, text) = when {
                            notificationItem.requiresBiometric -> Pair(
                                Icons.Outlined.Fingerprint,
                                stringResource(id = R.string.notification_response_auth_method_biometric)
                            )
                            notificationItem.requiresChallenge -> Pair(
                                Icons.Default.Pin,
                                stringResource(id = R.string.notification_response_auth_method_challenge)
                            )
                            else -> Pair(
                                Icons.Default.CheckCircle,
                                stringResource(id = R.string.notification_response_auth_method_standard)
                            )
                        }
                        Icon(
                            icon,
                            text,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    // Device information
                    notificationItem.deviceInfo?.let {
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            val deviceIcon = when(it.os) {
                                stringResource(id = R.string.notification_response_device_os_macos) -> Icons.Default.DesktopMac
                                stringResource(id = R.string.notification_response_device_os_windows), stringResource(id = R.string.notification_response_device_os_linux) -> Icons.Default.Laptop
                                stringResource(id = R.string.notification_response_device_os_android), stringResource(id = R.string.notification_response_device_os_ios) -> Icons.Default.PhoneAndroid
                                else -> Icons.Default.Laptop
                            }
                            Icon(
                                imageVector = deviceIcon,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "${it.os} - ${it.browser} ${it.browserVersion}",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    // Location address information (only if location is available)
                    if (notificationItem.hasLocationInfo &&
                        notificationItem.latitude != null &&
                        notificationItem.longitude != null) {
                        
                        // Location divider
                        HorizontalDivider(
                            modifier = Modifier.padding(vertical = 16.dp),
                            thickness = DividerDefaults.Thickness,
                            color = DividerDefaults.color
                        )

                        // Location address information
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(
                                imageVector = Icons.Default.LocationOn,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )

                            Spacer(modifier = Modifier.width(8.dp))

                            when {
                                isLoadingAddress -> {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        CircularProgressIndicator(
                                            modifier = Modifier.size(16.dp),
                                            strokeWidth = 2.dp
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text(
                                            text = stringResource(id = R.string.notification_response_loading_location),
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                                locationAddress != null -> {
                                    Text(
                                        text = locationAddress?.formatForDisplay() ?: "",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                addressError != null -> {
                                    Text(
                                        text = stringResource(id = R.string.notification_response_location_lat_lng, notificationItem.latitude.toString(), notificationItem.longitude.toString()),
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                else -> {
                                    Text(
                                        text = stringResource(id = R.string.notification_response_location_lat_lng, notificationItem.latitude.toString(), notificationItem.longitude.toString()),
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }

                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(8.dp)
                        ) {
                            AndroidView(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(120.dp),
                                factory = { context ->
                                    Configuration.getInstance().load(context, context.getSharedPreferences("osm", 0))

                                    MapView(context).apply {
                                        setTileSource(TileSourceFactory.MAPNIK)
                                        setMultiTouchControls(false)
                                        isClickable = false
                                        isFocusable = false
                                        isFocusableInTouchMode = false

                                        val location = GeoPoint(
                                            notificationItem.latitude,
                                            notificationItem.longitude
                                        )
                                        controller.setCenter(location)
                                        controller.setZoom(18.0)
                                        
                                        // Lock zoom level to prevent user changes
                                        minZoomLevel = 18.0
                                        maxZoomLevel = 18.0

                                        val marker = Marker(this)
                                        marker.position = location
                                        marker.title = context.getString(R.string.notification_response_map_marker_title)
                                        marker.setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)

                                        // Create custom red location pin drawable
                                        val customIcon = createLocationPinDrawable(Color.Red.toArgb())
                                        marker.icon = customIcon

                                        overlays.add(marker)

                                        invalidate()
                                    }
                                }
                            )
                        }
                    }
                }
            }

            // Action buttons based on type
            if (isChallenge && notificationItem.status == NotificationStatus.PENDING) {
                // Challenge selection UI
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = stringResource(id = R.string.notification_response_challenge_prompt),
                        style = MaterialTheme.typography.bodyLarge,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    if (challengeNumbers.isNotEmpty()) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly
                        ) {
                            challengeNumbers.forEach { number ->
                                ChallengeNumberButton(
                                    number = number,
                                    onClick = { onChallengeSolution?.invoke(number.toString()) }
                                )
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(24.dp))
                        
                        OutlinedButton(
                            onClick = onDismiss,
                            modifier = Modifier.fillMaxWidth(0.7f),
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = MaterialTheme.colorScheme.error
                            ),
                            border = BorderStroke(1.dp, MaterialTheme.colorScheme.error)
                        ) {
                            Text(stringResource(id = R.string.notification_response_cancel_authentication))
                        }
                    } else {
                        Text(
                            text = stringResource(id = R.string.notification_response_no_challenge_numbers),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.error
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Button(
                            onClick = onDismiss,
                            modifier = Modifier.fillMaxWidth(0.7f)
                        ) {
                            Text(stringResource(id = R.string.close))
                        }
                    }
                }
            } else if (notificationItem.credential?.isLocked == true) {
                // Show lock message for locked credentials
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Row(
                        modifier = Modifier
                            .fillMaxWidth(0.9f)
                            .background(
                                color = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.3f),
                                shape = RoundedCornerShape(8.dp)
                            )
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Lock,
                            contentDescription = stringResource(id = R.string.account_locked_indicator),
                            tint = MaterialTheme.colorScheme.error,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        val lockMessage = when (notificationItem.credential.lockingPolicy?.lowercase()) {
                            BiometricAvailablePolicy.POLICY_NAME -> stringResource(id = R.string.account_locked_biometric_available)
                            DeviceTamperingPolicy.POLICY_NAME -> stringResource(id = R.string.account_locked_device_tampering)
                            null -> stringResource(id = R.string.account_locked_unknown_policy)
                            else -> stringResource(id = R.string.account_locked_generic_policy, notificationItem.credential.lockingPolicy!!)
                        }
                        Text(
                            text = lockMessage,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Button(
                        onClick = onDismiss,
                        modifier = Modifier.fillMaxWidth(0.7f)
                    ) {
                        Text(stringResource(id = R.string.close))
                    }
                }
            } else if (notificationItem.status == NotificationStatus.PENDING) {
                // Standard approve/deny buttons
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Button(
                        onClick = {
                            onDeny?.invoke()
                        },
                        modifier = Modifier
                            .weight(1f)
                            .padding(end = 8.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.errorContainer,
                            contentColor = MaterialTheme.colorScheme.onErrorContainer
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Close,
                            contentDescription = stringResource(id = R.string.deny)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(text = stringResource(id = R.string.deny))
                    }

                    Button(
                        onClick = {
                            when {
                                onBiometricApprove != null && notificationItem.requiresBiometric -> {
                                    onBiometricApprove()
                                }
                                onApprove != null -> {
                                    onApprove()
                                }
                            }
                        },
                        modifier = Modifier
                            .weight(1f)
                            .padding(start = 8.dp)
                    ) {
                        Icon(
                            imageVector = if (notificationItem.requiresBiometric)
                                Icons.Outlined.Fingerprint else Icons.Outlined.Check,
                            contentDescription = stringResource(id = R.string.approve)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(text = if (notificationItem.requiresBiometric) stringResource(id = R.string.verify) else stringResource(id = R.string.approve))
                    }
                }
            }
        }
    }
}

/**
 * A button displaying a challenge number.
 */
@Composable
private fun ChallengeNumberButton(
    number: Int,
    onClick: () -> Unit
) {
    OutlinedButton(
        onClick = onClick,
        modifier = Modifier.size(80.dp),
        shape = CircleShape,
        border = BorderStroke(2.dp, MaterialTheme.colorScheme.primary),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = MaterialTheme.colorScheme.primary,
            containerColor = Color.Transparent
        )
    ) {
        Text(
            text = number.toString(),
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

/**
 * Creates a custom location pin drawable with the specified color
 */
private fun createLocationPinDrawable(color: Int): Drawable {
    return object : Drawable() {
        private val paint = Paint().apply {
            this.color = color
            isAntiAlias = true
            style = Paint.Style.FILL
        }
        
        private val strokePaint = Paint().apply {
            this.color = android.graphics.Color.WHITE
            isAntiAlias = true
            style = Paint.Style.STROKE
            strokeWidth = 3f
        }

        override fun draw(canvas: Canvas) {
            val bounds = getBounds()
            val centerX = bounds.centerX().toFloat()
            val width = bounds.width().toFloat()
            val height = bounds.height().toFloat()
            
            // Create location pin shape
            val path = Path().apply {
                // Top circle part
                val circleRadius = width * 0.3f
                val circleY = height * 0.3f
                addCircle(centerX, circleY, circleRadius, Path.Direction.CW)
                
                // Bottom triangle part
                moveTo(centerX - circleRadius * 0.5f, circleY + circleRadius * 0.5f)
                lineTo(centerX, height * 0.9f)
                lineTo(centerX + circleRadius * 0.5f, circleY + circleRadius * 0.5f)
                close()
            }
            
            // Draw the pin with stroke first, then fill
            canvas.drawPath(path, strokePaint)
            canvas.drawPath(path, paint)
            
            // Draw inner circle (location dot)
            val innerCircleRadius = width * 0.15f
            val innerY = height * 0.3f
            canvas.drawCircle(centerX, innerY, innerCircleRadius, strokePaint)
        }

        override fun setAlpha(alpha: Int) {
            paint.alpha = alpha
            strokePaint.alpha = alpha
        }

        override fun setColorFilter(colorFilter: android.graphics.ColorFilter?) {
            paint.colorFilter = colorFilter
            strokePaint.colorFilter = colorFilter
        }

        override fun getOpacity(): Int = android.graphics.PixelFormat.TRANSLUCENT
        
        override fun getIntrinsicWidth(): Int = 48
        override fun getIntrinsicHeight(): Int = 60
    }
}
