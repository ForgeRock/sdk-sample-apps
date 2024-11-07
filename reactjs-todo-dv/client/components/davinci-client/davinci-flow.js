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
export default function DaVinciFlow({ config, flowCompleteCb }) {
  /**
   * Collects the global state for detecting user auth for rendering
   * appropriate navigational items.
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" method to set new state values.
   */
  const [, methods] = useContext(AppContext);
  const [collectors, setCollectors] = useState([]);
  const [pageHeader, setPageHeader] = useState('');
  const [isSubmittingForm, setIsSubmittingForm] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  let client = useRef(null);

  useEffect(() => {
    (async () => {
      client.current = await davinci({ config });
      const node = await client.current.start();

      if (node.status !== 'success') {
        renderNewNode(node);
      } else {
        completeFlow(node);
      }
    })();
  }, []);

  const onSubmitHandler = async (event) => {
    event.preventDefault();
    setIsSubmittingForm(true);
    /**
     * We can just call `next` here and not worry about passing any arguments
     */
    const newNode = await client.current.next();
    /**
     * Recursively render the form with the new state
     */
    processNewNode(newNode);
  };

  async function completeFlow(successNode) {
    const code = successNode.client?.authorization?.code || '';
    const state = successNode.client?.authorization?.state || '';
    await TokenManager.getTokens({ query: { code, state } });
    const user = await UserManager.getCurrentUser();
    methods.setUser(user.preferred_username);
    methods.setEmail(user.email);
    methods.setAuthentication(true);
    // Call the callback function
    flowCompleteCb();
  }

  // Update the UI with the new node
  async function renderNewNode(nextNode) {
    // clear form contents
    setCollectors([]);
    // Set h1 header
    setPageHeader(nextNode.client?.name || '');
    const collectors = client.current.collectors();
    // Save collectors to state
    setCollectors(collectors);
    // If node is a protect node, move to next node without user interaction
    if (client.current.collectors().find((collector) => collector.name === 'protectsdk')) {
      const newNode = await client.current.next();
      processNewNode(newNode);
    }
  }

  function processNewNode(newNode) {
    if (newNode.status === 'next') {
      renderNewNode(newNode);
    } else if (newNode.status === 'success') {
      completeFlow(newNode);
    } else if (newNode.status === 'error') {
      setErrorMessage(newNode.error.message);
    } else {
      console.error('Unknown node status', newNode);
    }
  }

  return (
    <form onSubmit={onSubmitHandler}>
      {pageHeader && <h2>{pageHeader}</h2>}
      {errorMessage.length > 0 && <ErrorMessage message={errorMessage} />}
      {errorMessage.length == 0 &&
        collectors.map((collector) => {
          if (collector.type === 'TextCollector' && collector.name === 'protectsdk') {
            return (
              <Protect
                collector={collector}
                updater={client.current.update(collector)}
                key={`protect-${collector.output.key}`}
              />
            );
          } else if (collector.type === 'TextCollector') {
            return (
              <TextInput
                collector={collector}
                updater={client.current.update(collector)}
                key={`text-${collector.output.key}`}
              />
            );
          } else if (collector.type === 'PasswordCollector') {
            return (
              <Password
                collector={collector}
                updater={client.current.update(collector)}
                key={`password-${collector.output.key}`}
              />
            );
          } else if (collector.type === 'SubmitCollector') {
            return (
              <SubmitButton
                collector={collector}
                key={`submit-btn-${collector.output.key}`}
                submittingForm={isSubmittingForm}
              />
            );
          } else if (collector.type === 'FlowCollector') {
            return (
              <FlowButton
                collector={collector}
                key={`flow-btn-${collector.output.key}`}
                flow={client.current.flow({ action: collector.output.key })}
                renderForm={renderNewNode}
              />
            );
          }
        })}
    </form>
  );
}
