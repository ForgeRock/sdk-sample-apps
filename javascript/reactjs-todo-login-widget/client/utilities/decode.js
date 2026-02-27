/*
 * forgerock-sample-web-react
 *
 * decode.js
 *
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/**
 * @function htmlDecode - Decodes HTML encoded strings
 * @param {string} input - string that needs to be HTML decoded
 * @returns {string} - decoded string
 */
export function htmlDecode(input) {
  const e = document.createElement('div');
  e.innerHTML = input;
  return e.childNodes.length === 0 ? '' : e.childNodes[0].nodeValue;
}
