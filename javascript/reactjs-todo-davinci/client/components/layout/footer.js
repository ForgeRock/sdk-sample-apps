/*
 * ping-sample-web-react-davinci
 *
 * footer.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext } from 'react';

import { ThemeContext } from '../../context/theme.context.js';

/**
 * @function Footer - Footer React component
 * @returns {Object} - React component object
 */
export default function Footer() {
  const theme = useContext(ThemeContext);

  return (
    <div className="cstm_container container-fluid">
      <small
        className={`border-top d-block mt-5 py-5 ${theme.textClass} ${theme.borderHighContrastClass}`}
      >
        The React name and logomark are properties of <a href="https://reactjs.org">Facebook</a>,
        and their use herein is for learning and illustrative purposes only.
      </small>
    </div>
  );
}
