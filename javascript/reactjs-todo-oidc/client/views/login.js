/*
 * ping-sample-web-react-todo-oidc
 *
 * login.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext, useEffect, useState, useCallback } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';

import BackHome from '../components/utilities/back-home';
import Loading from '../components/utilities/loading';
import Card from '../components/layout/card';
import { SERVER, DEBUGGER } from '../constants';
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
  const [loadingMessage, setLoadingMessage] = useState('');

  const authorize = useCallback(
    async function authorizeCallback(codeParam, stateParam) {
      /** *****************************************************************
       * SDK INTEGRATION POINT
       * Summary: Get OAuth/OIDC tokens and user info
       * ------------------------------------------------------------------
       * Details: Exchange code and state for tokens. With valid tokens
       * stored in storage, we can then request user info and set app state
       ***************************************************************** */
      if (DEBUGGER) debugger;

      const tokens = await oidcClient.token.exchange(codeParam, stateParam);
      if ('error' in tokens) {
        setLoadingMessage('Sign in failed. Please try again.');
        console.error(`Error: token exchange; ${tokens.error}`);
        return;
      }

      const user = await oidcClient.user.info();
      if ('error' in user) {
        setLoadingMessage('Sign in failed. Please try again.');
        console.error(`Error: get current user; ${user.error}`);
        return;
      }

      const username =
        SERVER === 'PINGONE' ? `${user.given_name ?? ''} ${user.family_name ?? ''}` : user.name;

      methods.setUser(username);
      methods.setEmail(user.email);
      methods.setAuthentication(true);
      navigate('/');
    },
    [oidcClient, methods, navigate],
  );

  useEffect(() => {
    async function handleCentralizedLogin() {
      try {
        if (codeParam && stateParam) {
          /**
           * When the user returns to this app after successfully logging in,
           * the URL will include code and state query parameters that need to
           * be passed in to complete the OAuth flow giving the user access
           */
          setLoadingMessage('Success! Redirecting ...');
          await authorize(codeParam, stateParam);
        } else if (errorParam) {
          setLoadingMessage('Sign in failed. Please try again.');
        } else {
          /** *****************************************************************
           * SDK INTEGRATION POINT
           * Summary: Redirect the user to the authorization URL
           * ------------------------------------------------------------------
           * Details: Use the OIDC client to get an authorization URL to redirect
           * the user to sign in.
           ***************************************************************** */
          if (DEBUGGER) debugger;

          setLoadingMessage('Redirecting ...');

          const authorizeUrl = await oidcClient.authorize.url();
          if (typeof authorizeUrl !== 'string' && 'error' in authorizeUrl) {
            setLoadingMessage('Sign in failed. Please try again.');
            console.error(`Error: centralized login; ${authorizeUrl.error}`);
            return;
          }

          window.location.assign(authorizeUrl);
        }
      } catch (error) {
        console.error(`Error: centralized login; ${error}`);
      }
    }

    handleCentralizedLogin();
  }, [authorize, codeParam, errorParam, methods, navigate, oidcClient, stateParam]);

  return (
    <div className="cstm_container_v-centered container-fluid d-flex align-items-center">
      <div className="w-100">
        <BackHome />
        <Card>
          <Loading message={loadingMessage} />
        </Card>
      </div>
    </div>
  );
}
