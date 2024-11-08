/*
 * forgerock-sample-web-react
 *
 * error-message.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';
import AlertIcon from '../icons/alert-icon';

export default function ErrorMessage({ message }) {
  return (
    <p className="alert alert-danger d-flex align-items-center mt-1" role="alert">
      <AlertIcon classes="cstm_alert-icon col-1" />
      <span className="ps-2">{message}</span>
    </p>
  );
}
