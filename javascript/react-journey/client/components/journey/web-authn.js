/*
 * ping-sample-web-react-journey
 *
 * web-authn.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { WebAuthn, WebAuthnStepType } from '@forgerock/journey-client/webauthn';
import React, { useEffect, useState, useContext } from 'react';
import { ThemeContext } from '../../context/theme.context';
/**
 * @function WebAuthn - Footer React component
 * @returns {Object} - React component object
 */

export default function WebAuthnComponent({ step, setSubmissionStep }) {
  const theme = useContext(ThemeContext);
  const webAuthnStep = WebAuthn.getWebAuthnStepType(step);
  const [state, setState] = useState({
    message: '',
    header: '',
  });
  useEffect(() => {
    async function performWebAuthn() {
      try {
        if (webAuthnStep === WebAuthnStepType.Registration) {
          setState({
            header: 'Registering your device',
            message: 'Your device will be used to verify your identity',
          });
          await WebAuthn.register(step);
        } else {
          setState({
            header: 'Verifying your identity',
            message: 'Use your device to verify your identity',
          });
          await WebAuthn.authenticate(step);
        }
        setSubmissionStep(step);
      } catch (e) {
        setSubmissionStep(step);
      }
    }
    performWebAuthn();
  }, []);

  return (
    <p>
      <span className="d-flex justify-content-center my-2">
        <span className="cstm_loading-spinner spinner-border text-primary" role="status"></span>
      </span>
      <span className={`d-flex justify-content-center fw-bolder ${theme.textClass}`}>
        {state.header}
      </span>
      <span className={`d-flex justify-content-center p-3 fs-5 ${theme.textClass}`}>
        {state.message}
      </span>
    </p>
  );
}
