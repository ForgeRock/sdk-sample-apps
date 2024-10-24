/*
 * forgerock-sample-web-react
 *
 * protect.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

export default function (formEl, collector, updater) {
  // create paragraph element with text of "Loading ... "
  const p = document.createElement('p');

  p.innerText = collector.output.label;
  formEl?.appendChild(p);

  updater('fakeprofile');
}
