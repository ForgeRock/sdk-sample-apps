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
import { traceJourney, traceStep } from '../../utilities/journey-trace';
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
      traceStep('webauthn:handle:start', step, {
        webAuthnStep,
      });

      try {
        if (webAuthnStep === WebAuthnStepType.Registration) {
          setState({
            header: 'Registering your device',
            message: 'Your device will be used to verify your identity',
          });
          traceStep('webauthn:registration:request', step, {
            webAuthnStep,
          });
          const result = await WebAuthn.register(step);
          traceJourney('webauthn:registration:response', {
            webAuthnStep,
            result,
            step,
          });
        } else {
          setState({
            header: 'Verifying your identity',
            message: 'Use your device to verify your identity',
          });
          traceStep('webauthn:authentication:request', step, {
            webAuthnStep,
          });
          const result = await WebAuthn.authenticate(step);
          traceJourney('webauthn:authentication:response', {
            webAuthnStep,
            result,
            step,
          });
        }
        traceStep('webauthn:submit-step', step, {
          webAuthnStep,
        });
        setSubmissionStep(step);
      } catch (error) {
        traceJourney('webauthn:error', {
          error,
          webAuthnStep,
          step,
        });
        traceStep('webauthn:submit-step-after-error', step, {
          webAuthnStep,
        });
        setSubmissionStep(step);
      }
    }
    performWebAuthn();
  }, [setSubmissionStep, step, webAuthnStep]);

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
