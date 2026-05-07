/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.service

import com.pingidentity.authenticatorapp.data.LocationAddress
import com.pingidentity.authenticatorapp.data.NominatimResponse
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.parameter
import io.ktor.serialization.kotlinx.json.json
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

/**
 * Service for performing reverse geocoding using OpenStreetMap's Nominatim API
 */
class LocationService {
    
    companion object {
        private const val NOMINATIM_BASE_URL = "https://nominatim.openstreetmap.org"
        private const val TIMEOUT_SECONDS = 10_000L
        
        // Nominatim usage policy requires setting a User-Agent
        private const val USER_AGENT = "PingAuthenticatorSampleApp/1.0"
    }
    
    private val httpClient = HttpClient(CIO) {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                coerceInputValues = true
            })
        }
        // Configure timeout
        install(HttpTimeout) {
            connectTimeoutMillis = TIMEOUT_SECONDS / 1000
            requestTimeoutMillis = TIMEOUT_SECONDS / 1000
        }
    }
    
    /**
     * Performs reverse geocoding to convert latitude/longitude to a human-readable address
     * 
     * @param latitude The latitude coordinate
     * @param longitude The longitude coordinate
     * @return LocationAddress with city, state, and country, or null if unable to resolve
     */
    suspend fun reverseGeocode(latitude: Double, longitude: Double): LocationAddress? {
        return withContext(Dispatchers.IO) {
            try {
                val response = httpClient.get("$NOMINATIM_BASE_URL/reverse") {
                    parameter("lat", latitude)
                    parameter("lon", longitude)
                    parameter("format", "json")
                    parameter("addressdetails", "1")
                    parameter("zoom", "10")
                    
                    // Required by Nominatim usage policy
                    header("User-Agent", USER_AGENT)
                }
                
                val nominatimResponse = response.body<NominatimResponse>()
                LocationAddress.fromNominatim(nominatimResponse)
                
            } catch (e: Exception) {
                // Log error but don't crash - return null to show coordinates as fallback
                println("LocationService: Failed to reverse geocode lat=$latitude, lon=$longitude: ${e.message}")
                null
            }
        }
    }
    
    /**
     * Clean up resources when done
     */
    fun close() {
        httpClient.close()
    }
}