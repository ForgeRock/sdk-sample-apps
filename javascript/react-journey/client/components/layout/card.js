/*
 * ping-sample-web-react-journey
 *
 * card.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext } from 'react';
import { ThemeContext } from '../../context/theme.context';

/**
 * @function Card - React component that displays the alert icon representing the a warning
 * @param {Object} props - React props object
 * @param {Object} props.children - The child React components that are passed in
 * @returns {Object} - React JSX Object
 */
export default function Card(props) {
  const theme = useContext(ThemeContext);

  return (
    <div className={`card shadow-sm p-5 mb-2 w-100 ${theme.cardBgClass} ${theme.textClass}`}>
      {props.children}
    </div>
  );
}
