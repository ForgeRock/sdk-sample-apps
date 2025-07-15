/*
 * ping-sample-web-react-davinci
 *
 * form.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { Fragment, useContext, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import Readonly from './readonly.js';
import Text from './text.js';
import Error from './error.js';
import Password from './password.js';
import SubmitButton from './submit-button.js';
import Protect from './protect.js';
import ObjectValueComponent from './object-value.js';
import SingleSelect from './single-select.js';
import FlowLink from './flow-link.js';
import Unknown from './unknown.js';
import Alert from './alert.js';
import KeyIcon from '../icons/key-icon';
import NewUserIcon from '../icons/new-user-icon';
import Loading from '../utilities/loading.js';
import { AppContext } from '../../global-state.js';
import useDavinci from './hooks/davinci.hook.js';
import useOAuth from './hooks/oauth.hook.js';

/**
 * @function Form - React view for managing the user authentication journey
 * @returns {Object} - React component object
 */
export default function Form() {
  /**
   * Compose the state used in this view.
   * First, we will use the global state methods found in the App Context.
   * Then, we will create local state to manage the login flow.
   *
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" methods to set new state values.
   */

  const [{ theme, protectAPI }, methods] = useContext(AppContext);
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  /**
   * Custom hooks for managing form state and authorization
   */
  const [user, setCode] = useOAuth();
  const [{ formName, formAction, node, collectors }, { getError, setNext, startNewFlow, updater }] =
    useDavinci();

  /**
   * @function hasProtectTextCollector - Determines if there is a Protect SDK Text collector
   * @param {Object} collectors - An array of collectors from DaVinci
   * @returns {boolean} - True if there is a Protect SDK Text collector otherwise false
   */
  function hasProtectTextCollector(collectors) {
    return collectors?.some(
      (collector) => collector.type === 'TextCollector' && collector.name === 'protectsdk',
    );
  }

  /**
   * @function hasProtectCollector - Determines if there is a ProtectCollector
   * @param {Object} collectors - An array of collectors from DaVinci
   * @returns {boolean} - True if there is a ProtectCollector otherwise false
   */
  function hasProtectCollector(collectors) {
    return collectors?.some((collector) => collector.type === 'ProtectCollector');
  }

  /**
   * @function updateProtectCollector - Updates the ProtectCollector with data collected
   * @param {Object} protectCollector - A ProtectCollector from DaVinci
   * @returns {Promise<void>}
   */
  async function updateProtectCollector(protectCollector) {
    /**
     * Use the `getData()` method to retrieve the device profiling and behavioral data
     * collected since initialization. Then set the data on the ProtectCollector.
     */
    const data = await protectAPI.getData();
    const protectUpdater = updater(protectCollector);
    const error = protectUpdater(data);
    if (error && 'error' in error) {
      console.error(`Error updating ProtectCollector: ${error.error.message}`);
    }
  }

  /**
   * @function submitProtect - Handles Protect collector submission
   * @returns {Promise<void>}
   */
  async function submitProtect() {
    if (hasProtectTextCollector(collectors)) {
      await setNext();
    } else if (hasProtectCollector(collectors)) {
      const protectCollector = collectors.find(
        (collector) => collector.type === 'ProtectCollector',
      );
      await updateProtectCollector(protectCollector);
    }
  }

  /**
   * Upon successful login, set the authorization code and state used in the custom
   * useOAuth hook to start the OAuth process.
   */
  useEffect(() => {
    async function setOAuthCode() {
      if (node?.status === 'success') {
        const code = node.client?.authorization?.code;
        const state = node.client?.authorization?.state;
        setCode({ code, state });
      }
    }

    setOAuthCode();
  }, [node?.status]);

  /**
   * If the user successfully authenticates, let React complete
   * rendering, then complete setting the global state and redirect to home.
   */
  useEffect(() => {
    async function finalizeAuthState() {
      /**
       * First, let's see if we get a user back from useOauth.
       * If we do, let's set the user data and redirect back to home.
       */
      if (user) {
        /**
         * Set user state/info on "global state"
         */
        methods.setUser(`${user.given_name ?? ''} ${user.family_name ?? ''}`);
        methods.setEmail(user.email);
        methods.setAuthentication(true);

        // Redirect back to the home page
        navigate('/');
      }
    }

    finalizeAuthState();
  }, [user]);

  /**
   * @function onSubmitHandler - The function to call when the form is submitted
   * @param {Object} event - The event object from the form submission
   * @returns {undefined}
   */
  async function onSubmitHandler(event) {
    event.preventDefault();
    setIsLoading(true);

    try {
      // Submit Protect data if there is a Protect collector
      await submitProtect(collectors);

      // Get the next node in the flow
      await setNext();
    } catch (error) {
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  }

  /**
   * Iterate through collectors received from DaVinci and map the collector to the
   * appropriate collector component
   */
  function mapCollectorsToComponents(collector, idx) {
    /** *********************************************************************
     * SDK INTEGRATION POINT
     * Summary: SDK callback method for getting the collector type
     * ----------------------------------------------------------------------
     * Details: This method is helpful in quickly identifying the collector
     * when iterating through an unknown list of Davinci collectors
     ********************************************************************* */
    const collectorName = collector.name;

    if (collector.type === 'TextCollector' && collector.name === 'protectsdk') {
      return (
        <Protect
          collector={collector}
          updater={updater(collector)}
          submit={submitProtect}
          key={collectorName}
        />
      );
    }

    switch (collector.type) {
      case 'TextCollector':
        return (
          <Text
            collector={collector}
            inputName={collectorName}
            updater={updater(collector)}
            key={collectorName}
          />
        );
      case 'PasswordCollector':
        return (
          <Password
            collector={collector}
            inputName={collectorName}
            updater={updater(collector)}
            key={collectorName}
          />
        );
      case 'SingleSelectCollector':
        return (
          <SingleSelect collector={collector} updater={updater(collector)} key={collectorName} />
        );
      case 'ERROR_DISPLAY':
        return <Error key={idx + 'err'} getError={getError} />;
      case 'ReadOnlyCollector':
        return <Readonly key={idx + collectorName} collector={collector} />;
      case 'PhoneNumberCollector':
      case 'DeviceRegistrationCollector':
      case 'DeviceAuthenticationCollector':
        return (
          <ObjectValueComponent
            inputName={collectorName}
            collector={collector}
            updater={updater(collector)}
            key={collectorName}
            submitForm={setNext}
          />
        );
      // TODO: Do we need this?
      // case 'PROTECT':
      //   return <Protect collector={collector} updater={updater(collector)} key={collectorName} />;
      case 'ProtectCollector':
        return <Protect collector={collector} key={collectorName} />;
      case 'SubmitCollector':
        return <SubmitButton collector={collector} isLoading={isLoading} key={collectorName} />;
      case 'FlowCollector':
        return <FlowLink collector={collector} startNewFlow={startNewFlow} key={collectorName} />;
      default:
        // If current collector is not supported, render a warning message
        return <Unknown collector={collector} key={`unknown-${idx}`} />;
    }
  }

  /**
   * @function formIcon - Gets the appropriate icon for the form
   * @param {string} formAction - The type of form
   * @returns {Object} - React icon component
   */
  function formIcon(formAction) {
    switch (formAction) {
      case 'SIGNON':
        return <KeyIcon size="72px" />;
      case 'REGISTER':
        return <NewUserIcon size="72px" />;
      default:
        return null;
    }
  }

  /**
   * Render conditions for presenting appropriate views to user.
   * First, we need to handle no "node", which means we are waiting for
   * the initial response from PingOne for authentication.
   *
   * Once we have a node, we then need to ensure we don't already have a
   * success or failure. If we have a node but don't have a success or
   * failure, we will likely have collectors that we will need to present
   * to the user in their render component form.
   */
  if (!node || node.status === 'start') {
    /**
     * Since there is no node information we need to call DaVinci to retrieve the
     * instructions for rendering the login form.
     */
    return <Loading message="Checking your session ..." />;
  } else if (node.status === 'success') {
    /**
     * Since we have successfully authenticated, show a success message to
     * user while we complete the process and redirect to home page.
     */
    return <Alert message="Success! You're logged in." type="success" />;
  } else if (node.status === 'continue') {
    /**
     * The node to render has collectors, so we need to collect additional
     * data from user.
     */
    return (
      <Fragment>
        <div className="cstm_form-icon  align-self-center mb-3">{formIcon(formAction)}</div>
        <h1 className={`text-center fs-2 mb-3 ${theme.textClass}`}>
          {hasProtectTextCollector(collectors) || hasProtectCollector(collectors) ? '' : formName}
        </h1>
        {/*
         * Map over the collectors and render the appropriate
         * component for each one.
         * */}
        <form onSubmit={onSubmitHandler}>{collectors?.map(mapCollectorsToComponents)}</form>
      </Fragment>
    );
  } else if (node.status === 'error') {
    /**
     * Something went wrong, show an error message to the user.
     */
    return <Alert type="error" message={node.error.message} />;
  } else {
    /**
     * Just in case things blow up.
     */
    return <Alert type="error" message="Unknown node status" />;
  }
}
