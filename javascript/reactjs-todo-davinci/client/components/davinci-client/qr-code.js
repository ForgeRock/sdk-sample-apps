/*
 * ping-sample-web-react-davinci
 *
 * qr-code.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';

export default function QrCode({ collector }) {
  if (collector.error) {
    return (
      <p className="alert alert-danger mt-1" role="alert">
        {`QR Code error: ${collector.error}`}
      </p>
    );
  }

  return (
    <div className="d-flex flex-column align-items-center mb-3">
      <img src={collector.output.src} alt="QR Code" id="qr-code-image" />
      {collector.output.label && (
        <p className="mt-2" id="qr-code-fallback">
          {`Manual code: ${collector.output.label}`}
        </p>
      )}
    </div>
  );
}
