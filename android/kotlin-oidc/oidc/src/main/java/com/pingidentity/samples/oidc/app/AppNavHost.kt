/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app

import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.pingidentity.samples.oidc.app.centralize.Centralize
import com.pingidentity.samples.oidc.app.centralize.CentralizeLoginViewModel
import com.pingidentity.samples.oidc.app.token.Token
import com.pingidentity.samples.oidc.app.userprofile.UserProfile
import com.pingidentity.samples.oidc.app.userprofile.UserProfileViewModel

@Composable
fun AppNavHost(
    navController: NavHostController,
    startDestination: String = Destinations.CENTRALIZE_ROUTE,
) {
    NavHost(
        navController = navController,
        startDestination = startDestination,
    ) {
        composable(Destinations.TOKEN_ROUTE) {
            Token()
        }
        composable(Destinations.USER_INFO) {
            val userProfileViewModel = viewModel<UserProfileViewModel>()
            UserProfile(userProfileViewModel)
        }
        composable(Destinations.CENTRALIZE_ROUTE) {
            val centralizeLoginViewModel = viewModel<CentralizeLoginViewModel>()
            Centralize(centralizeLoginViewModel) {
                navController.navigate(Destinations.USER_INFO)
            }
        }
    }
}
