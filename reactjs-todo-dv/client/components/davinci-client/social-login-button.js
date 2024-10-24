/*
 * forgerock-sample-web-react
 *
 * social-login-button.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

export default function submitButtonComponent(formEl, collector) {
  const link = document.createElement('a');

  link.innerText = collector.output.label;
  link.href = collector.output?.url || '';

  formEl?.appendChild(link);
}
