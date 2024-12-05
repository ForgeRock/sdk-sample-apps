/*
 * forgerock-react-native-sample
 *
 * failed-policies.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';

import Choice from './choice';
import KBA from './kba';
import Password from './password';
import TermsAndConditions from './boolean';
import Text from './text';
import Unknown from './unknown';

/**
 * @function mapCallbacksToComponents - maps AM callbacks to a React component
 * @param {Object} cb - Callback from AM to map
 * @param {number} idx - Index number within map
 * @returns {Object} - React component
 */
export function mapCallbacksToComponents(cb, idx) {
  const name = cb?.payload?.input?.[0].name;

  /** *********************************************************************
   * JAVASCRIPT SDK INTEGRATION POINT
   * Summary: SDK callback method for getting the callback type
   * ----------------------------------------------------------------------
   * Details: This method is helpful in quickly identifying the callback
   * when iterating through an unknown list of AM callbacks
   ********************************************************************* */
  switch (cb.getType()) {
    case 'ChoiceCallback':
      return <Choice callback={cb} key={name} />;
    case 'NameCallback':
    case 'ValidatedCreateUsernameCallback':
    case 'StringAttributeInputCallback':
      return <Text callback={cb} key={name} />;
    case 'PasswordCallback':
    case 'ValidatedCreatePasswordCallback':
      return <Password callback={cb} key={name} />;
    case 'BooleanAttributeInputCallback':
      return <TermsAndConditions callback={cb} key={name} />;
    case 'TermsAndConditionsCallback':
      return <TermsAndConditions callback={cb} key={name} />;
    case 'KbaCreateCallback':
      return <KBA callback={cb} key={name} />;
    default:
      // If current callback is not supported, render a warning message
      return <Unknown callback={cb} key={`unknown-${idx}`} />;
  }
}

/**
 * @function handleFailedPolicies - Function for parsing failed policies for display
 * @param {Array} failedPolicies - Array of failed input policies
 * @returns {string} - String for display to user
 */
function handleFailedPolicies(failedPolicies = []) {
  /*
   * If failed policies is not an array, just return early
   */
  if (!Array.isArray(failedPolicies)) return '';

  if (failedPolicies?.length) {
    const validationFailure = failedPolicies.reduce((prev, curr) => {
      let failureObj;
      try {
        failureObj = JSON.parse(curr);
      } catch (err) {
        console.log(`Parsing failure for ${err.message}`);
      }

      switch (failureObj.policyRequirement) {
        case 'REQUIRED':
          prev = 'This field is required. ';
          break;
        case 'VALID_USERNAME':
          prev = 'Please choose a different username. ';
          break;
        case 'VALID_EMAIL_ADDRESS_FORMAT':
          prev = 'Please use a valid email address. ';
          break;
        default:
          prev = 'Please check this value for correctness.';
      }
      return prev;
    }, '');
    return validationFailure;
  }
  return '';
}

export { handleFailedPolicies };
