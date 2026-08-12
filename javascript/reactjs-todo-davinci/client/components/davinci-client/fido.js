/*
 * ping-sample-web-react-davinci
 *
 * fido.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState, useEffect } from 'react';
import { fido } from '@forgerock/davinci-client';

/**
 * @function describeFidoError - Maps a typed FIDO GenericError to sample-app-friendly copy.
 * @param {Object} fidoError - The typed error returned by the DaVinci FIDO client
 * @param {string} fidoError.type - 'fido_error' for an expected WebAuthn/browser failure,
 * 'unknown_error' for an unexpected internal failure
 * @param {string} [fidoError.code] - Optional WebAuthn error code (e.g. 'NotAllowedError')
 * @param {string} [fidoError.message] - Optional human-readable detail from the SDK
 * @returns {{ message: string, code?: string }} - Display message and error code for the UI
 */
function describeFidoError(fidoError) {
  if (fidoError.type === 'fido_error') {
    return {
      message: fidoError.message || 'Your device or browser could not complete this request.',
      code: fidoError.code,
    };
  }

  return { message: 'Something unexpected went wrong. Please try again.', code: fidoError.code };
}

/**
 * FidoComponent React component for FIDO registration and authentication
 * @param {Object} props
 * @param {Object} props.collector - FidoRegistrationCollector or FidoAuthenticationCollector
 * @param {Function} props.updater - Updater function for collector
 * @param {Function} props.submitForm - Function to call to advance the flow
 */
export default function FidoComponent({ collector, updater, submitForm }) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [hasAttempted, setHasAttempted] = useState(false); // for registration auto-trigger
  const fidoClient = fido();

  async function updateAndSubmit(result, fallbackErrorMessage) {
    const updateResult = updater(result);
    if (updateResult && 'error' in updateResult) {
      setError({ message: updateResult.error?.message || fallbackErrorMessage });
      console.error('Error updating fido collector:', updateResult.error);
      return;
    }
    await submitForm();
  }

  async function handleFido() {
    setIsLoading(true);
    setError(null);

    let response;
    if (collector.type === 'FidoRegistrationCollector') {
      response = await fidoClient.register(
        collector.output.config.publicKeyCredentialCreationOptions,
      );
    } else if (collector.type === 'FidoAuthenticationCollector') {
      response = await fidoClient.authenticate(
        collector.output.config.publicKeyCredentialRequestOptions,
      );
    } else {
      setError({ message: 'Unsupported FIDO collector type' });
      setIsLoading(false);
      return;
    }

    if ('error' in response) {
      /** *********************************************************************
       * SDK INTEGRATION POINT
       * Summary: Branch on the FIDO client's typed error contract
       * ----------------------------------------------------------------------
       * Details: `fidoClient.register`/`authenticate` return a typed
       * `GenericError` on failure. Its `type` field ('fido_error' vs
       * 'unknown_error') lets the flow distinguish an expected WebAuthn/browser
       * failure from an unexpected internal one, rather than parsing a message
       * string. `code` (e.g. `NotAllowedError`) is surfaced as a data attribute
       * so e2e tests can assert on the specific WebAuthn failure reason.
       ********************************************************************* */
      const fidoError = describeFidoError(response);
      setError(fidoError);
      console.error('Fido error:', response);

      await updateAndSubmit(response, fidoError.message);
    } else {
      await updateAndSubmit(response, 'Update error');
    }

    setIsLoading(false);
    setHasAttempted(true);
  }

  // Auto-trigger registration or authentication on mount or collector change
  useEffect(() => {
    if (
      (collector.type === 'FidoRegistrationCollector' ||
        collector.type === 'FidoAuthenticationCollector') &&
      !isLoading &&
      !hasAttempted
    ) {
      handleFido();
    }
  }, [collector]);

  return (
    <div className="my-3" aria-busy={isLoading ? 'true' : undefined}>
      {error && (
        <div
          className="text-danger text-center"
          role="alert"
          aria-live="assertive"
          data-error-code={error.code}
        >
          <div>{error.message}</div>
          <button
            type="submit"
            className="btn btn-primary w-100 my-4"
            onClick={() => handleFido()}
            disabled={isLoading}
          >
            Try Again
          </button>
        </div>
      )}
    </div>
  );
}
