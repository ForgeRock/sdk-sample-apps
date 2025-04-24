/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.InvalidLength
import com.pingidentity.davinci.collector.MaxRepeat
import com.pingidentity.davinci.collector.MinCharacters
import com.pingidentity.davinci.collector.RegexError
import com.pingidentity.davinci.collector.Required
import com.pingidentity.davinci.collector.UniqueCharacter
import com.pingidentity.davinci.collector.ValidationError

@Composable
fun ErrorMessage(errors: List<ValidationError>) {
    if (errors.isEmpty()) return // Don't display if there are no errors

    Column(modifier = Modifier.padding(8.dp)) {
        for (error in errors) {
            androidx.compose.material3.Text(
                text = getErrorMessage(error),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.error,
                modifier = Modifier.padding(vertical = 4.dp)
            )
        }
    }
}

fun getErrorMessage(error: ValidationError): String {
    return when (error) {
        is Required -> "This field cannot be empty."
        is RegexError -> "The input format is invalid."
        is InvalidLength -> "The input length must be between ${error.min} and ${error.max} characters."
        is UniqueCharacter -> "The input must contain at least ${error.min} unique characters."
        is MaxRepeat -> "The input contains too many repeated characters. Maximum allowed repeats: ${error.max}."
        is MinCharacters -> "The input must include at least ${error.min} character(s) from this set: '${error.character}'."
        else -> "Invalid input. Please check the provided value."
    }
}