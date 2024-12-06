/*
 * forgerock-react-native-sample
 *
 * text.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import {SafeAreaView, SafeAreaProvider} from 'react-native-safe-area-context';
import {StyleSheet, TextInput} from 'react-native';

/*
 * Please ensure you have created an .env.js from the
 * .env.example.js template!
 */
import { DEBUGGER_OFF } from '../../../.env';
import { handleFailedPolicies } from './utilities';

/**
 * @function Text - React component used for displaying regular text inputs
 * @param {Object} props - React props object passed from parent
 * @param {Object} props.callback - The callback object from AM
 * @returns {Object} - React component object
 */
export default function TextInputField({ callback }) {
  /********************************************************************
   * JAVASCRIPT SDK INTEGRATION POINT
   * Summary: Utilize Callback methods
   * ------------------------------------------------------------------
   *  Details: Because we wrap our responses in FRStep using the Javascript SDK
   *  we have access to helper methods to set, and retrieve information from our response.
   *  Referencing these helper methods allows us to avoid managing the state
   *  in our own application and leverage the SDK to do so
   *  *************************************************************** */
  if (!DEBUGGER_OFF) debugger;
  

  const error = handleFailedPolicies(
    callback.getFailedPolicies ? callback.getFailedPolicies() : [],
  );
  const isRequired = callback.isRequired ? callback.isRequired() : false;
  const label = callback.getPrompt();
  const setText = (text) => callback.setInputValue(text);

  return (
    <SafeAreaProvider>
      <SafeAreaView>
        <TextInput
          autoCapitalize="none"
          style={styles.input}
          onChangeText= {setText}
        />
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

 const styles = StyleSheet.create({
  container: {
    marginVertical: 10,
  },
  label: {
    fontSize: 16,
    marginBottom: 5,
    color: '#333',
  },
  required: {
    color: 'red',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 5,
    padding: 10,
    fontSize: 16,
    backgroundColor: '#fff',
  },
  inputError: {
    borderColor: 'red',
  },
  errorText: {
    marginTop: 5,
    fontSize: 14,
    color: 'red',
  },
});

