/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.data

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.util.getTimeAgoString
import com.pingidentity.mfa.commons.policy.BiometricAvailablePolicy
import com.pingidentity.mfa.commons.policy.DeviceTamperingPolicy
import com.pingidentity.mfa.oath.OathCredential
import com.pingidentity.mfa.push.PushCredential
import com.pingidentity.mfa.push.PushNotification
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

private val jsonParser = Json { ignoreUnknownKeys = true }

/**
 * Enum representing the status of a push notification.
 */
enum class NotificationStatus {
    PENDING,
    APPROVED,
    DENIED,
    EXPIRED
}

/**
 * Data class to represent a group of credentials (OATH or Push) with the same issuer/account.
 * This is used to display a unified account view regardless of authentication method.
 */
data class AccountGroup(
    val issuer: String,
    val accountName: String,
    val displayIssuer: String,
    val displayAccountName: String,
    val oathCredentials: List<OathCredential> = emptyList(),
    val pushCredentials: List<PushCredential> = emptyList()
) {
    /**
     * Check if this account group has any locked credentials.
     */
    val isLocked: Boolean
        get() = oathCredentials.any { it.isLocked } || pushCredentials.any { it.isLocked }
    
    /**
     * Get the locking policy name from the first locked credential.
     */
    val lockingPolicy: String?
        get() = oathCredentials.firstOrNull { it.isLocked }?.lockingPolicy 
            ?: pushCredentials.firstOrNull { it.isLocked }?.lockingPolicy
}

/**
 * Data class for push notification UI display with additional UI-specific fields.
 */
data class PushNotificationItem(
    val notification: PushNotification,
    val credential: PushCredential? = null,
    val timeAgo: String = "",
    val requiresChallenge: Boolean = false,
    val requiresBiometric: Boolean = false,
    val hasLocationInfo: Boolean = false,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val status: NotificationStatus = NotificationStatus.PENDING,
    val deviceInfo: DeviceInfo? = null
)

/**
 * Data class to represent location data parsed from contextInfo JSON.
 */
@Serializable
private data class LocationData(
    val latitude: Double,
    val longitude: Double
)

@Serializable
private data class ContextWrapper(
    @SerialName("location") val location: LocationData? = null,
    @SerialName("remoteIp") val remoteIp: String? = null,
    @SerialName("userAgent") val userAgent: String? = null
)

/**
 * Extension function to convert a list of push notifications into UI items with additional info.
 */
fun List<PushNotification>.toUiItems(pushCredentials: List<PushCredential>): List<PushNotificationItem> {
    return map {
        // Find the credential associated with this notification
        createPushNotificationItem(pushCredentials, it)
    }
}

/**
 * Function to create a PushNotificationItem from a PushNotification and its associated credentials.
 * 
 */
fun createPushNotificationItem(
    pushCredentials: List<PushCredential>,
    notification: PushNotification
): PushNotificationItem {
    val credential = pushCredentials.find { it.id == notification.credentialId }

    // Calculate time ago string
    val timeAgo = getTimeAgoString(notification.createdAt)

    // Determine notification characteristics based on push type
    val pushTypeStr = notification.pushType.toString()
    val requiresChallenge = pushTypeStr.lowercase().contains("challenge")
    val requiresBiometric = pushTypeStr.lowercase().contains("biometric")

    // Check if location info is available
    var hasLocationInfo = false
    var latitude: Double? = null
    var longitude: Double? = null
    var deviceInfo: DeviceInfo? = null

    notification.contextInfo?.let { contextInfoString ->
        val unescapedContextInfo = contextInfoString.replace("\\\"","\"")
        try {
            val parsedContext = jsonParser.decodeFromString<ContextWrapper>(unescapedContextInfo)
            parsedContext.location?.let {
                latitude = it.latitude
                longitude = it.longitude
                hasLocationInfo = true
            }
            parsedContext.userAgent?.let { userAgent ->
                deviceInfo = parseUserAgent(userAgent)
            }
        } catch (_: Exception) {
            // Ignore errors from decodeFromString if content is not valid JSON
        }
    }

    // Determine notification status
    val status = when {
        notification.approved -> NotificationStatus.APPROVED
        (notification.expired && notification.pending) -> NotificationStatus.EXPIRED
        notification.pending -> NotificationStatus.PENDING
        else -> NotificationStatus.DENIED
    }

    return PushNotificationItem(
        notification = notification,
        credential = credential,
        timeAgo = timeAgo,
        requiresChallenge = requiresChallenge,
        requiresBiometric = requiresBiometric,
        hasLocationInfo = hasLocationInfo,
        latitude = latitude,
        longitude = longitude,
        status = status,
        deviceInfo = deviceInfo
    )
}

/**
 * Function to group credentials by issuer and account name.
 * 
 * @param oathCredentials List of OATH credentials to group
 * @param pushCredentials List of Push credentials to group
 * @param shouldCombine Whether to combine credentials with the same issuer and account name
 */
fun groupCredentialsByAccount(
    oathCredentials: List<OathCredential>,
    pushCredentials: List<PushCredential>,
    shouldCombine: Boolean = true
): List<AccountGroup> {
    val accountGroups = mutableMapOf<Pair<String, String>, AccountGroup>()
    
    // If we're not combining accounts, create separate account groups
    if (!shouldCombine) {
        val separateGroups = mutableMapOf<String, AccountGroup>()
        
        // Create individual OATH account groups with unique identifiers
        oathCredentials.forEach { credential ->
            val groupKey = "${credential.issuer}-${credential.accountName}-oath-${credential.id}"
            separateGroups[groupKey] = AccountGroup(
                issuer = credential.issuer,
                accountName = credential.accountName,
                displayIssuer = credential.displayIssuer,
                displayAccountName = credential.displayAccountName,
                oathCredentials = listOf(credential),
                pushCredentials = emptyList()
            )
        }
        
        // Create individual Push account groups with unique identifiers
        pushCredentials.forEach { credential ->
            val groupKey = "${credential.issuer}-${credential.accountName}-push-${credential.id}"
            separateGroups[groupKey] = AccountGroup(
                issuer = credential.issuer,
                accountName = credential.accountName,
                displayIssuer = credential.displayIssuer,
                displayAccountName = credential.displayAccountName,
                oathCredentials = emptyList(),
                pushCredentials = listOf(credential)
            )
        }
        
        return separateGroups.values.toList()
    }
    
    // Otherwise, combine accounts with the same issuer and account name
    // Add OATH credentials to groups
    for (credential in oathCredentials) {
        val key = Pair(credential.issuer, credential.accountName)
        val existingGroup = accountGroups[key] ?: AccountGroup(
            issuer = credential.issuer,
            accountName = credential.accountName,
            displayIssuer = credential.displayIssuer,
            displayAccountName = credential.displayAccountName,
            oathCredentials = emptyList(),
            pushCredentials = emptyList()
        )
        // Update display names if the new credential has them
        val updatedDisplayIssuer = credential.displayIssuer
        val updatedDisplayAccountName = credential.displayAccountName
        
        accountGroups[key] = existingGroup.copy(
            displayIssuer = updatedDisplayIssuer,
            displayAccountName = updatedDisplayAccountName,
            oathCredentials = existingGroup.oathCredentials + credential
        )
    }
    
    // Add Push credentials to groups
    for (credential in pushCredentials) {
        val key = Pair(credential.issuer, credential.accountName)
        val existingGroup = accountGroups[key] ?: AccountGroup(
            issuer = credential.issuer,
            accountName = credential.accountName,
            displayIssuer = credential.displayIssuer,
            displayAccountName = credential.displayAccountName,
            oathCredentials = emptyList(),
            pushCredentials = emptyList()
        )
        // Update display names if the new credential has them
        val updatedDisplayIssuer = credential.displayIssuer
        val updatedDisplayAccountName = credential.displayAccountName
        
        accountGroups[key] = existingGroup.copy(
            displayIssuer = updatedDisplayIssuer,
            displayAccountName = updatedDisplayAccountName,
            pushCredentials = existingGroup.pushCredentials + credential
        )
    }
    
    return accountGroups.values.toList()
}

/**
 * Data class to hold parsed user agent information.
 */
data class DeviceInfo(
    val userAgent: String,
    val browser: String? = null,
    val os: String? = null,
    val browserVersion: String? = null
)

fun parseUserAgent(userAgent: String): DeviceInfo {
    val browser = getBrowser(userAgent)
    val os = getOs(userAgent)
    val browserVersion = getBrowserVersion(userAgent, browser)
    return DeviceInfo(userAgent, browser, os, browserVersion)
}

private fun getBrowser(userAgent: String): String {
    return when {
        userAgent.contains("Chrome") -> "Chrome"
        userAgent.contains("Firefox") -> "Firefox"
        userAgent.contains("Safari") -> "Safari"
        userAgent.contains("Edge") -> "Edge"
        userAgent.contains("MSIE") || userAgent.contains("Trident") -> "Internet Explorer"
        else -> "Unknown"
    }
}

private fun getOs(userAgent: String): String {
    return when {
        userAgent.contains("Windows") -> "Windows"
        userAgent.contains("Macintosh") -> "macOS"
        userAgent.contains("Linux") -> "Linux"
        userAgent.contains("Android") -> "Android"
        userAgent.contains("iPhone") || userAgent.contains("iPad") -> "iOS"
        else -> "Unknown"
    }
}

private fun getBrowserVersion(userAgent: String, browser: String): String? {
    return try {
        val regex = when (browser) {
            "Chrome" -> "Chrome/(\\S+)"
            "Firefox" -> "Firefox/(\\S+)"
            "Safari" -> "Version/(\\S+)"
            "Edge" -> "Edge/(\\S+)"
            "Internet Explorer" -> "MSIE (\\S+);|rv:(\\S+)"
            else -> return null
        }
        val matchResult = Regex(regex).find(userAgent)
        matchResult?.groups?.get(1)?.value
    } catch (_: Exception) {
        null
    }
}

/**
 * Data classes for Nominatim reverse geocoding API response
 */
@Serializable
data class NominatimAddress(
    @SerialName("city") val city: String? = null,
    @SerialName("town") val town: String? = null,
    @SerialName("village") val village: String? = null,
    @SerialName("state") val state: String? = null,
    @SerialName("state_district") val stateDistrict: String? = null,
    @SerialName("county") val county: String? = null,
    @SerialName("country") val country: String? = null,
    @SerialName("country_code") val countryCode: String? = null
)

@Serializable
data class NominatimResponse(
    @SerialName("place_id") val placeId: Long? = null,
    @SerialName("licence") val licence: String? = null,
    @SerialName("osm_type") val osmType: String? = null,
    @SerialName("osm_id") val osmId: Long? = null,
    @SerialName("lat") val lat: String? = null,
    @SerialName("lon") val lon: String? = null,
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("address") val address: NominatimAddress? = null
)

/**
 * Data class with simplified address data for UI display
 */
data class LocationAddress(
    val city: String,
    val state: String,
    val country: String
) {
    companion object {
        fun fromNominatim(response: NominatimResponse): LocationAddress? {
            val address = response.address ?: return null

            // Get city (try city, town, then village)
            val city = address.city
                ?: address.town
                ?: address.village
                ?: return null

            // Get state/province (try state, then state_district, then county)
            val state = address.state
                ?: address.stateDistrict
                ?: address.county
                ?: return null

            // Get country
            val country = address.country ?: return null

            return LocationAddress(
                city = city,
                state = state,
                country = country
            )
        }
    }

    /**
     * Format address for display in UI
     */
    fun formatForDisplay(): String {
        return "$city, $state, $country"
    }
}

/**
 * Get the appropriate lock message for a locked account based on the locking policy.
 * Returns the string resource ID for the appropriate message.
 */
@Composable
fun getLockMessage(lockingPolicy: String?): String {
    return when (lockingPolicy?.lowercase()) {
        BiometricAvailablePolicy.POLICY_NAME -> stringResource(id = R.string.account_locked_biometric_available)
        DeviceTamperingPolicy.POLICY_NAME -> stringResource(id = R.string.account_locked_device_tampering)
        null -> stringResource(id = R.string.account_locked_unknown_policy)
        else -> stringResource(id = R.string.account_locked_generic_policy, lockingPolicy)
    }
}