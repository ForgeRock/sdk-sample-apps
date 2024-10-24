/*
 * forgerock-sample-web-react
 *
 * flow-link.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

export default function flowLinkComponent(formEl, collector, flow, renderForm) {
  const button = document.createElement('button');

  button.classList.add('flow-link');
  button.type = 'button';
  button.innerText = collector.output.label;

  formEl?.appendChild(button);

  button.addEventListener('click', async () => {
    const node = await flow(collector.output.key);
    renderForm(node);
  });
}
