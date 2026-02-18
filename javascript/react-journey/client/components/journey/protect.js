/*
 * ping-sample-web-react-journey
 *
 * protect.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext, useEffect, useState } from 'react';
import { protect } from '@forgerock/protect';
import { callbackType } from '@forgerock/journey-client';
import { DEBUGGER, INIT_PROTECT } from '../../constants';
import Loading from '../utilities/loading';
import { ProtectContext } from '../../context/protect.context';

const urlParams = new URLSearchParams(window.location.search);
const protectInitMode = INIT_PROTECT || urlParams.get('initProtect');

/**
 * @function Protect - React component for handling PingOne Protect callbacks
 * @param {FRStep} step - The current step in the authentication journey
 * @param {function} setSubmissionStep - Method to set the submission step
 * @returns {Object} - A React loading component
 */
export default function Protect({ step, setSubmissionStep }) {
  const [loadingMessage, setLoadingMessage] = useState('');
  const [protectApi, setProtectApi] = useContext(ProtectContext);

  useEffect(() => {
    async function handleProtect() {
      if (
        protectInitMode === 'journey' &&
        step.getCallbacksOfType(callbackType.PingOneProtectInitializeCallback).length
      ) {
        /** *************************************************************************
         * SDK INTEGRATION POINT
         * Summary: Initialize Protect by callback
         * --------------------------------------------------------------------------
         * Details: If the INIT_PROTECT flag is set to 'journey', rely on the
         * configuration from the PingOneProtectInitializeCallback's output to
         * initialize the Protect API. Then call the API's start method to begin
         * collecting data.
         ************************************************************************* */
        if (DEBUGGER) debugger;
        setLoadingMessage('Initializing PingOne Protect...');

        const callback = step.getCallbackOfType(callbackType.PingOneProtectInitializeCallback);
        const config = callback.getConfig();

        const api = protect(config);
        setProtectApi(api);

        const result = await api.start();

        if (result?.error) {
          console.error(`Error initializing Protect: ${result.error}`);
          setLoadingMessage('Error initializing Protect');
        } else {
          console.log('Protect initialized by callback for data collection');
          setLoadingMessage('');
        }
      } else if (step.getCallbacksOfType(callbackType.PingOneProtectEvaluationCallback).length) {
        /** *************************************************************************
         * SDK INTEGRATION POINT
         * Summary: Update the Protect evaluation callback with data collected
         * --------------------------------------------------------------------------
         * Details: To handle the evaluation callback, use the `getData()` method to
         * retrieve the device profiling and behavioral data collected since
         * initialization. Then set the data on the evaluation callback.
         ************************************************************************* */
        if (DEBUGGER) debugger;
        setLoadingMessage('Evaluating PingOne Protect...');

        const callback = step.getCallbackOfType(callbackType.PingOneProtectEvaluationCallback);
        const data = await protectApi.getData();

        if (typeof data !== 'string' && 'error' in data) {
          console.error(`Failed to retrieve data from PingOne Protect: ${data.error}`);
          setLoadingMessage('Failed to retrieve data from PingOne Protect');
        } else {
          callback.setData(data);
          console.log('Data set on Protect evaluation callback');
          setLoadingMessage('');
        }
      }

      /**
       * Set the submission step to either proceed with initialization or perform the Protect risk
       * assessment and continue with the journey
       */
      setSubmissionStep(step);
    }

    handleProtect();
  }, [step, setLoadingMessage, setSubmissionStep]);

  return <Loading message={loadingMessage} />;
}
