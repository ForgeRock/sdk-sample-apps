/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.example.app

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBox
import androidx.compose.material.icons.filled.GeneratingTokens
import androidx.compose.material.icons.filled.ListAlt
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.OpenInBrowser
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.NavigationDrawerItem
import androidx.compose.material3.NavigationDrawerItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.example.app.Destinations.CENTRALIZE_ROUTE
import com.example.app.Destinations.ENV_ROUTE
import com.example.app.Destinations.TOKEN_ROUTE
import com.example.app.Destinations.USER_PROFILE
import org.forgerock.android.auth.FRUser

/**
 * AppDrawer component to show the drawer.
 * @param navigateTo Function1<String, Unit> the navigation function.
 * @param closeDrawer Function0<Unit> the close drawer function.
 */
@Composable
fun AppDrawer(
    navigateTo: (String) -> Unit,
    closeDrawer: () -> Unit) {

    val scroll = rememberScrollState(0)

    ModalDrawerSheet(
        modifier = Modifier
            .verticalScroll(scroll)) {
        Logo(
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
        )
        NavigationDrawerItem(
            label = { Text("Environment Config") },
            selected = false,
            icon = { Icon(Icons.Filled.ListAlt, null) },
            onClick = { navigateTo(ENV_ROUTE); closeDrawer() },
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
        )
        NavigationDrawerItem(
            label = { Text("Launch OIDC Redirect Login") },
            selected = false,
            icon = { Icon(Icons.Filled.OpenInBrowser, null) },
            onClick = {
                navigateTo(CENTRALIZE_ROUTE);
                closeDrawer()
            },
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
        )
        NavigationDrawerItem(
            label = { Text("Show Token") },
            selected = false,
            icon = { Icon(Icons.Filled.GeneratingTokens, null) },
            onClick = {
                navigateTo(TOKEN_ROUTE);
                closeDrawer()
            },
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
        )
        NavigationDrawerItem(
            label = { Text("User Profile") },
            selected = false,
            icon = { Icon(Icons.Filled.AccountBox, null) },
            onClick = {
                navigateTo(USER_PROFILE);
                closeDrawer()
            },
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
        )
        NavigationDrawerItem(
            label = { Text("Logout") },
            selected = false,
            icon = { Icon(Icons.Filled.Logout, null) },
            onClick = {
                FRUser.getCurrentUser()?.logout()
                navigateTo(ENV_ROUTE)
                closeDrawer()
            },
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
        )
    }
}

@Composable
private fun Logo(modifier: Modifier) {
    Row(modifier = Modifier
        .fillMaxWidth()
        .background(colorResource(id = R.color.black))
        .then(modifier)) {
        Icon(
            painterResource(R.drawable.ping_logo),
            contentDescription = null,
            modifier = Modifier
                .height(100.dp).padding(8.dp)
                .then(modifier),
            tint = Color.Unspecified,
        )
    }

}