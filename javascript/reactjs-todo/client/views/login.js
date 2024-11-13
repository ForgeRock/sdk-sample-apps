/*
 * forgerock-sample-web-react
 *
 * login.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext, useEffect, useState } from 'react';
import { Link, useSearchParams, useNavigate } from 'react-router-dom';

import BackHome from '../components/utilities/back-home';
import Loading from '../components/utilities/loading';
import Card from '../components/layout/card';
import { AppContext } from '../global-state';
import Form from '../components/journey/form';

import { CENTRALIZED_LOGIN } from '../constants';

import { TokenManager, UserManager } from '@forgerock/javascript-sdk';

/**
 * @function Login - React view for Login
 * @returns {Object} - React component object
 */
export default function Login() {
  // Used for setting global authentication state
  const [contextState, methods] = useContext(AppContext);

  // Used for redirection after success
  const navigate = useNavigate();
  const [params] = useSearchParams();

  // Get the code and state from the URL query parameters
  const codeParam = params.get('code');
  const errorParam = params.get('error');
  const stateParam = params.get('state');
  const centralLogin = params.get('centralLogin');
  const journey = params.get('journey');

  // Get environment variable
  const isCentralizedLogin = CENTRALIZED_LOGIN === 'true' || centralLogin === 'true';
  const [state, setState] = useState({
    loadingMessage: '',
  });

  useEffect(() => {
    async function checkCentralizedLogin() {
      if (isCentralizedLogin) {
        if (codeParam && stateParam) {
          /** *****************************************************************
           * SDK INTEGRATION POINT
           * Summary: Get OAuth/OIDC tokens with Authorization Code Flow w/PKCE.
           * ------------------------------------------------------------------
           * Details:When the user return to this app after successfully logging in,
           * the URL will include code and state query parameters that need to
           * be passed in to complete the OAuth flow giving the user access
           ***************************************************************** */
          setState({
            loadingMessage: 'Success! Redirecting ...',
          });
          await authorize(codeParam, stateParam);
        } else if (errorParam) {
          // Do nothing as it will redirect for central login
        } else {
          /** *****************************************************************
           * SDK INTEGRATION POINT
           * Summary: Get OAuth/OIDC tokens with Authorization Code Flow w/PKCE.
           * ------------------------------------------------------------------
           * The key-value of `login: redirect` is what allows central-login.
           * Passing no arguments or a key-value of `login: 'embedded'` means
           * the app handles authentication locally
           ***************************************************************** */
          setState({
            loadingMessage: 'Redirecting ...',
          });
          await TokenManager.getTokens({ login: 'redirect' });
        }
      }
    }
    checkCentralizedLogin();
  }, []);

  async function authorize(codeParam, stateParam) {
    await TokenManager.getTokens({ query: { code: codeParam, state: stateParam } });
    const user = await UserManager.getCurrentUser();
    methods.setUser(user.name);
    methods.setEmail(user.email);
    methods.setAuthentication(true);
    navigate('/');
  }

  if (!isCentralizedLogin) {
    return (
      <div className="cstm_container_v-centered container-fluid d-flex align-items-center">
        <div className="w-100">
          <BackHome />
          <Card>
            <Form
              action={{ type: 'login' }}
              bottomMessage={
                <p className={`text-center text-secondary p-3 ${contextState.theme.textClass}`}>
                  Don’t have an account? <Link to="/register">Sign up here!</Link>
                </p>
              }
              journey={journey}
            />
          </Card>
        </div>
      </div>
    );
  } else {
    return (
      <div className="cstm_container_v-centered container-fluid d-flex align-items-center">
        <div className="w-100">
          <Loading message={state.loadingMessage} />
        </div>
      </div>
    );
  }
}
