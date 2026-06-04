/*
 * ping-sample-web-react-davinci
 *
 * polling.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState, useEffect } from 'react';

import Loading from '../utilities/loading.js';

/**
 * @function PollingComponent - React component for DaVinci PollingCollector
 * @param {Object} props
 * @param {Object} props.collector - PollingCollector
 * @param {Function} props.pollStatus - Poller function returning the current poll status
 * @param {Function} props.updater - Updater bound to the PollingCollector
 * @param {Function} props.submitForm - Function to advance the DaVinci flow
 * @returns {Object} - React component
 */
export default function PollingComponent({ collector, cacheKey, pollStatus, updater, submitForm }) {
  const [isPolling, setIsPolling] = useState(false);
  const [error, setError] = useState(null);
  const [result, setResult] = useState(null);

  useEffect(() => {
    async function handlePoll() {
      setIsPolling(true);
      setError(null);
      setResult(null);

      const status = await pollStatus();

      if (typeof status !== 'string' && status && 'error' in status) {
        const message = status.error?.message || 'Polling error';
        console.error(message);
        setError(message);
        setIsPolling(false);
        return;
      }

      const updateResult = updater(status);
      if (updateResult && 'error' in updateResult) {
        const message = updateResult.error?.message || 'Polling error';
        console.error(message);
        setError(message);
        setIsPolling(false);
        return;
      }

      setResult(status);
      await submitForm();
      setIsPolling(false);
    }

    handlePoll();

    /**
     * In continue polling mode, a rewind node can be returned if polling should continue.
     * While the polling collector in this node looks identical, the node's cache key will
     * differ indicating a re-render/re-poll should occur.
     */
  }, [cacheKey]);

  return (
    <div className="my-3" aria-busy={isPolling ? 'true' : undefined}>
      {isPolling && <Loading message="Polling..." />}
      {result && <p className="mt-2">{`Polling result: ${result}`}</p>}
      {error && (
        <p className="alert alert-danger mt-2" role="alert">
          {`Polling error: ${error}`}
        </p>
      )}
    </div>
  );
}
