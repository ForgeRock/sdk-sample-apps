/*
 * forgerock-sample-web-react
 *
 * login.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';
import BackHome from '../components/utilities/back-home';
import Card from '../components/layout/card';
import { useNavigate } from 'react-router-dom';
import DaVinciFlow from '../components/davinci-client/davinci-flow.js';
import { CLIENT_ID, REDIRECT_URI, SCOPE, BASE_URL } from '../constants';

/**
 * @function Login - React view for Login
 * @returns {Object} - React component object
 */
export default function Login() {
  // Used for redirection after success
  const navigate = useNavigate();

  // Set DaVinci config object
  const config = {
    clientId: CLIENT_ID, // oAuth client id
    redirectUri: REDIRECT_URI, // oAuth redirect uri
    scope: SCOPE, // Requested oAuth scopes
    serverConfig: {
      baseUrl: BASE_URL, // PingOne base url
      wellknown: `${BASE_URL}as/.well-known/openid-configuration`,
    },
  };

  // This function is passed to DaVinciFlow to be called when the flow is complete
  // Each individual flow might have a different completion action
  function onComplete() {
    navigate('/');
  }

  return (
    <div className="cstm_container_v-centered container-fluid d-flex align-items-center">
      <div className="w-100">
        <BackHome />
        <Card>
          <DaVinciFlow config={config} flowCompleteCb={onComplete} />
        </Card>
      </div>
    </div>
  );
}
