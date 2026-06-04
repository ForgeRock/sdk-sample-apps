/*
 * ping-sample-web-react-davinci
 *
 * error.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useState } from 'react';

export default function Error({ getError }) {
  const [error, setError] = useState(null);
  useEffect(() => {
    if (getError) {
      const err = getError();
      setError(err);
    }
  }, []);

  return error ? <pre>${error?.message ?? 'An Error Occured'}</pre> : null;
}
