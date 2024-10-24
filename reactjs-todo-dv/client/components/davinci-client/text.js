/*
 * forgerock-sample-web-react
 *
 * text.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

export default function usernameComponent(formEl, collector, updater) {
  const collectorKey = collector.output.key;
  const label = document.createElement('label');
  const input = document.createElement('input');

  label.htmlFor = collectorKey;
  label.innerText = collector.output.label;
  input.type = 'text';
  input.id = collectorKey;
  input.name = collectorKey;

  formEl?.appendChild(label);
  formEl?.appendChild(input);

  formEl?.querySelector(`#${collectorKey}`)?.addEventListener('input', (event) => {
    updater(event.target.value);
  });
}
