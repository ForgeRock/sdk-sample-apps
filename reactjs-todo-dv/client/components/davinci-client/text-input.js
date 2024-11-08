/*
 * forgerock-sample-web-react
 *
 * text-input.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext } from 'react';
import { AppContext } from '../../global-state';

const Text = ({ collector, updater }) => {
  const [appState, methods] = useContext(AppContext);

  return (
    <div key={`div-${collector.output.key}`} className={`cstm_form-floating form-floating mb-3`}>
      <input
        className={`cstm_form-control form-control bg-transparent ${appState.theme.textClass} ${appState.theme.borderClass}`}
        id={collector.output.key}
        name={collector.output.key}
        onChange={(e) => updater(e.target.value)}
        type="text"
        key={collector.output.key}
      />
      <label key={`label-${collector.output.key}`} htmlFor={collector.output.key}>
        {collector.output.label}
      </label>
    </div>
  );
};

export default Text;
