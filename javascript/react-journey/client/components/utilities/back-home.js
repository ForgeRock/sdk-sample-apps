/*
 * ping-sample-web-react-journey
 *
 * back-home.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext } from 'react';
import { Link } from 'react-router-dom';

import { ThemeContext } from '../../context/theme.context';
import LeftArrowIcon from '../icons/left-arrow-icon';

export default function BackHome() {
  const theme = useContext(ThemeContext);
  const bootstrapClasses = 'btn btn-sm text-bold text-decoration-none d-inline-block fs-6 my-2';

  return (
    <Link
      className={`cstm_back-home ${bootstrapClasses} ${
        theme.mode === 'dark' ? 'cstm_back-home_dark' : ''
      }`}
      to="/"
    >
      <LeftArrowIcon />
      Home
    </Link>
  );
}
