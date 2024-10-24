/*
 * forgerock-sample-web-react
 *
 * password.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

export default function passwordComponent(formEl, collector, updater) {
  const label = document.createElement('label');
  const input = document.createElement('input');

  label.htmlFor = collector.output.key;
  label.innerText = collector.output.label;
  input.type = 'password';
  input.id = collector.output.key;
  input.name = collector.output.key;

  formEl?.appendChild(label);
  formEl?.appendChild(input);

  formEl?.querySelector(`#${collector.output.key}`)?.addEventListener('blur', (event) => {
    updater(event.target.value);
  });
}
