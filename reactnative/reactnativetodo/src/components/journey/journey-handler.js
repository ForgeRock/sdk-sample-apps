/*
 * forgerock-react-native-sample
 *
 * journey-hook.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { FRStep } from '@forgerock/javascript-sdk';
import { useEffect, useState } from 'react';
import { NativeModules } from 'react-native';

/*
 * Please ensure you have created an .env.js from the
 * .env.example.js template!
 */
import { DEBUGGER_OFF } from '../../../.env';

const { FRAuthSampleBridge } = NativeModules;
const errorMessages = {
  login: 'Login failed. Please try again.',
  register: 'Registration failed. Please try again',
};

/**
 * @function useJourneyHandler - A custom hook for journey state and error management
 * @param {Object} action - action object with a type of login or register
 * @param {string} action.type - the intended user action: login or register
 * @returns {Object} - {
 *   formFailureMessage: string,
 *   renderStep: Object,
 *   submittingForm: Boolean,
 *   setSubmissionStep: React Hook Setter,
 *   setSubmittingForm: React Hook Setter,
 *   user: User information
 * };
 */
export default function useJourneyHandler({ type }) {
  /**
   * Compose the state used in this view.
   * First, we will use the global state methods found in the App Context.
   * Then, we will create local state to manage the login journey. The
   * underscore is an unused variable, since we don't need the current global state.
   *
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" method to set new state values.
   */
  // Form level errors
  const [formFailureMessage, setFormFailureMessage] = useState(null);
  // Step to render
  const [renderStep, setRenderStep] = useState(null);
  // Step to submit
  const [submissionStep, setSubmissionStep] = useState(null);
  // Processing submission
  const [isProcessingForm, setProcessingForm] = useState(false);
  // User state
  const [user, setUser] = useState(null);

  /**
   * Since we have API calls to AM, we need to handle these requests as side-effects.
   * This will allow the view to render, but update/re-render after the request completes.
   */
  useEffect(() => {
    /**
     * @function getStep - The function for calling AM with a previous step to get a new step
     * @param {Object} prev - This is the previous step that should contain the input for AM
     * @returns {undefined}
     */
    async function getStep(prev) {
      // if we have no render step we are initializing a login or a register flow
      if (!renderStep) {
        let data;
        let next;
        try {
          /*****************************************************************
           * NATIVE BRIDGE SDK INTEGRATION POINT
           * Summary: Call the login endpoint
           * --------------------------------------------------------------
           * Details: When we have no current 'renderStep', that means we
           * have no data to render. Given our action type, we know we want
           * to login so we can call the login method in order to get back
           * our data to render for our login screen.
           *************************************************************** */
          if (!DEBUGGER_OFF) debugger;
          data = await FRAuthSampleBridge[type]();
        } catch (err) {
          /**
           * If we fail here, the user might have a lingering session, so
           * let's log them out, and start over.
           */
          await FRAuthSampleBridge.logout();
          data = await FRAuthSampleBridge[type]();
        }

        next = JSON.parse(data);

        /*****************************************************************
         * JAVASCRIPT SDK INTEGRATION POINT
         * Summary: Convert Response to an FRStep
         * --------------------------------------------------------------
         * This is a helper method provided by the Javascript SDK.
         * It will decorate the callbacks array items (each object), with
         * helper methods on the prototype for each object.
         * In return, much of the state management
         * is taken care of by the SDK layer.
         *************************************************************** */
        if (!DEBUGGER_OFF) debugger;
        const step = new FRStep(next);

        setRenderStep(step);
        setProcessingForm(false);
      } else {
        /**
         * Save previous step information just in case we have a total
         * form failure due to 400 response from ForgeRock.
         */
        const previousStage = prev?.getStage && prev.getStage();
        const previousCallbacks = prev?.callbacks;
        const previousPayload = prev?.payload;
        let step;

        try {
          /** *********************************************************************
           * NATIVE BRIDGE SDK INTEGRATION POINT
           * Summary: Call the SDK's next method to submit the current step.
           * ----------------------------------------------------------------------
           * Details: This calls the next method with the previous step, expecting
           * the next step to be returned, or a success or failure.
           ********************************************************************* */
          if (!DEBUGGER_OFF) debugger;
          const response = await FRAuthSampleBridge.next(
            JSON.stringify(renderStep.payload),
          );
          /**
           * Condition for handling start, error handling and completion
           * of login journey.
           */
          if (response?.type === 'LoginSuccess') {
            /** *********************************************************************
             * Native Bridge SDK INTEGRATION POINT
             * Summary: Call userInfo endpoint
             * ----------------------------------------------------------------------
             * Details: Now that we have successfully logged in, let's call the user
             * info endpoint to collect the user data.
             * ********************************************************************* */
            if (!DEBUGGER_OFF) debugger;
            const userInfo = await FRAuthSampleBridge.getUserInfo();
            console.log(userInfo);

            setUser(userInfo);
          } else {
            /**
             * If we got here, then the form submission was both successful
             * and requires additional step rendering.
             */
            const data = JSON.parse(response);
            step = new FRStep(data);
            setRenderStep(step);
            setProcessingForm(false);
          }
        } catch (err) {
          /**
           * Handle basic form error
           */
          setFormFailureMessage(
            err.message === 'LoginFailure' ? errorMessages[type] : err.message,
          );
          setProcessingForm(false);

          try {
            /** *******************************************************************
             * NATIVE BRIDGE SDK INTEGRATION POINT
             * Summary: Call next with submission step payload
             * --------------------------------------------------------------------
             * Details: Because LoginFailure throws, we have to handle the failure
             * in the catch block
             * ******************************************************************* */
            if (!DEBUGGER_OFF) debugger;
            const response = await FRAuthSampleBridge[type]();

            const data = JSON.parse(response);

            /*****************************************************************
             * JAVASCRIPT SDK INTEGRATION POINT
             * Summary: Convert Response to an FRStep
             * --------------------------------------------------------------
             * This is a helper method provided by the Javascript SDK.
             * It will decorate the callbacks array items (each object), with
             * helper methods on the prototype for each object.
             * In return, much of the state management
             * is taken care of by the SDK layer.
             *************************************************************** */
            if (!DEBUGGER_OFF) debugger;
            const newStep = new FRStep(data);

            if (newStep.getStage && newStep.getStage() === previousStage) {
              newStep.callbacks = previousCallbacks;
              newStep.payload = {
                ...previousPayload,
                authId: newStep.payload.authId,
              };
            }

            setRenderStep(newStep);
            setProcessingForm(false);
          } catch (err2) {
            console.error('Parsing received data for JS SDK failed.');
          }
        }
      }
    }

    /* *******************************************************************
     * Kickstart the authentication journey!
     * submissionStep will initially be `null`, and that's intended.
     ****************************************************************** */
    getStep(submissionStep);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [type, submissionStep]);

  return {
    formFailureMessage,
    renderStep,
    isProcessingForm,
    setSubmissionStep,
    setProcessingForm,
    user,
  };
}
