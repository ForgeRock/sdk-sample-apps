/*
 * ping-sample-web-react-journey
 *
 * protect.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useEffect, useState } from 'react';
import { PIProtect } from '@forgerock/ping-protect';
import { callbackType } from '@forgerock/journey-client';
import { DEBUGGER, INIT_PROTECT } from '../../constants';
import Loading from '../utilities/loading';

/**
 * @function Protect - React component for handling PingOne Protect callbacks
 * @param {FRStep} step - The current step in the authentication journey
 * @param {function} setSubmissionStep - Method to set the submission step
 * @returns {Object} - A React loading component
 */
export default function Protect({ step, setSubmissionStep }) {
  const [loadingMessage, setLoadingMessage] = useState('');

  useEffect(() => {
    async function handleProtect() {
      if (
        !INIT_PROTECT &&
        step.getCallbacksOfType(callbackType.PingOneProtectInitializeCallback).length
      ) {
        const callback = step.getCallbackOfType(callbackType.PingOneProtectInitializeCallback);
        /**
         * If the INIT_PROTECT flag is false, rely on the PingOneProtectInitializeCallback
         * to initialize PingOne Protect. The configuration can be retrieved from the node
         * in the journey using the `getConfig()` method on the callback.
         */
        try {
          if (DEBUGGER) debugger;
          setLoadingMessage('Initializing PingOne Protect...');

          const config = callback.getConfig();
          await PIProtect.start(config);
          console.log('PingOne Protect initialized by callback');
        } catch (err) {
          console.error(`Failed to initialize PingOne Protect`, err);
        } finally {
          setLoadingMessage('');
        }
      } else if (step.getCallbacksOfType(callbackType.PingOneProtectEvaluationCallback).length) {
        const callback = step.getCallbackOfType(callbackType.PingOneProtectEvaluationCallback);
        /**
         * To handle the evaluation callback, use the `getData()` method to retrieve the device
         * profiling and behavioral data collected since initialization. Then set the data on the
         * evaluation callback.
         */
        try {
          if (DEBUGGER) debugger;
          setLoadingMessage('Evaluating PingOne Protect...');

          const data = await PIProtect.getData();
          callback.setData(data);
          console.log('Data set on Protect evaluation callback');
        } catch (err) {
          console.error(`Failed to evaluate PingOne Protect`, err);
        } finally {
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
