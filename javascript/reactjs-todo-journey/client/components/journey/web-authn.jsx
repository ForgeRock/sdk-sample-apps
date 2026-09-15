/*
 * ping-sample-web-react-journey
 *
 * web-authn.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { WebAuthn, WebAuthnStepType } from '@forgerock/journey-client/webauthn';
import { useEffect, useState, useContext } from 'react';
import { ThemeContext } from '../../context/theme.context';
import Alert from './alert';
/**
 * @function WebAuthn - Footer React component
 * @returns {Object} - React component object
 */

export default function WebAuthnComponent({ step, setSubmissionStep, callbacksForm }) {
  const theme = useContext(ThemeContext);
  const webAuthnStep = WebAuthn.getWebAuthnStepType(step);
  const [autofill, setAutofill] = useState(false);
  const [state, setState] = useState({
    message: '',
    header: '',
  });
  const [error, setError] = useState('');

  useEffect(() => {
    async function performWebAuthn() {
      try {
        if (webAuthnStep === WebAuthnStepType.Registration) {
          setState({
            header: 'Registering your device',
            message: 'Your device will be used to verify your identity',
          });
          await WebAuthn.register(step);
          setSubmissionStep(step);
        } else if (webAuthnStep === WebAuthnStepType.Authentication) {
          setState({
            header: 'Verifying your identity',
            message: 'Use your device to verify your identity',
          });

          // (Optional) Check if the browser supports conditional mediation
          const isConditionalSupported = await WebAuthn.isConditionalMediationSupported();

          // Check if the PingAM authorization server allows conditional mediation
          const metadataCallback = WebAuthn.getMetadataCallback(step);
          const meta = metadataCallback?.getData();
          const isConditionalMediation =
            meta?.mediation === 'conditional' || meta?.conditional === true;

          if (isConditionalSupported && isConditionalMediation) {
            setAutofill(true);
            const controller = new AbortController();
            await WebAuthn.authenticate(step, controller.signal);
          } else {
            // Proceed to default WebAuthn authentication method if autofill isn't available
            await WebAuthn.authenticate(step);
          }

          setSubmissionStep(step);
        } else {
          setError('Unknown WebAuthn step type');
        }
      } catch (error) {
        console.error(error.message);
        setError(
          `Failed to ${webAuthnStep === WebAuthnStepType.Registration ? 'register' : 'authenticate'}`,
        );
        setSubmissionStep(step);
      }
    }
    performWebAuthn();
  }, [setSubmissionStep, step, webAuthnStep]);

  if (error) {
    return <Alert message={error} type="error" />;
  }

  return autofill ? (
    callbacksForm
  ) : (
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
