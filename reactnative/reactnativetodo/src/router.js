/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */


import React, { useContext, useEffect } from 'react';
import { NativeModules } from 'react-native';
import MaterialCommunityIcons from 'react-native-vector-icons/MaterialCommunityIcons';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { NavigationContainer } from '@react-navigation/native';

import { DEBUGGER_OFF } from '../.env';
import Home from './screens/home';
import Login from './screens/login';
import Logout from './screens/logout';
import Register from './screens/register';
import Todos from './screens/todos';

const { FRAuthSampleBridge } = NativeModules;

const Tab = createBottomTabNavigator();
const tabBarOptions = {
  tabBarLabelStyle: {
    fontSize: 12,
  },
  tabBarStyle: { height: 85, paddingTop: 5 },
};

import { AppContext } from './global-state';

export default function Navigation() {
  // Used for getting the global authentication state
  const [{ authenticated }, { setAuthentication }] = useContext(AppContext);

  useEffect(() => {
    async function getUserInfo() {
      try {
        /** *********************************************************************
         * NATIVE BRIDGE SDK INTEGRATION POINT
         * Summary: Logout, end session and revoke tokens
         * ----------------------------------------------------------------------
         * Details: This is a bit overkill in most situations, but this is the most
         * strict way of protecting a route. Other options are just checking
         * global state (remove this useEffect entirely), or checking for
         * stored tokens (instead, call `getAccessToken`).
         ********************************************************************* */
        if (!DEBUGGER_OFF) debugger;
        await FRAuthSampleBridge.getUserInfo();
      } catch (err) {
        console.info('User has been logged out.');
        /**
         * If the above getUserInfo fails, then the user has been
         * logged out, so clear our global state.
         */
        setAuthentication(false);
      }
    }
    if (authenticated) {
      getUserInfo();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [authenticated]);

  if (!authenticated) {
    return (
      <NavigationContainer>
        <Tab.Navigator screenOptions={tabBarOptions}>
          <Tab.Screen
            component={Home}
            name="Home"
            options={{
              tabBarLabel: 'Home',
              tabBarIcon: ({ color, size }) => (
                <MaterialCommunityIcons name="home" color={color} size={size} />
              ),
            }}
          />
          <Tab.Screen
            component={Login}
            name="Sign In"
            options={{
              tabBarLabel: 'Sign In',
              tabBarIcon: ({ color, size }) => (
                <MaterialCommunityIcons name="key" color={color} size={size} />
              ),
            }}
          />
          <Tab.Screen
            component={Register}
            name="Sign Up"
            options={{
              tabBarLabel: 'Sign Up',
              tabBarIcon: ({ color, size }) => (
                <MaterialCommunityIcons
                  name="account-plus"
                  color={color}
                  size={size}
                />
              ),
            }}
          />
        </Tab.Navigator>
      </NavigationContainer>
    );
  } else {
    return (
      <NavigationContainer>
        <Tab.Navigator screenOptions={tabBarOptions}>
          <Tab.Screen
            component={Home}
            name="Home"
            options={{
              tabBarLabel: 'Home',
              tabBarIcon: ({ color, size }) => (
                <MaterialCommunityIcons name="home" color={color} size={size} />
              ),
            }}
          />
          <Tab.Screen
            component={Todos}
            name="Todos"
            options={{
              tabBarLabel: 'Todos',
              tabBarIcon: ({ color, size }) => (
                <MaterialCommunityIcons
                  name="check-all"
                  color={color}
                  size={size}
                />
              ),
            }}
          />
          <Tab.Screen
            component={Logout}
            name="Sign Out"
            options={{
              tabBarLabel: 'Sign Out',
              tabBarIcon: ({ color, size }) => (
                <MaterialCommunityIcons
                  name="logout"
                  color={color}
                  size={size}
                />
              ),
            }}
          />
        </Tab.Navigator>
      </NavigationContainer>
    );
  }
}
