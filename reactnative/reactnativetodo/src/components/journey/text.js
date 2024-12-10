/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { FormControl } from 'native-base';
import React from 'react';
import {TextInput} from 'react-native';

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
export default function Text({ callback }) {
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
    <FormControl isRequired={isRequired} isInvalid={error}>
      <FormControl.Label mb={0}>{label}</FormControl.Label>
      <TextInput
          autoCapitalize="none"
          onChangeText= {setText}
        />
      <FormControl.ErrorMessage>
        {error.length ? error : ''}
      </FormControl.ErrorMessage>
    </FormControl>
  );
}
