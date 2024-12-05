/*
 * forgerock-sample-web-react
 *
 * global-state.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import AsyncStorage from '@react-native-async-storage/async-storage';
import React, { useEffect, useState } from 'react';
import { NativeModules } from 'react-native';

/*
 * Please ensure you have created an .env.js from the
 * .env.example.js template!
 */
import { DEBUGGER_OFF } from '../.env';

const { FRAuthSampleBridge } = NativeModules;

/**
 * @function useStateMgmt - The global state/store for managing user authentication and page
 * @param {Object} props - The object representing React's props
 * @param {boolean} props.authenticated - Boolean value of user's auth status
 * @param {string} props.email - User's email
 * @param {string} props.name - User's full name
 * @returns {Array} - Global state values and state methods
 */
export function useGlobalStateMgmt(props) {
  const [authenticated, setAuthentication] = useState(
    props.authenticated || null,
  );
  const [email, setEmail] = useState(props.email || '');
  const [name, setName] = useState(props.name || '');

  /**
   * Asynchronously check if we have stored information; replace with stored
   * values if defaults are used.
   */
  useEffect(() => {
    async function checkTemporaryStorage() {
      try {
        let storedAuthenticated = await AsyncStorage.getItem('authenticated');
        let storedEmail = await AsyncStorage.getItem('email');
        let storedName = await AsyncStorage.getItem('name');

        setAuthentication(storedAuthenticated === 'true' ? true : false);
        setEmail(storedEmail);
        setName(storedName);
      } catch (err) {
        console.warn('Issue with retrieving values from temp storage');
      }
    }

    /**
     * If defaults are used, check to see if we have stored values
     */
    if (authenticated === null && !email && !name) {
      checkTemporaryStorage();
    }
    // Just run on initial execution
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /**
   * @function setAuthenticationWrapper - A wrapper for storing authentication in storage
   * @param {boolean} value - current user authentication
   * @returns {void}
   */
  async function setAuthenticationWrapper(value) {
    if (value === false) {
      /** *********************************************************************
       * NATIVE BRIDGE SDK INTEGRATION POINT
       * Summary: Logout, end session and revoke tokens
       * ----------------------------------------------------------------------
       * Details: Since this method is a global method via the Context API,
       * any part of the application can log a user out. This is helpful when
       * APIs are called and we get a 401 response.
       ********************************************************************* */
      if (!DEBUGGER_OFF) debugger;
      await FRAuthSampleBridge.logout();
      await setEmailWrapper('');
      await setNameWrapper('');
    }
    try {
      await AsyncStorage.setItem('authenticated', JSON.stringify(value));
    } catch (err) {
      console.warn('Issue with saving authenticated value to temp storage');
    }
    setAuthentication(value);
  }

  /**
   * @function setEmailWrapper - A wrapper for storing authentication in storage
   * @param {string} value - current user's email
   * @returns {void}
   */
  async function setEmailWrapper(value) {
    try {
      await AsyncStorage.setItem('email', value);
    } catch (err) {
      console.warn('Issue with saving email value to temp storage');
    }
    setEmail(value);
  }

  /**
   * @function setUserWrapper - A wrapper for storing authentication in storage
   * @param {string} value - current user's username
   * @returns {void}
   */
  async function setNameWrapper(value) {
    try {
      await AsyncStorage.setItem('name', value);
    } catch (err) {
      console.warn('Issue with saving name value to temp storage');
    }
    setName(value);
  }

  /**
   * returns an array with state object as index zero and setters as index one
   */
  return [
    {
      authenticated,
      email,
      name,
    },
    {
      setAuthentication: setAuthenticationWrapper,
      setEmail: setEmailWrapper,
      setName: setNameWrapper,
    },
  ];
}

/**
 * @constant AppContext - Creates React Context API
 * This provides the capability to set a global state in React
 * without having to pass the state as props through parent-child components.
 */
export const AppContext = React.createContext([{}, {}]);
