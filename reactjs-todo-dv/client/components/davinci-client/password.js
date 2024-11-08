/*
 * forgerock-sample-web-react
 *
 * password.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useState, useContext } from 'react';
import { AppContext } from '../../global-state';
import EyeIcon from '../icons/eye-icon';

const Password = ({ collector, updater }) => {
  const [appState, methods] = useContext(AppContext);
  const [isVisible, setVisibility] = useState(false);

  /**
   * @function toggleVisibility - toggles the password from masked to plaintext
   */
  function toggleVisibility() {
    setVisibility(!isVisible);
  }

  return (
    <div
      key={`div-${collector.output.key}`}
      className="cstm_form-floating input-group form-floating mb-3"
    >
      <input
        className={`cstm_input-password form-control border-end-0 bg-transparent ${appState.theme.textClass} ${appState.theme.borderClass}`}
        id={collector.output.key}
        name={collector.output.key}
        type={isVisible ? 'text' : 'password'}
        onBlur={(e) => updater(e.target.value)}
        key={collector.output.key}
      />
      <label key={`label-${collector.output.key}`} htmlFor={collector.output.key}>
        {collector.output.label}
      </label>
      <button
        className={`cstm_input-icon border-start-0 input-group-text bg-transparent ${appState.theme.textClass} ${appState.theme.borderClass}`}
        onClick={toggleVisibility}
        type="button"
        key={`eye-icon-btn-${collector.output.key}`}
      >
        <EyeIcon key={`eye-icon-${collector.output.key}`} visible={isVisible} />
      </button>
    </div>
  );
};

export default Password;
