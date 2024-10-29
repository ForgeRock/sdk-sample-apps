/*
 * forgerock-sample-web-react
 *
 * flow-button.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';

export default function FlowButton({ collector, flow, renderForm }) {

  const clickHandler = async () => {
    const node = await flow(collector.output.key);
    renderForm(node);
  };

  return (
    <button
      key={collector.output.key}
      type="button"
      className="btn btn-primary w-100 flow-link mb-2"
      onClick={clickHandler}
    >
      <span> {collector.output.label}</span>
    </button>
  );
}
