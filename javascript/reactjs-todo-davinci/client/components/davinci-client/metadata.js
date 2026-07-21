/*
 * ping-sample-web-react-davinci
 *
 * metadata.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useState } from 'react';

/**
 * @function runThirdPartySdk - Stand-in for invoking a third-party SDK with the
 * DaVinci-provided config payload (e.g. an identity-verification or fraud SDK
 * paused mid-flow via MetadataCollector). Per the MetadataCollector design, the
 * payload is guaranteed to already be a valid JSON object -- DaVinci's server
 * validates it before the app ever sees it.
 * @param {Object} config - The payload from collector.output.config
 * @param {boolean} shouldSucceed - Which outcome to simulate (demo-only; a real
 * integration's outcome is decided by the third-party SDK, not the caller)
 * @returns {Promise<{value: Object}|{error: string}>}
 */
async function runThirdPartySdk(config, shouldSucceed) {
  // Simulate calling a real third-party SDK with `config`. A real integration
  // reports whatever success value or failure reason that SDK itself returns.
  return new Promise((resolve) =>
    setTimeout(() => {
      if (shouldSucceed) {
        resolve({ value: { verification: 'successful', status: true, config } });
      } else {
        resolve({ error: 'Third-party SDK verification failed' });
      }
    }, 500),
  );
}

/**
 * MetadataComponent React component for the DaVinci MetadataCollector
 * @param {Object} props
 * @param {Object} props.collector - MetadataCollector
 * @param {Function} props.updater - Updater function for collector
 * @param {Function} props.submitForm - Function to call to advance the flow
 */
export default function MetadataComponent({ collector, updater, submitForm }) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  /** *********************************************************************
   * SDK INTEGRATION POINT
   * Summary: Run a third-party SDK against the metadata payload, then report
   * its outcome back to DaVinci
   * ----------------------------------------------------------------------
   * Details: MetadataCollector pauses the flow so the app can invoke a
   * third-party SDK with the DaVinci-provided config (collector.output.config).
   * Whatever that third-party SDK returns is reported back: its success value
   * via updater(), or a structured MetadataError (a plain {code, message}
   * object per the SDK's MetadataError type -- the SDK exposes no builder
   * function for it) if it fails. Either way, `updater` can itself return an
   * error (e.g. missing ID, invalid state), so its result must be checked
   * before advancing the flow. The Success/Failure buttons below simulate both
   * outcomes for demo purposes; a real integration has exactly one action that
   * calls the third-party SDK and branches on what it returns.
   ********************************************************************* */
  async function handleContinue(shouldSucceed) {
    setIsLoading(true);
    setError(null);

    const sdkResult = await runThirdPartySdk(collector.output.config, shouldSucceed);
    const updateResult =
      sdkResult && 'error' in sdkResult
        ? updater({ code: 'METADATA_PROCESSING_ERROR', message: sdkResult.error })
        : updater(sdkResult.value);

    if (updateResult && 'error' in updateResult) {
      setError(updateResult.error?.message || 'Update error');
      console.error('Error updating metadata collector:', updateResult.error);
    } else {
      await submitForm();
    }

    setIsLoading(false);
  }

  return (
    <div className="my-3">
      <pre>{JSON.stringify(collector.output.config, null, 2)}</pre>
      {error && (
        <div className="text-danger text-center" role="alert" aria-live="assertive">
          {error}
        </div>
      )}
      <button
        type="button"
        className="btn btn-primary w-100 mb-2"
        onClick={() => handleContinue(true)}
        disabled={isLoading}
      >
        Success
      </button>
      <button
        type="button"
        className="btn btn-danger w-100"
        onClick={() => handleContinue(false)}
        disabled={isLoading}
      >
        Failure
      </button>
    </div>
  );
}
