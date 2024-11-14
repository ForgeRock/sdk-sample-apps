/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */


package com.example.app

import androidx.compose.runtime.Composable

import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController

import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable

import com.example.app.centralize.Centralize
import com.example.app.centralize.CentralizeLoginViewModel
import com.example.app.env.EnvRoute

import com.example.app.token.Token
import com.example.app.token.TokenViewModel
import com.example.app.userprofile.UserProfile
import com.example.app.userprofile.UserProfileViewModel

/**
 * AppNavHost to handle the navigation.
 * @param navController NavHostController the navigation controller.
 * @param configViewModel ConfigViewModel the config view model.
 * @param startDestination String the start destination.
 */
@Composable
fun AppNavHost(navController: NavHostController,
               configViewModel: ConfigViewModel,
               startDestination: String = Destinations.ENV_ROUTE) {

    NavHost(navController = navController,
        startDestination = startDestination) {

        composable(Destinations.ENV_ROUTE) {
            EnvRoute(configViewModel) {
                navController.navigate(Destinations.CENTRALIZE_ROUTE) {
                    launchSingleTop = true
                }
            }
        }

        composable(Destinations.TOKEN_ROUTE) {
            val tokenViewModel = viewModel<TokenViewModel>()
            Token(tokenViewModel)
        }

        composable(Destinations.CENTRALIZE_ROUTE) {
            val centralizeLoginViewModel = viewModel<CentralizeLoginViewModel>()
            Centralize(centralizeLoginViewModel) {
                navController.navigate(Destinations.TOKEN_ROUTE) {
                    launchSingleTop = true
                }
            }
        }

        composable(Destinations.USER_PROFILE) {
            val userProfileViewModel = viewModel<UserProfileViewModel>()
            UserProfile(userProfileViewModel)
        }


    }
}