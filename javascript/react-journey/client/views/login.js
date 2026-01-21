/*
 * ping-sample-web-react-journey
 *
 * login.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext, useEffect, useState } from 'react';
import { Link, useSearchParams, useNavigate } from 'react-router-dom';
import BackHome from '../components/utilities/back-home';
import Loading from '../components/utilities/loading';
import Card from '../components/layout/card';
import Form from '../components/journey/form';
import { CENTRALIZED_LOGIN, DEBUGGER } from '../constants';
import { OidcContext } from '../context/oidc.context';
import { ThemeContext } from '../context/theme.context';

/**
 * @function Login - React view for Login
 * @returns {Object} - React component object
 */
export default function Login() {
  const theme = useContext(ThemeContext);
  
  // Used for setting global authentication state
  const [{oidcClient}, methods] = useContext(OidcContext);

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
          /**
           * When the user returns to this app after successfully logging in,
           * the URL will include code and state query parameters that need to
           * be passed in to complete the OAuth flow giving the user access
           */
          setState({
            loadingMessage: 'Success! Redirecting ...',
          });
          await authorize(codeParam, stateParam);
        } else if (errorParam) {
          // Do nothing as it will redirect for central login
        } else {
          /** *****************************************************************
           * SDK INTEGRATION POINT
           * Summary: Redirect the user to the authorization URL
           * ------------------------------------------------------------------
           * Details: Use the OIDC client to get an authorization URL to redirect
           * the user to sign in.
           ***************************************************************** */
          if (DEBUGGER) debugger;

          setState({
            loadingMessage: 'Redirecting ...',
          });

          const authorizeUrl = await oidcClient.authorize.url();
          if (typeof authorizeUrl !== 'string' && 'error' in authorizeUrl) {
            console.error('Authorization URL Error:', authorizeUrl);
          } else {
            window.location.assign(authorizeUrl);
          }
        }
      }
    }
    checkCentralizedLogin();
  }, []);

  async function authorize(codeParam, stateParam) {
    /** *****************************************************************
     * SDK INTEGRATION POINT
     * Summary: Get OAuth/OIDC tokens and user info
     * ------------------------------------------------------------------
     * Details: Exchange code and state for tokens. With valid tokens
     * stored in storage, we can then request user info and set app state
     ***************************************************************** */
    if (DEBUGGER) debugger;

    const tokenResponse = await oidcClient.token.exchange(codeParam, stateParam);
    if ('error' in tokenResponse) {
      console.error('Token exchange error:', tokenResponse);
    }

    const user = await oidcClient.user.info();
    if ('error' in user) {
      console.error('Error getting user:', user);
    }

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
                <p className={`text-center text-secondary p-3 ${theme.textClass}`}>
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
