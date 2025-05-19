/*
 * forgerock-sample-web-react
 *
 * protect.js
 *
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useEffect } from 'react';
import { PIProtect } from '@forgerock/ping-protect';
import { CallbackType } from '@forgerock/javascript-sdk';
import { DEBUGGER, PINGONE_ENV_ID } from '../../constants';
import Loading from '../utilities/loading';

/**
 * @function Protect - React component for handling PingOne Protect callbacks
 * @param {FRStep} step - The current step in the authentication journey
 * @param {function} setSubmissionStep - Method to set the submission step
 * @returns {Object} - A React loading component
 */
export default function Protect({ step, setSubmissionStep }) {
  useEffect(() => {
    async function handleProtect() {
      if (step.getCallbacksOfType(CallbackType.PingOneProtectInitializeCallback)) {
        /**
         * Initialize PingOne Protect with a configuration object. The PingOne environment
         * ID is required while all other options are optional. Then submit the step to
         * move foward with the journey.
         */
        try {
          if (DEBUGGER) debugger;
          if (!PINGONE_ENV_ID) {
            console.error('Missing PingOne environment ID for Protect intialization');
          } else {
            await PIProtect.start({ envId: PINGONE_ENV_ID });
            setSubmissionStep(step);
          }
        } catch (err) {
          console.error(`Failed to initialize PingOne Protect`, err);
        }
      } else if (step.getCallbacksOfType(CallbackType.PingOneProtectEvaluationCallback)) {
        const callback = step.getCallbackOfType(CallbackType.PingOneProtectEvaluationCallback);
        /**
         * To handle the evaluation callback, use the `getData()` method to retrieve the device
         * profiling and behavioral data collected since initialization. Then set the data on the
         * evaluation callback and submit the step to perform the Protect risk assessment and
         * continue with the journey.
         */
        try {
          if (DEBUGGER) debugger;
          const data = await PIProtect.getData();
          callback.setData(data);
          setSubmissionStep(step);
        } catch (err) {
          console.error(`Failed to evaluate PingOne Protect`, err);
        }
      }
    }

    handleProtect();
  }, [step]);

  return <Loading />;
}
