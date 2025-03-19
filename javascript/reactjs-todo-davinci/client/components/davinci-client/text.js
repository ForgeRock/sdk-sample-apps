/*
 * ping-sample-web-react-davinci
 *
 * text.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext } from 'react';
import { AppContext } from '../../global-state';

const Text = ({ collector, inputName, updater }) => {
  const [state] = useContext(AppContext);

  return (
    <div className={`cstm_form-floating form-floating mb-3`}>
      <input
        className={`cstm_form-control form-control bg-transparent ${state.theme.textClass} ${state.theme.borderClass}`}
        id={inputName}
        name={inputName}
        onChange={(e) => updater(e.target.value)}
        type="text"
      />
      <label htmlFor={inputName}>{collector.output.label}</label>
    </div>
  );
};

export default Text;
