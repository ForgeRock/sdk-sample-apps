/*
 * ping-sample-web-react-davinci
 *
 * recognize.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useEffect, useRef, useState } from 'react';
import { recognize } from '@forgerock/recognize';

/**
 * @function getClientOptions - Maps the connector's collector config to Recognize client options
 * @param {Object} config - The RecognizeCollector `output.config`
 * @returns {Object} - Options for creating the Recognize client
 */
const getClientOptions = ({ serviceURL, customerName, transactionData, webSDKOptions }) => ({
  serviceURL,
  customer: customerName,
  transactionData,
  authorizationToken: webSDKOptions.authorizationToken,
  operationID: webSDKOptions.operationId,
  disableSteps: ['done', 'error'],
});

/**
 * @function getInitOptions - Maps the connector's collector config to Recognize session options
 * @param {Object} config - The RecognizeCollector `output.config`
 * @param {HTMLElement} container - The element the Recognize UI is mounted into
 * @returns {Object} - Options for initializing the Recognize session
 */
const getInitOptions = ({ action, username }, container) => ({
  mode: 'mount',
  container,
  type: action === 'ENROLL' ? 'enroll' : 'auth',
  username,
});

/**
 * @function RecognizeComponent - React component for the DaVinci RecognizeCollector
 * @param {Object} props
 * @param {Object} props.collector - DaVinci RecognizeCollector; `output.config` carries the
 *   configuration emitted by the PingOne Recognize connector
 * @param {Function} props.updater - Updater function for the collector
 * @param {Function} props.submitForm - Function to call to advance the flow
 * @returns {Object} - React component object
 */
const RecognizeComponent = ({ collector, updater, submitForm }) => {
  const containerRef = useRef(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Create the Recognize client from the collector config
     * ----------------------------------------------------------------------
     * Details: The connector decides whether the user must enroll or
     * authenticate and says so in `config.action`. The rest of the config
     * is everything needed to start the session.
     ********************************************************************* */
    const config = collector.output.config;
    const client = recognize(getClientOptions(config));

    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Send the outcome back to DaVinci
     * ----------------------------------------------------------------------
     * Details: On success, set the transaction JWT on the collector. On
     * error, pass the Recognize error as-is so the flow can route on it.
     * Either way, submit to move to the next node.
     ********************************************************************* */
    const finish = (value) => {
      updater(value);
      submitForm();
    };

    const unsubscribe = client.subscribe({
      error: (err) => {
        setError(err.error.message || 'Recognition failed');
        finish(err);
      },
      complete: ({ jwt }) => finish({ transactionJWT: jwt ?? '' }),
    });

    client.init(getInitOptions(config, containerRef.current)).then((initError) => {
      if (initError) {
        setError(initError.error?.message || 'Failed to initialize the Recognize session');
      }
    });

    // Release the camera and WASM resources when the node unmounts
    return () => {
      unsubscribe();
      client.dispose();
    };
  }, [collector.id]);

  return (
    <div className="my-3">
      {error && (
        <div className="text-danger text-center mb-2" role="alert" aria-live="assertive">
          {error}
        </div>
      )}
      <div ref={containerRef} />
    </div>
  );
};

export default RecognizeComponent;
