/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.managers

import android.util.Base64
import com.pingidentity.mfa.oath.OathAlgorithm
import com.pingidentity.mfa.oath.OathCredential
import com.pingidentity.mfa.oath.OathType
import com.pingidentity.mfa.push.PushCredential
import java.util.UUID

/**
 * Factory class for creating test accounts for development and testing purposes.
 * Provides utilities to generate random OATH, Push, and combined MFA accounts.
 */
class TestAccountFactory {
    
    companion object {
        private val RANDOM_ACCOUNT_RANGE = 1000..9999
        private const val TEST_SERVER_ENDPOINT = "https://test.example.com/push"
        private const val SECRET_LENGTH = 32
    }

    /**
     * Creates a random OATH account for testing.
     */
    fun createRandomOathAccount(): Pair<String, String> {
        // Generate a random TOTP URI
        val randomNumber = RANDOM_ACCOUNT_RANGE.random()
        val issuer = "TestIssuer-${randomNumber}"
        val accountName = "test.user${randomNumber}@example.com"
        val secret = generateRandomBase32Secret()
        val uri = "otpauth://totp/$issuer:$accountName?secret=$secret&issuer=$issuer&algorithm=SHA1&digits=6&period=30"
        
        return Pair(uri, "Random OATH account created: $issuer")
    }

    /**
     * Creates a random Push credential for testing.
     */
    fun createRandomPushCredential(): Pair<PushCredential, String> {
        // Generate a random account name and issuer
        val randomNumber = RANDOM_ACCOUNT_RANGE.random()
        val issuer = "TestIssuer-${randomNumber}"
        val accountName = "test.user${randomNumber}@example.com"
        val userId = "user-${UUID.randomUUID().toString().substring(0, 8)}"
        
        // Generate a random shared secret
        val sharedSecret = generateRandomBase32Secret()
        
        // Create a fake registration endpoint and authentication endpoint
        val serverEndpoint = TEST_SERVER_ENDPOINT
        
        // Create a new PushCredential
        val credential = PushCredential(
            id = UUID.randomUUID().toString(),
            accountName = accountName,
            issuer = issuer,
            userId = userId,
            sharedSecret = Base64.encodeToString(sharedSecret.toByteArray(), Base64.NO_WRAP),
            serverEndpoint = serverEndpoint
        )
        
        return Pair(credential, "Created test push account: $accountName")
    }

    /**
     * Creates random combined OATH and Push credentials for the same account.
     */
    fun createRandomCombinedMfaCredentials(): Triple<PushCredential, OathCredential, String> {
        // Generate a random account name and issuer
        val randomNumber = RANDOM_ACCOUNT_RANGE.random()
        val issuer = "TestIssuer-${randomNumber}"
        val accountName = "test.user${randomNumber}@example.com"
        val userId = "user-${UUID.randomUUID().toString().substring(0, 8)}"

        // Generate a random shared secret
        val sharedSecret = generateRandomBase32Secret()

        // Create a fake registration endpoint and authentication endpoint
        val serverEndpoint = TEST_SERVER_ENDPOINT

        // Create a new PushCredential
        val pushCredential = PushCredential(
            id = UUID.randomUUID().toString(),
            accountName = accountName,
            issuer = issuer,
            userId = userId,
            sharedSecret = Base64.encodeToString(sharedSecret.toByteArray(), Base64.NO_WRAP),
            serverEndpoint = serverEndpoint
        )

        // Create a new OATH Credential
        val oathCredential = OathCredential(
            id = UUID.randomUUID().toString(),
            accountName = accountName,
            issuer = issuer,
            oathType = OathType.TOTP,
            oathAlgorithm = OathAlgorithm.SHA1,
            digits = 6,
            period = 30,
            secret = sharedSecret
        )

        return Triple(pushCredential, oathCredential, "Created test combined account: $accountName")
    }

    /**
     * Generates a random Base32 string for OATH secrets
     */
    private fun generateRandomBase32Secret(): String {
        val base32Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        return (1..SECRET_LENGTH)
            .map { base32Chars.random() }
            .joinToString("")
    }
}