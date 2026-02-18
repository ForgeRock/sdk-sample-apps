/*
 * ping-sample-web-react-davinci
 *
 * fido-collector.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState, useEffect } from 'react';
import { fido } from '@forgerock/davinci-client';

/**
 * FidoCollector React component for FIDO registration and authentication
 * @param {Object} props
 * @param {Object} props.collector - FidoRegistrationCollector or FidoAuthenticationCollector
 * @param {Function} props.updater - Updater function for collector
 * @param {Function} props.submitForm - Function to call to advance the flow
 */
export default function FidoCollector({ collector, updater, submitForm }) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [hasAttempted, setHasAttempted] = useState(false); // for registration auto-trigger
  const fidoClient = fido();

  async function handleFido() {
    setIsLoading(true);
    setError(null);
    try {
      let response;
      if (collector.type === 'FidoRegistrationCollector') {
        response = await fidoClient.register(collector.output.config.publicKeyCredentialCreationOptions);
      } else if (collector.type === 'FidoAuthenticationCollector') {
        response = await fidoClient.authenticate(collector.output.config.publicKeyCredentialRequestOptions);
      } else {
        setError('Unsupported FIDO collector type');
        setIsLoading(false);
        return;
      }

      if ('error' in response) {
        setError(response.error?.message || response?.message || 'FIDO error');
        console.error(response);
      } else {
        const updateResult = updater(response);
        if (updateResult && 'error' in updateResult) {
          setError(updateResult.error?.message || 'Update error');
          console.error(updateResult.error?.message);
        } else {
          await submitForm();
        }
      }
    } catch (err) {
      setError(err.message || 'Unexpected error');
      console.error(err);
    } finally {
      setIsLoading(false);
      setHasAttempted(true);
    }
  }

  // Auto-trigger registration or authentication on mount or collector change
  useEffect(() => {
    if (
      (collector.type === 'FidoRegistrationCollector' || collector.type === 'FidoAuthenticationCollector') &&
      !isLoading &&
      !hasAttempted
    ) {
      handleFido();
    }
  }, [collector]);

  if (collector.type !== 'FidoRegistrationCollector' && collector.type !== 'FidoAuthenticationCollector') {
    return <div role="alert">Unsupported FIDO collector type</div>;
  }

  return (
    <div className="my-3" aria-busy={isLoading ? "true" : undefined}>
      {error && (
        <div className="text-danger text-center" role="alert" aria-live="assertive">
          <div>{error}</div>
          <button
            type="submit"
            className="btn btn-primary w-100 my-4"
            onClick={() => handleFido()}
            disabled={isLoading}
            aria-label="Try the FIDO operation again"
          >
            <span>Try Again</span>
          </button>
        </div>
      )}
    </div>
  );
}
