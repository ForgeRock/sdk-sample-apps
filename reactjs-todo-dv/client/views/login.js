/*
 * forgerock-sample-web-react
 *
 * login.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import BackHome from '../components/utilities/back-home';
import Card from '../components/layout/card';
// import { AppContext } from '../global-state';
import { TokenManager, UserManager } from '@forgerock/javascript-sdk';
import davinci from '@forgerock/davinci-client';
import usernameComponent from '../components/davinci-client/text.js';
import passwordComponent from '../components/davinci-client/password.js';
import submitButtonComponent from '../components/davinci-client/submit-button.js';
import protect from '../components/davinci-client/protect.js';
import flowLinkComponent from '../components/davinci-client/flow-link.js';
import socialLoginButtonComponent from '../components/davinci-client/social-login-button.js';
import { CLIENT_ID, REDIRECT_URI, SCOPE, BASE_URL } from '../constants';

import { AppContext } from '../global-state';

/**
 * @function Login - React view for Login
 * @returns {Object} - React component object
 */
export default function Login() {
  /**
   * Collects the global state for detecting user auth for rendering
   * appropriate navigational items.
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" method to set new state values.
   */
  const [_, methods] = useContext(AppContext);

  // Used for redirection after success
  const navigate = useNavigate();

  const config = {
    clientId: CLIENT_ID,
    redirectUri: REDIRECT_URI,
    scope: SCOPE,
    serverConfig: {
      baseUrl: BASE_URL,
      wellknown: `${BASE_URL}as/.well-known/openid-configuration`,
    },
  };

  useEffect(() => {
    (async () => {
      const client = await davinci({ config });
      const formEl = document.getElementById('form');
      /**
       * Optionally subscribe to the store to listen for all store updates
       * This is useful for debugging and logging
       * It returns an unsubscribe function that you can call to stop listening
       */
      client.subscribe(() => {
        const state = client.getState();
        console.log('Event emitted from store:', state);
      });

      const node = await client.start();

      formEl.addEventListener('submit', async (event) => {
        event.preventDefault();
        /**
         * We can just call `next` here and not worry about passing any arguments
         */

        // const state = client.getState();
        const newNode = await client.next();

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
      });

      if (node.status !== 'success') {
        renderForm(node);
      } else {
        renderComplete(node);
      }

      // Represents the main render function for app
      async function renderForm(nextNode) {
        formEl.innerHTML = '';

        const header = document.createElement('h2');
        header.innerText = nextNode.client?.name || '';
        formEl.appendChild(header);

        const subheader = document.createElement('h3');
        subheader.innerText = nextNode.client?.description || '';
        formEl.appendChild(subheader);

        const collectors = client.collectors();

        collectors.forEach((collector) => {
          if (collector.type === 'TextCollector' && collector.name === 'protectsdk') {
            protect(
              formEl, // You can ignore this; it's just for rendering
              collector, // This is the plain object of the collector
              client.update(collector), // Returns an update function for this collector
            );
          } else if (collector.type === 'TextCollector') {
            usernameComponent(
              formEl, // You can ignore this; it's just for rendering
              collector, // This is the plain object of the collector
              client.update(collector), // Returns an update function for this collector
            );
          } else if (collector.type === 'PasswordCollector') {
            passwordComponent(
              formEl, // You can ignore this; it's just for rendering
              collector, // This is the plain object of the collector
              client.update(collector), // Returns an update function for this collector
            );
          } else if (collector.type === 'SubmitCollector') {
            submitButtonComponent(
              formEl, // You can ignore this; it's just for rendering
              collector, // This is the plain object of the collector
            );
          } else if (collector.type === 'SocialLoginCollector') {
            socialLoginButtonComponent(formEl, collector);
          } else if (collector.type === 'FlowCollector') {
            flowLinkComponent(
              formEl, // You can ignore this; it's just for rendering
              collector, // This is the plain object of the collector
              client.flow({
                // Returns a function to call the flow from within component
                action: collector.output.key,
              }),
              renderForm, // Ignore this; it's just for re-rendering the form
            );
          }
        });

        if (client.collectors().find((collector) => collector.name === 'protectsdk')) {
          const newNode = await client.next();

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

      async function renderComplete(successNode) {
        const code = successNode.client?.authorization?.code || '';
        const state = successNode.client?.authorization?.state || '';
        await TokenManager.getTokens({ query: { code, state } });
        const user = await UserManager.getCurrentUser();
        methods.setUser(user.preferred_username);
        methods.setEmail(user.email);
        methods.setAuthentication(true);
        navigate('/');
      }

      function renderError(errorNode) {
        formEl.innerHTML = `
              <h2>Error</h2>
              <pre>${errorNode.error.message}</pre>
            `;
      }
    })();
  }, []);

  return (
    <div className="cstm_container_v-centered container-fluid d-flex align-items-center">
      <div className="w-100">
        <BackHome />
        <Card>
          <form id="form"></form>
        </Card>
      </div>
    </div>
  );
}
