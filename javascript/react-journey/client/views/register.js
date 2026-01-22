/*
 * ping-sample-web-react-journey
 *
 * register.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext } from 'react';
import { Link } from 'react-router-dom';

import BackHome from '../components/utilities/back-home';
import Card from '../components/layout/card';
import { ThemeContext } from '../context/theme.context';
import { OidcContext } from '../context/oidc.context';
import apiRequest from '../utilities/request';
import Form from '../components/journey/form';

/**
 * @function Register - React view for Register
 * @returns {Object} - React component object
 */
export default function Register() {
  const theme = useContext(ThemeContext);
  const [{ oidcClient }] = useContext(OidcContext);

  async function initUserInDb() {
    await apiRequest(`users`, 'POST', undefined, oidcClient);
  }

  return (
    <div className="cstm_container_v-centered container-fluid d-flex align-items-center">
      <div className="w-100">
        <BackHome />
        <Card>
          <Form
            action={{ type: 'register' }}
            followUp={initUserInDb}
            topMessage={
              <p className={`text-center text-secondary pb-2 ${theme.textClass}`}>
                Already have an account? <Link to="/login">Sign in here!</Link>
              </p>
            }
          />
        </Card>
      </div>
    </div>
  );
}
