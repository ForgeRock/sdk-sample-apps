/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.GeneratingTokens
import androidx.compose.material.icons.filled.OpenInBrowser
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.RocketLaunch
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
import com.pingidentity.samples.app.Destinations.CENTRALIZE_ROUTE
import com.pingidentity.samples.app.Destinations.DAVINCI
import com.pingidentity.samples.app.Destinations.LAUNCH_ROUTE
import com.pingidentity.samples.app.Destinations.TOKEN_ROUTE
import com.pingidentity.samples.app.Destinations.USER_INFO

@Composable
fun AppDrawer(
    logoutViewModel: LogoutViewModel,
    navigateTo: (String) -> Unit,
    closeDrawer: () -> Unit,
) {
    val scroll = rememberScrollState(0)

    ModalDrawerSheet(
        modifier =
        Modifier
            .verticalScroll(scroll),
    ) {
        Logo(
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding),
        )
        NavigationDrawerItem(
            label = { Text("Launch DaVinci") },
            selected = false,
            icon = { Icon(Icons.Filled.RocketLaunch, null) },
            onClick = {
                navigateTo(DAVINCI)
                closeDrawer()
            },
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding),
        )
        NavigationDrawerItem(
            label = { Text("Show Token") },
            selected = false,
            icon = { Icon(Icons.Filled.GeneratingTokens, null) },
            onClick = {
                navigateTo(TOKEN_ROUTE)
                closeDrawer()
            },
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding),
        )
        NavigationDrawerItem(
            label = { Text("User Info") },
            selected = false,
            icon = { Icon(Icons.Filled.Person, null) },
            onClick = {
                navigateTo(USER_INFO)
                closeDrawer()
            },
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding),
        )

        NavigationDrawerItem(
            label = { Text("Centralize Login") },
            selected = false,
            icon = { Icon(Icons.Filled.OpenInBrowser, null) },
            onClick = {
                navigateTo(CENTRALIZE_ROUTE)
                closeDrawer()
            },
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding),
        )
        NavigationDrawerItem(
            label = { Text("Logout") },
            selected = false,
            icon = { Icon(Icons.AutoMirrored.Filled.Logout, null) },
            onClick = {
                logoutViewModel.logout {
                    navigateTo(DAVINCI)
                }
                closeDrawer()
            },
            modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding),
        )
    }
}

@Composable
private fun Logo(modifier: Modifier) {
    Row(
        modifier =
        Modifier
            .fillMaxWidth()
            .background(colorResource(id = R.color.black))
            .then(modifier),
    ) {
        Icon(
            painterResource(R.drawable.logo_davinci_white),
            contentDescription = null,
            modifier =
            Modifier
                .height(100.dp)
                .padding(8.dp)
                .then(modifier),
            tint = Color.Unspecified,
        )
    }
}
