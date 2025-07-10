/*
 * ping-sample-web-react-davinci
 *
 * protect.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useEffect, useState } from 'react';
import Loading from '../utilities/loading.js';

export default function Protect({ updater, submit }) {
  const [loading, setLoading] = useState(true);
  /**
   * The protect collector is sent with the first node of the flow, but
   * it is not needed. It is a self-submitting node which requires no
   * user interaction. While you would normally load the Protect module
   * here and wait for a response, we instead mock the response with a
   * dummy value and update the collector. Then call the
   * submit function to proceed with the flow.
   */
  useEffect(() => {
    async function handleProtect() {
      updater('fakeprofile');
      setLoading(false);
      if (submit !== undefined) {
        await submit();
      }
    }
    handleProtect();
  }, [updater, submit]);

  return loading ? <Loading key="loading-protect" /> : null;
}
