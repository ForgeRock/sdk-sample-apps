/*
 * forgerock-sample-web-react
 *
 * register.js
 *
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext } from 'react';
import { Link } from 'react-router-dom';

import BackHome from '../components/utilities/back-home';
import Card from '../components/layout/card';
import { AppContext } from '../global-state';
import apiRequest from '../utilities/request';

/**
 * @function Register - React view for Register
 * @returns {Object} - React component object
 */
export default function Register() {
  const [state] = useContext(AppContext);

  async function initUserInDb() {
    await apiRequest(`users`, 'POST');
  }

  return (
    <div className="cstm_container_v-centered container-fluid d-flex align-items-center">
      <div className="w-100">
        <BackHome />
        <Card>
        </Card>
      </div>
    </div>
  );
}
