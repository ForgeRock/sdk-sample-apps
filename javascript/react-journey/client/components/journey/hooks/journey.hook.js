/*
 * ping-sample-web-react-journey
 *
 * journey.hook.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useContext, useEffect, useState } from 'react';
import createJourneyClient from './journey-client.utils.js';
import { DEBUGGER } from '../../../constants.js';
import { htmlDecode } from '../../../utilities/decode.js';
import { OidcContext } from '../../../context/oidc.context.js';
import { callbackType } from '@forgerock/journey-client';

/**
 *
 * @param {Object} props - React props object
 * @param {Object} props.action - Action object for a "reducer" pattern
 * @param {string} props.action.type - Action type string that represents the action
 * @param {Object} props.formMetadata - The form metadata object
 * @returns {Object} - React component object
 */
export default function useJourney({ action, formMetadata, resumeUrl }) {
  /**
   * Compose the state used in this view.
   * First, we will use the global state methods found in the App Context.
   * Then, we will create local state to manage the login journey. The
   * underscore is an unused variable, since we don't need the current global state.
   *
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" method to set new state values.
   */

  // Journey client instance for managing auth
  const [journeyClient, setJourneyClient] = useState(null);
  // Form level errors
  const [formFailureMessage, setFormFailureMessage] = useState(null);
  // Step to render
  const [renderStep, setRenderStep] = useState(null);
  // Step to submit
  const [submissionStep, setSubmissionStep] = useState(null);
  // Count steps
  const [stepCount, setStepCount] = useState(0);
  // Processing submission
  const [submittingForm, setSubmittingForm] = useState(false);
  // User state
  const [user, setUser] = useState(null);

  const [{ oidcClient }] = useContext(OidcContext);

  useEffect(() => {
    async function initJourney() {
      /** *********************************************************************
       * SDK INTEGRATION POINT
       * Summary: Initialize the Journey client
       * ----------------------------------------------------------------------
       * Details: Start the journey to get the first step for rendering the form.
       ********************************************************************* */
      if (DEBUGGER) debugger;
      try {
        const client = await createJourneyClient();
        setJourneyClient(client);

        if (resumeUrl) {
          /**
           * If we were redirected here from an IDP with a resumeUrl, then resume the flow
           */
          const resumeStep = await client?.resume(resumeUrl);
          setRenderStep(resumeStep);
        } else {
          const initialStep = await client?.start({ journey: formMetadata.tree });
          setRenderStep(initialStep);
        }
      } catch (error) {
        console.error(`Error initializing journey; ${error}`);
      }
    }

    if (!journeyClient) {
      initJourney();
    }
  }, [journeyClient]);

  /**
   * Since we have API calls to AM, we need to handle these requests as side-effects.
   * This will allow the view to render, but update/re-render after the request completes.
   */
  useEffect(() => {
    /**
     * @function getOAuth - The function to call when we get a LoginSuccess
     * @returns {undefined}
     */
    async function getOAuth() {
      /** *********************************************************************
       * SDK INTEGRATION POINT
       * Summary: Get OAuth/OIDC tokens with Authorization Code Flow w/PKCE.
       * ----------------------------------------------------------------------
       * Details: Since we have successfully authenticated the user, we can now
       * get the OAuth2/OIDC tokens. We initiate authorization in the background
       * to receive code and state which we can then exchange for tokens.
       ************************************************************************* */
      if (DEBUGGER) debugger;

      const response = await oidcClient.authorize.background();
      if ('error' in response) {
        console.error('Authorization Error:', response);

        if (response.redirectUrl) {
          window.location.assign(response.redirectUrl);
        } else {
          console.log('Authorization failed with no ability to redirect:', response);
        }
        return;
      } else if ('code' in response && 'state' in response) {
        // Handle success response from background authorization
        const tokenResponse = await oidcClient.token.exchange(response.code, response.state);
        if ('error' in tokenResponse) {
          console.error('Token error:', tokenResponse);
          return;
        }
      }

      /** *********************************************************************
       * SDK INTEGRATION POINT
       * Summary: Call the user info endpoint for some basic user data.
       * ----------------------------------------------------------------------
       * Details: This is an OAuth2 call that returns user information with a
       * valid access token. This is optional and only used for displaying
       * user info in the UI.
       ********************************************************************* */
      if (DEBUGGER) debugger;
      const user = await oidcClient.user.info();
      if ('error' in user) {
        console.error('Error getting user:', user);
        setUser({});
      } else {
        setUser(user);
      }
    }

    /**
     * @function getStep - The function for calling AM with a previous step to get a new step
     * @param {Object} prev - This is the previous step that should contain the input for AM
     * @returns {undefined}
     */
    async function setStep(prev) {
      /**
       * Save previous step information just in case we have a total
       * form failure due to 400 response from Ping.
       */
      const previousStage = prev?.getStage && prev.getStage();
      const previousCallbacks = prev?.callbacks;
      const previousPayload = prev?.payload;

      /** *********************************************************************
       * SDK INTEGRATION POINT
       * Summary: Call the journey client's next method to submit the current step.
       * ----------------------------------------------------------------------
       * Details: This calls the next method with the previous step, expecting
       * the next step to be returned, or a success or failure.
       ********************************************************************* */
      if (DEBUGGER) debugger;
      let nextStep;

      try {
        if (resumeUrl) {
          nextStep = await journeyClient.resume(resumeUrl);
        } else {
          nextStep = await journeyClient.next(prev);
        }
        setStepCount((current) => current + 1);
      } catch (err) {
        console.error(`Error: failure in next step request; ${err}`);

        /**
         * Setup an object to display failure message
         */
        nextStep = {
          type: 'LoginFailure',
          payload: {
            message: 'Unknown request failure',
          },
        };
      }

      /**
       * Condition for handling start, error handling and completion
       * of login journey.
       */
      if (!nextStep || nextStep.type === 'LoginFailure') {
        /**
         * Handle basic form error
         */
        setFormFailureMessage(nextStep ? htmlDecode(nextStep.payload.message) : 'Login failure');

        /** *******************************************************************
         * SDK INTEGRATION POINT
         * Summary: Restart the journey upon login failure
         * --------------------------------------------------------------------
         * Details: Since this is within the failure block, let's call the start
         * method again to get a fresh authId.
         ******************************************************************* */
        if (DEBUGGER) debugger;
        let newStep;

        try {
          newStep = await journeyClient.start({ tree: formMetadata.tree });
        } catch (err) {
          console.error(`Error: failure in new step request; ${err}`);

          /**
           * Setup an object to display failure message
           */
          newStep = {
            type: 'LoginFailure',
            payload: {
              message: 'Unknown request failure',
            },
          };
        }

        /** *******************************************************************
         * SDK INTEGRATION POINT
         * Summary: Repopulate callbacks/payload with previous data.
         * --------------------------------------------------------------------
         * Details: Now that we have a new authId (the identification of the
         * fresh step) let's populate this new step with old callback data if
         * the stage is the same. If not, the user will have to refill form. We
         * will display the error we collected from the previous submission,
         * restart the flow, and provide better UX with the previous form data,
         * so the user doesn't have to refill the form.
         ******************************************************************* */
        if (DEBUGGER) debugger;
        if (stepCount === 1 && newStep.type === 'Step' && newStep.getStage() === previousStage) {
          newStep.callbacks = previousCallbacks;
          newStep.payload = {
            ...previousPayload,
            authId: newStep.payload.authId,
          };
        }

        setRenderStep(newStep);
        setSubmittingForm(false);
      } else if (nextStep.type === 'LoginSuccess') {
        // Clear out step count
        setStepCount(0);

        // User is authenticated, now call for OAuth tokens
        await getOAuth();
      } else {
        /**
         * If we got here, then the form submission was both successful
         * and requires additional step rendering.
         */
        setRenderStep(nextStep);
        setSubmittingForm(false);
      }
    }

    /**
     * Set the next step to render from the journey
     */
    if (submissionStep && journeyClient) {
      setStep(submissionStep);
    }
  }, [action.type, formMetadata.tree, submissionStep, journeyClient]);

  /**
   * @function redirect - Redirects the user to the specified URL in the step
   * @param step - A step with a RedirectCallback
   */
  async function redirect(step) {
    /** *******************************************************************
     * SDK INTEGRATION POINT
     * Summary: Redirect the user to the URL specified in the RedirectCallback
     * --------------------------------------------------------------------
     * Details: If there is a RedirectCallback in the step, use the journey
     * client to automatically handle the redirect.
     ******************************************************************* */
    if (DEBUGGER) debugger;

    try {
      if (step.getCallbacksOfType(callbackType.RedirectCallback).length) {
        await journeyClient.redirect(step);
      }
    } catch (error) {
      console.error(`Error during redirect; ${error}`);
    }
  }

  return [
    {
      formFailureMessage,
      renderStep,
      submittingForm,
      user,
    },
    {
      setSubmissionStep,
      setSubmittingForm,
      redirect,
    },
  ];
}
