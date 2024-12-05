/*
 * forgerock-react-native-sample
 *
 * choice.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { FormControl, Select } from 'native-base';
import React from 'react';

/*
 * Please ensure you have created an .env.js from the
 * .env.example.js template!
 */
import { DEBUGGER_OFF } from '../../../.env';

/**
 * @function Choice - React component used for displaying choices
 * @param {Object} props - React props object passed from parent
 * @param {Object} props.callback - The callback object from AM
 * @returns {Object} - React component object
 */
export default function Choice({ callback }) {
  /** *************************************************************************
   * SDK INTEGRATION POINT
   * Summary: SDK callback methods for getting values
   * --------------------------------------------------------------------------
   * Details: Each callback is wrapped by the SDK to provide helper methods
   * for accessing values from the callbacks received from AM
   ************************************************************************* */
  if (!DEBUGGER_OFF) debugger;
  const label = callback.getPrompt();
  const choiceOptions = callback.getChoices();
  const defaultChoice = callback.getDefaultChoice();
  const isRequired = callback.isRequired ? callback.isRequired() : false;

  /**
   * @function setValue - Sets the value on the callback on element blur (lose focus)
   * @param {Object} event
   */
  function setValue(value) {
    /** ***********************************************************************
     * SDK INTEGRATION POINT
     * Summary: SDK callback methods for setting values
     * ------------------------------------------------------------------------
     * Details: Each callback is wrapped by the SDK to provide helper methods
     * for writing values to the callbacks received from AM
     *********************************************************************** */
    callback.setChoiceIndex(value);
  }

  return (
    <FormControl isRequired={isRequired}>
      <FormControl.Label mb={0}>{label}</FormControl.Label>
      <Select
        accessibilityLabel={label}
        fontSize="lg"
        onValueChange={setValue}
        placeholder={label}
        selectedValue={defaultChoice}
      >
        {choiceOptions.map((option, idx) => (
          <Select.Item label={option} key={idx} value={option} />
        ))}
      </Select>
    </FormControl>
  );
}
