/*
 * ping-sample-web-react-davinci
 *
 * unknown.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';

/**
 * @function Unknown- React component used for displaying Unknown callback
 * @returns {Object} - React component object
 */
export default function Unknown({ collector }) {
  const collectorType = collector.type;

  return (
    <div className="form-group">
      <p>{`Warning: unknown collector type, ${collectorType}, isn't handled`}</p>
    </div>
  );
}
