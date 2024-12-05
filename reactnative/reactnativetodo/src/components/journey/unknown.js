/*
 * forgerock-react-native-sample
 *
 * unknown.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { FormControl } from 'native-base';
import React from 'react';

/**
 * @function Unknown - React component used for displaying unknown callbacks
 * @param {Object} props - React props object passed from parent
 * @param {Object} props.callback - The callback object from AM
 * @returns {Object} - React component object
 */
export default function Unknown({ callback }) {
  const callbackType = callback.getType();
  return (
    <FormControl isInvalid>
      <FormControl.ErrorMessage>
        {`Warning: unknown callback type, ${callbackType}, isn't handled`}
      </FormControl.ErrorMessage>
    </FormControl>
  );
}
