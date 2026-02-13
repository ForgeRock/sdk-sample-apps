/*
 * ping-sample-web-react-davinci
 *
 * login.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';
import BackHome from '../components/utilities/back-home.js';
import Card from '../components/layout/card.js';
import Form from '../components/davinci-client/form.js';

/**
 * @function Login - React view for Login
 * @returns {Object} - React component object
 */
export default function Login() {
  return (
    <div className="cstm_container_v-centered container-fluid d-flex align-items-center">
      <div className="w-100">
        <BackHome />
        <Card>
          <Form />
        </Card>
      </div>
    </div>
  );
}
