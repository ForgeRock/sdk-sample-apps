/*
 * forgerock-react-native-sample
 *
 * toggle.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useState, useCallback } from 'react';

/**
 * @function useToggle - Handles the state of the todo
 * @param {boolean} initialState - state of the todo: completed or not
 * @returns {Array} - Conventional state and method items in array
 */
export default function useToggle(initialState = false) {
  const [state, setState] = useState(initialState);
  const toggle = useCallback(() => setState((bool) => !bool), []);
  return [state, toggle];
}
