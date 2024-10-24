/*
 * forgerock-sample-web-react
 *
 * submit-button.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

export default function submitButtonComponent(formEl, collector) {
  const button = document.createElement('button');
  button.type = 'submit';
  button.innerText = collector.output.label;
  button.value = collector.output.key;
  formEl?.appendChild(button);
}
