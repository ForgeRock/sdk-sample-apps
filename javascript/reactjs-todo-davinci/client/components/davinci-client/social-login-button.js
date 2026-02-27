/*
 * ping-sample-web-react-davinci
 *
 * social-login-button.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';

export default function SocialLoginButton({ collector, updater, isLoading }) {
  return (
    <button
      type="button"
      className="btn btn-primary w-100 mb-2"
      disabled={isLoading}
      onClick={async () => {
        await updater();
        window.location.assign(collector.output.url);
      }}
    >
      {
        /**
         * Render a small spinner during submission calls
         */
        isLoading ? (
          <span
            className="spinner-border spinner-border-sm"
            role="status"
            aria-hidden="true"
          ></span>
        ) : null
      }
      <span>{collector.output.label}</span>
    </button>
  );
}
