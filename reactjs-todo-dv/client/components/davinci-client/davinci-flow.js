/*
 * forgerock-sample-web-react
 *
 * davinci-flow.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext, useEffect, useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { TokenManager, UserManager } from '@forgerock/javascript-sdk';
import davinci from '@forgerock/davinci-client';
import TextInput from './text-input.js';
import Password from './password.js';
import SubmitButton from './submit-button.js';
import Protect from './protect.js';
import FlowButton from './flow-button.js';
import ErrorMessage from './error-message.js';
import { AppContext } from '../../global-state.js';

/**
 * @function DaVinciFlow - React view for a DaVinci flow
 * @returns {Object} - React component object
 */
export default function DaVinciFlow({ config }) {
  /**
   * Collects the global state for detecting user auth for rendering
   * appropriate navigational items.
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" method to set new state values.
   */
  const [, methods] = useContext(AppContext);
  const [components, setComponents] = useState([]);
  const [pageHeader, setPageHeader] = useState('');

  // Used for redirection after success
  const navigate = useNavigate();

  let client = useRef(null);

  const renderComplete = async (successNode) => {
    const code = successNode.client?.authorization?.code || '';
    const state = successNode.client?.authorization?.state || '';
    await TokenManager.getTokens({ query: { code, state } });
    const user = await UserManager.getCurrentUser();
    methods.setUser(user.preferred_username);
    methods.setEmail(user.email);
    methods.setAuthentication(true);
    navigate('/');
  };

  const renderError = (errorNode) => {
    const errorMessage = <ErrorMessage message={errorNode.error.message} key="error-message" />;
    setComponents([errorMessage]);
  };

  // Represents the main render function for app
  async function renderForm(nextNode) {
    const arrFormFields = [];
    // clear form contents
    setComponents([]);
    // Set h1 header
    setPageHeader(nextNode.client?.name || '');

    const collectors = client.current.collectors();

    collectors.forEach((collector) => {
      if (collector.type === 'TextCollector' && collector.name === 'protectsdk') {
        arrFormFields.push(
          <Protect
            collector={collector}
            updater={client.current.update(collector)}
            key={`protect-${collector.output.key}`}
          />,
        );
      } else if (collector.type === 'TextCollector') {
        arrFormFields.push(
          <TextInput
            collector={collector}
            updater={client.current.update(collector)}
            key={`text-${collector.output.key}`}
          />,
        );
      } else if (collector.type === 'PasswordCollector') {
        arrFormFields.push(
          <Password
            collector={collector}
            updater={client.current.update(collector)}
            key={`password-${collector.output.key}`}
          />,
        );
      } else if (collector.type === 'SubmitCollector') {
        arrFormFields.push(
          <SubmitButton collector={collector} key={`submit-btn-${collector.output.key}`} />,
        );
      } else if (collector.type === 'FlowCollector') {
        arrFormFields.push(
          <FlowButton
            collector={collector}
            key={`flow-btn-${collector.output.key}`}
            flow={client.current.flow({ action: collector.output.key })}
            renderForm={renderForm}
          />,
        );
      }
    });

    // Save components to state
    setComponents(arrFormFields);

    if (client.current.collectors().find((collector) => collector.name === 'protectsdk')) {
      const newNode = await client.current.next();

      if (newNode.status === 'next') {
        return renderForm(newNode);
      } else if (newNode.status === 'success') {
        return renderComplete(newNode);
      } else if (newNode.status === 'error') {
        return renderError(newNode);
      } else {
        console.error('Unknown node status', newNode);
      }
    }
  }

  const onSubmitHandler = async (event) => {
    event.preventDefault();

    /**
     * We can just call `next` here and not worry about passing any arguments
     */
    const newNode = await client.current.next();

    /**
     * Recursively render the form with the new state
     */
    if (newNode.status === 'next') {
      renderForm(newNode);
    } else if (newNode.status === 'success') {
      return renderComplete(newNode);
    } else if (newNode.status === 'error') {
      return renderError(newNode);
    } else {
      console.error('Unknown node status', newNode);
    }
  };

  useEffect(() => {
    (async () => {
      client.current = await davinci({ config });
      /**
       * Optionally subscribe to the store to listen for all store updates
       * This is useful for debugging and logging
       * It returns an unsubscribe function that you can call to stop listening
       */
      client.current.subscribe(() => {
        const state = client.current.getState();
        console.log('Event emitted from store:', state);
      });

      const node = await client.current.start();

      if (node.status !== 'success') {
        renderForm(node);
      } else {
        renderComplete(node);
      }
    })();
  }, []);

  return (
    <form onSubmit={onSubmitHandler}>
      {pageHeader && <h2>{pageHeader}</h2>}
      {components.map((component) => {
        return component;
      })}
    </form>
  );
}
