/*
 * ping-sample-web-react-todo-oidc
 *
 * login.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext, useEffect, useState } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';

import BackHome from '../components/utilities/back-home';
import Loading from '../components/utilities/loading';
import Card from '../components/layout/card';
import { OidcContext } from '../context/oidc.context';

/**
 * @function Login - React view for Login
 * @returns {Object} - React component object
 */
export default function Login() {
  const [{ oidcClient }, methods] = useContext(OidcContext);
  const navigate = useNavigate();
  const [params] = useSearchParams();

  const codeParam = params.get('code');
  const errorParam = params.get('error');
  const stateParam = params.get('state');
  const [state, setState] = useState({
    loadingMessage: '',
  });

  useEffect(() => {
    async function checkCentralizedLogin() {
      try {
        if (!oidcClient) {
          setState({
            loadingMessage: 'Initializing application...',
          });
          return;
        }

        if (codeParam && stateParam) {
          const tokens = await oidcClient.token.exchange(codeParam, stateParam);
          if ('error' in tokens) {
            setState({
              loadingMessage: 'Sign in failed. Please try again.',
            });
            console.error(`Error: token exchange; ${tokens.error}`);
            return;
          }

          const user = await oidcClient.user.info();
          if ('error' in user) {
            setState({
              loadingMessage: 'Sign in failed. Please try again.',
            });
            console.error(`Error: get current user; ${user.error}`);
            return;
          }

          setState({
            loadingMessage: 'Success! Redirecting ...',
          });

          methods.setUser(user.name);
          methods.setEmail(user.email);
          methods.setAuthentication(true);
          navigate('/');
        } else if (errorParam) {
          setState({
            loadingMessage: 'Sign in failed. Please try again.',
          });
        } else {
          setState({
            loadingMessage: 'Redirecting ...',
          });
          const authorizeUrl = await oidcClient.authorize.url();
          if (typeof authorizeUrl !== 'string' && 'error' in authorizeUrl) {
            setState({
              loadingMessage: 'Sign in failed. Please try again.',
            });
            console.error(`Error: centralized login; ${authorizeUrl.error}`);
            return;
          }
          window.location.assign(authorizeUrl);
        }
      } catch (error) {
        console.error(`Error: centralized login; ${error}`);
      }
    }

    checkCentralizedLogin();
  }, [oidcClient]);

  return (
    <div className="cstm_container_v-centered container-fluid d-flex align-items-center">
      <div className="w-100">
        <BackHome />
        <Card>
          <Loading message={state.loadingMessage} />
        </Card>
      </div>
    </div>
  );
}
