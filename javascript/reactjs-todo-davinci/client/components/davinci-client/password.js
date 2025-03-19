/*
 * ping-sample-web-react-davinci
 *
 * password.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useState, useContext } from 'react';
import { AppContext } from '../../global-state';
import EyeIcon from '../icons/eye-icon';

const Password = ({ collector, inputName, updater }) => {
  const [state] = useContext(AppContext);
  const [isVisible, setVisibility] = useState(false);
  const passwordLabel = collector.output.label;

  /**
   * @function toggleVisibility - toggles the password from masked to plaintext
   */
  function toggleVisibility() {
    setVisibility(!isVisible);
  }

  return (
    <div className="cstm_form-floating input-group form-floating mb-3">
      <input
        className={`cstm_input-password form-control border-end-0 bg-transparent ${state.theme.textClass} ${state.theme.borderClass}`}
        id={inputName}
        name={inputName}
        type={isVisible ? 'text' : 'password'}
        onChange={(e) => updater(e.target.value)}
      />
      <label htmlFor={inputName}>{passwordLabel}</label>
      <button
        className={`cstm_input-icon border-start-0 input-group-text bg-transparent ${state.theme.textClass} ${state.theme.borderClass}`}
        onClick={toggleVisibility}
        type="button"
      >
        <EyeIcon visible={isVisible} />
      </button>
    </div>
  );
};

export default Password;
